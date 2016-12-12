let s:Vital = vital#of('vital')
let s:String = s:Vital.import('Data.String')

function! unite_rspec#run_spec() abort "{{{
  let filepath = expand("%")
  let spec_file_regex = '_spec\.rb$'

  if match(filepath, spec_file_regex) == -1
    if exists('g:unite_rspec_last_command')
      call unite_rspec#run_last_spec()
    else
      exec ":RSpecUnite"
    endif

    return
  endif

  let line = line('.')
  let spec = expand('%')
  let g:unite_rspec_last_command = unite_rspec#build_rspec(spec, line)
  exec unite_rspec#run_spec_command(g:unite_rspec_last_command)
endfunction "}}}

function! unite_rspec#run_last_spec() abort "{{{
  if exists('g:unite_rspec_last_command')
    exec unite_rspec#run_spec_command(g:unite_rspec_last_command)
  endif
endfunction "}}}

function! unite_rspec#build_rspec(spec, line) abort "{{{
  if a:line > 0
    return a:spec.':'.a:line
  else
    return a:spec
  endif
endfunction "}}}

function! unite_rspec#run_spec_command(rspec_command) abort "{{{
  " update file before running tests
  exec ':wall'

  let shellcmd = s:String.replace(a:rspec_command, ' ', '\\ ')
  let shellcmd = s:String.replace(shellcmd, ':', '\:')
  let uniteOptions = '-no-quit'
  let run_cmd = ':Unite '.uniteOptions.' rspec/run:'.shellcmd
  return run_cmd
endfunction "}}}
