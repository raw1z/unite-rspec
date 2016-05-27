command! RSpecRun call unite_rspec#run_spec()
command! RSpecRunLast call unite_rspec#run_last_spec()
command! RSpecUnite Unite -no-empty rspec

if !exists("g:unite_rspec_map_keys")
  let g:unite_rspec_map_keys = 1
endif

if g:unite_rspec_map_keys
  silent! map <unique> <Leader>r :RSpecRun<CR>
  silent! map <unique> <Leader>R :RSpecUnite<CR>
  silent! map <unique> <Leader>l :RSpecRunLast<CR>
endif
