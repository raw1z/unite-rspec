let s:Vital = vital#of('vital')
let s:Prelude = s:Vital.import('Prelude')
let s:Filepath = s:Vital.import('System.Filepath')
let s:String = s:Vital.import('Data.String')
let s:List = s:Vital.import('Data.List')

function! unite#sources#rspec#define() abort "{{{
  return s:source
endfunction "}}}

let s:source = {
      \ 'name' : 'rspec',
      \ 'description' : 'candidates from rspec',
      \}

function! s:source.run_spec(path) abort "{{{
  return printf("echo %s", a:path)
endfunction "}}}

function! s:source.gather_candidates(args, context) abort "{{{
  return self.list_specs()
endfunction "}}}

fun! s:source.list_specs() abort "{{{
  let currentDirectory = getcwd()
  let specDirectory = s:Filepath.join(currentDirectory, "spec")
  let specHelperFile = s:Filepath.join(specDirectory, "/spec_helper.rb")
  if filereadable(specHelperFile)
    let filesList = [{'word': specDirectory, 'abbr': 'spec'}]

    " list spec directories
    let specDirectoryContents = s:Prelude.globpath(specDirectory, '*')
    let ignoredElements = ['factories', 'support', 'spec_helper.rb', 'rails_helper.rb']
    for element in specDirectoryContents
      let abbr = s:String.replace(element, specDirectory."/", "")
      if s:List.any('v:val == "'.abbr.'"', ignoredElements) == 0
        let word = element
        let filesList = s:List.push(filesList, {'word': word, 'abbr': abbr})
      endif
    endfor

    " list spec files
    let specFiles = s:Prelude.globpath(specDirectory, '**/*_spec.rb')
    for specFile in specFiles
      let word = specFile
      let abbr = s:String.replace(specFile, specDirectory."/", "")
      let filesList = s:List.push(filesList, {'word': word, 'abbr': abbr})
    endfor

    return filesList
  else
    return []
  endif
endf "}}}


