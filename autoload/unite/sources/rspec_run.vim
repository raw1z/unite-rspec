" Variables {{{
let s:Vital = vital#of('vital')
let s:Prelude = s:Vital.import('Prelude')
let s:Filepath = s:Vital.import('System.Filepath')
let s:String = s:Vital.import('Data.String')
let s:List = s:Vital.import('Data.List')

let g:unite_rspec_run_last_metadata = {}
let g:unite_source_rspec_run_colors =
      \ get(g:, 'unite_source_rspec_run_colors', [
        \ '#6c6c6c', '#ff6666', '#66ff66', '#ffd30a',
        \ '#1e95fd', '#ff13ff', '#1bc8c8', '#c0c0c0',
        \ '#383838', '#ff4444', '#44ff44', '#ffb30a',
        \ '#6699ff', '#f820ff', '#4ae2e2', '#ffffff',
        \])
"}}}

function! unite#sources#rspec_run#define() abort "{{{
  return s:source
endfunction "}}}

let s:source = {
      \ 'name' : 'rspec/run',
      \ 'description' : 'run rspec tests',
      \ 'default_kind' : 'command',
      \ 'syntax' : 'uniteSource__Rspec_Run',
      \ 'hooks' : {},
      \ 'lines' : 0,
      \}

let s:job = {'pty': 1, 'TERM': 'xterm-256color'} "{{{
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
    let g:unite_rspec_last_command = self.spec
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
  return ['./bin/rspec', '--color', '--format', 'documentation', '--format', 'json', a:spec]
endfunction "}}}
function s:job.new(spec_to_run) "{{{
  let rspec_command = self.build_rspec_command(a:spec_to_run)
  let instance = extend(copy(self), {'stdout': '', 'stderr': '', 'exited': 0, 'reporting': 0, 'json_report': '', 'spec': a:spec_to_run})
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
function! s:source.hooks.on_syntax(args, context) abort "{{{
  let highlight_table = {
        \ '0' : ' cterm=NONE ctermfg=NONE ctermbg=NONE gui=NONE guifg=NONE guibg=NONE',
        \ '1' : ' cterm=BOLD gui=BOLD',
        \ '3' : ' cterm=ITALIC gui=ITALIC',
        \ '4' : ' cterm=UNDERLINE gui=UNDERLINE',
        \ '7' : ' cterm=REVERSE gui=REVERSE',
        \ '8' : ' ctermfg=0 ctermbg=0 guifg=#000000 guibg=#000000',
        \ '9' : ' gui=UNDERCURL',
        \ '21' : ' cterm=UNDERLINE gui=UNDERLINE',
        \ '22' : ' gui=NONE',
        \ '23' : ' gui=NONE',
        \ '24' : ' gui=NONE',
        \ '25' : ' gui=NONE',
        \ '27' : ' gui=NONE',
        \ '28' : ' ctermfg=NONE ctermbg=NONE guifg=NONE guibg=NONE',
        \ '29' : ' gui=NONE',
        \ '39' : ' ctermfg=NONE guifg=NONE',
        \ '49' : ' ctermbg=NONE guibg=NONE',
        \}
  for color in range(30, 37)
    " Foreground color pattern.
    let highlight_table[color] = printf(' ctermfg=%d guifg=%s',
          \ color - 30, g:unite_source_rspec_run_colors[color - 30])
    for color2 in [1, 3, 4, 7]
      " Type;Foreground color pattern
      let highlight_table[color2 . ';' . color] =
            \ highlight_table[color2] . highlight_table[color]
    endfor
  endfor
  for color in range(40, 47)
    " Background color pattern.
    let highlight_table[color] = printf(' ctermbg=%d guibg=%s',
          \ color - 40, g:unite_source_rspec_run_colors[color - 40])
    for color2 in range(30, 37)
      " Foreground;Background color pattern.
      let highlight_table[color2 . ';' . color] =
            \ highlight_table[color2] . highlight_table[color]
    endfor
  endfor

  syntax match uniteSource__Rspec_Run_Conceal
        \ contained conceal    '\e\[[0-9;]*m'
        \ containedin=uniteSource__Rspec_Run

  syntax match uniteSource__Rspec_Run_Conceal
        \ contained conceal    '\e\[?1h'
        \ containedin=uniteSource__Rspec_Run

  syntax match uniteSource__Rspec_Run_Ignore
        \ contained conceal    '\e\[?\d[hl]\|\e=\r\|\r\|\e>'
        \ containedin=uniteSource__Rspec_Run

  for [key, highlight] in items(highlight_table)
    let syntax_name = 'uniteSource__Rspec_Run_Color'
          \ . substitute(key, ';', '_', 'g')
    let syntax_command = printf('start=+\e\[0\?%sm+ end=+\ze\e[\[0*m]\|$+ ' .
          \ 'contains=uniteSource__Rspec_Run_Conceal ' .
          \ 'containedin=uniteSource__Rspec_Run oneline', key)

    execute 'syntax region' syntax_name syntax_command
    execute 'highlight' syntax_name highlight
  endfor
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

  let candidates = map(job.read_lines(), "{
        \ 'word' : rspec_run#sanitized_candidate_word(v:val),
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
  let str = '"'. a:data . '"'
  return "call rspec_run#open_spec_file(". str . ")"
endfunction "}}}
function! rspec_run#sanitized_candidate_word(data) abort "{{{
  let label = substitute(a:data, "\e\[[0-9;]*m", '', 'g')
  let label = substitute(label, "(FAILED.*)", "", "g")
  return s:String.trim(label)
endfunction "}}}
function! rspec_run#open_spec_file(data) abort "{{{
  let label = rspec_run#sanitized_candidate_word(a:data)
  let examples = g:unite_rspec_run_last_metadata.examples
  for example in examples
    if (example.description == label) || (label =~ ".*".example.full_description.".*")
      call rspec_run#goto_file_at_line(example.file_path, example.line_number, 0)
      return
    else
      if rspec_run#goto_stack_file(label, example)
        return
      endif
    endif
  endfor
endfunction "}}}
function! rspec_run#goto_file_at_line(file_path, line_number, splitted) abort "{{{
  let existing_buffer = bufnr(a:file_path)
  let window = bufwinnr(existing_buffer)

  if window == -1
    execute 'wincmd j'

    if &modified || a:splitted
      execute 'bo split ' . a:file_path
    else
      execute 'e ' . a:file_path
    endif
  else
    execute window . 'wincmd w'
  endif

  execute a:line_number
endfunction "}}}
function! rspec_run#goto_stack_file(data, example) abort "{{{
  if s:String.starts_with(a:data, "# ")
    let scans = s:String.scan(a:data, '\v\.\/.*\.rb\:\d+')
    if !empty(scans)
      let tokens = s:String.nsplit(scans[0], 2, ':')
      if !empty(tokens)
        call rspec_run#goto_file_at_line(tokens[0], tokens[1], 1)
        return 1
      endif
    endif
  endif

  return 0
endfunction "}}}
