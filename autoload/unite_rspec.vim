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
  let g:unite_rspec_last_command =unite_rspec#set_rspec_command(spec, line)
  exec unite_rspec#run_spec_command(g:unite_rspec_last_command)
endfunction "}}}

function! unite_rspec#run_last_spec() abort "{{{
  if exists('g:unite_rspec_last_command')
    exec unite_rspec#run_spec_command(g:unite_rspec_last_command)
  endif
endfunction "}}}

function! unite_rspec#set_rspec_command(spec, line) abort "{{{
  let shellcmd = 'rspec\\ --format\\ documentation\\ '.a:spec
  if a:line > 0
    let shellcmd = shellcmd.'\:'.a:line
  endif
  return shellcmd
endfunction "}}}

function! unite_rspec#run_spec_command(rspec_command) abort "{{{
  let uniteOptions = '-log'
  return ':Unite '.uniteOptions.' output/shellcmd:'.a:rspec_command
endfunction "}}}

