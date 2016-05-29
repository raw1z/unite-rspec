let s:Vital = vital#of('vital')
let s:Prelude = s:Vital.import('Prelude')
let s:Filepath = s:Vital.import('System.Filepath')
let s:String = s:Vital.import('Data.String')
let s:List = s:Vital.import('Data.List')

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

let g:unite_rspec_run_last_metadata = {}

let s:job = {} "{{{

function s:job.on_stdout(job_id, data)
  let lines = []
  for item in a:data
    if (s:String.starts_with(item, '{') == 0) && (s:String.ends_with(item, '}') == 0)
      let lines = s:List.conj(lines, item)
    else
      try
        let g:unite_rspec_run_last_metadata = json_decode(item)
      catch
        " call unite#print_error(v:exception)
      endtry
    endif
  endfor

  let self.stdout = self.stdout . join(lines, "\n")
endfunction

function s:job.on_stderr(job_id, data)
  let self.stderr = self.stderr . join(a:data, "\n")
endfunction

function s:job.on_exit(job_id, data)
  let self.exited = 1
endfunction

function s:job.read_lines()
  let lines = s:String.lines(self.stdout)
  let self.stdout = ''
  return lines
endfunction

function! s:job.build_rspec_command(spec)
  return './bin/rspec --format documentation --format json '.a:spec
endfunction

function s:job.new(spec_to_run)
  let rspec_command = self.build_rspec_command(a:spec_to_run)
  let instance = extend(copy(self), {'stdout': '', 'stderr': '', 'exited': 0})
  let instance.id = jobstart(rspec_command, instance)
  return instance
endfunction "}}}

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
  let label = s:String.trim(a:data)
  let examples = g:unite_rspec_run_last_metadata.examples
  for example in examples
    let full_description = example.full_description
    if stridx(full_description, label) != -1
      let file_path = example.file_path
      let line_number = example.line_number
      let existing_buffer = bufnr(file_path)
      let window = bufwinnr(existing_buffer)

      if window == -1
        execute 'wincmd j'

        if &modified
          execute 'bo split ' . file_path
        else
          execute 'e ' . file_path
        endif
      else
        execute window . 'wincmd w'
      endif

      execute line_number
      return
    endif
  endfor
endfunction "}}}

