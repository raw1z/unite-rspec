" Variables {{{
let s:Vital = vital#of('vital')
let s:Prelude = s:Vital.import('Prelude')
let s:Filepath = s:Vital.import('System.Filepath')
let s:String = s:Vital.import('Data.String')
let s:List = s:Vital.import('Data.List')

let g:unite_rspec_run_last_metadata = {}
"}}}

function! unite#sources#rspec_run#define() abort "{{{
  return s:source
endfunction "}}}

let s:source = {
      \ 'name' : 'rspec/run',
      \ 'description' : 'run rspec tests',
      \ 'default_kind' : 'command',
      \ 'hooks' : {},
      \ 'lines' : 0,
      \}

let s:job = {} "{{{
function s:job.parse_data(data) "{{{
  let lines = []
  for item in a:data
    if self.reporting
      let self.json_report = self.json_report . item
      continue
    endif

    if s:String.starts_with(item, '{"version":')
      let self.reporting = 1
      let self.json_report = self.json_report . item
    else
      let lines = s:List.conj(lines, item)
    endif
  endfor

  return join(lines, "\n")
endfunction "}}}
function s:job.on_stdout(job_id, data) "{{{
  let self.stdout = self.stdout . self.parse_data(a:data)
endfunction "}}}
function s:job.on_stderr(job_id, data) "{{{
  let self.stderr = self.stderr . self.parse_data(a:data)
endfunction "}}}
function s:job.on_exit(job_id, data) "{{{
  try
    let json_data = get(s:String.scan(self.json_report, "{.*}"), 0, '{}')
    let g:unite_rspec_run_last_metadata = json_decode(json_data)
  catch
    call unite#print_error(v:exception)
  endtry
  let self.exited = 1
endfunction "}}}
function s:job.read_lines() "{{{
  let stdout_lines = self.read_lines_from_stream(self.stdout)
  let self.stdout = ''

  let stderr_lines = self.read_lines_from_stream(self.stderr)
  let self.stderr = ''

  return s:List.concat([stdout_lines, stderr_lines])
endfunction "}}}
function s:job.read_lines_from_stream(stream) "{{{
  return s:String.lines(a:stream)
endfunction "}}}
function! s:job.build_rspec_command(spec) "{{{
  return './bin/rspec --format documentation --format json '.a:spec
endfunction "}}}
function s:job.new(spec_to_run) "{{{
  let rspec_command = self.build_rspec_command(a:spec_to_run)
  let instance = extend(copy(self), {'stdout': '', 'stderr': '', 'exited': 0, 'reporting': 0, 'json_report': ''})
  let instance.id = jobstart(rspec_command, instance)
  return instance
endfunction "}}}
"}}}
function! s:source.hooks.on_init(args, context) abort "{{{
  let command = join(filter(copy(a:args), "v:val !=# '!'"))
  if command == ''
    let command = unite#util#input(
          \ 'Please input spec: ', '', 'file')
    redraw
  endif
  let a:context.source__command = command
endfunction"}}}
function! s:source.gather_candidates(args, context) abort "{{{
  if a:context.is_redraw
    let a:context.is_async = 1
  endif

  if a:context.is_redraw
    let a:context.is_async = 1
  endif

  try
    let a:context.source__job = s:job.new(a:context.source__command)
  catch
    call unite#print_error(v:exception)
    let a:context.is_async = 0
    return []
  endtry

  return self.async_gather_candidates(a:args, a:context)
endfunction "}}}
function! s:source.async_gather_candidates(args, context) abort "{{{
  let job = a:context.source__job

  if job.exited
    let a:context.is_async = 0
    call jobwait([job.id])
  endif

  let lines = job.read_lines()
  let lines = map(lines,
          \ "substitute(unite#util#iconv(v:val, 'char', &encoding),
          \   '\\e\\[\\u', '', 'g')")

  let candidates = map(lines, "{
        \ 'word' : substitute(v:val, '\\e\\[[0-9;]*m', '', 'g'),
        \ 'abbr' : v:val,
        \ 'action__command' : self.open_spec_file(v:val)
        \ }")

  return candidates
endfunction "}}}
function! s:source.hooks.on_close(args, context) abort "{{{
  if has_key(a:context, 'source__job')
    let job = a:context.source__job
    if job.exited == 0
      call jobstop(job.id)
    endif
  endif
endfunction "}}}
function! s:source.open_spec_file(data) "{{{
  return "call rspec_run#open_spec_file('". a:data . "')"
endfunction "}}}
function! rspec_run#open_spec_file(data) abort "{{{
  let label = substitute(a:data, "(FAILED.*)", "", "g")
  let label = s:String.trim(label)
  let examples = g:unite_rspec_run_last_metadata.examples
  for example in examples
    if (example.description == label) || (label =~ ".*".example.full_description.".*")
      call rspec_run#goto_spec(example.file_path, example.line_number)
      return
    endif
  endfor
endfunction "}}}
function! rspec_run#goto_spec(file_path, line_number) abort "{{{
  let existing_buffer = bufnr(a:file_path)
  let window = bufwinnr(existing_buffer)

  if window == -1
    execute 'wincmd j'

    if &modified
      execute 'bo split ' . a:file_path
    else
      execute 'e ' . a:file_path
    endif
  else
    execute window . 'wincmd w'
  endif

  execute a:line_number
endfunction "}}}

