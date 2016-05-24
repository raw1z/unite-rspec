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
      \ 'default_kind' : 'command'
      \}

function! s:source.run_spec(path) abort "{{{
  let command = "bundle exec rspec --no-color --format default ".spec
  return printf("echo %s", a:path)
endfunction "}}}

function! s:source.gather_candidates(args, context) abort "{{{
  return self.list_specs()
endfunction "}}}

function! s:source.list_specs() abort "{{{
  let currentDirectory = getcwd()
  let specDirectory = s:Filepath.join(currentDirectory, "spec")
  let specHelperFile = s:Filepath.join(specDirectory, "/spec_helper.rb")
  if filereadable(specHelperFile)
    let filesList = [self.build_candidates(currentDirectory, specDirectory)]

    " list spec directories
    let specDirectoryContents = s:Prelude.globpath(specDirectory, '*')
    let ignoredElements = ['factories', 'support', 'spec_helper.rb', 'rails_helper.rb']
    for element in specDirectoryContents
      let abbr = s:String.replace(element, specDirectory."/", "")
      if s:List.any('v:val == "'.abbr.'"', ignoredElements) == 0
        let filesList = s:List.push(filesList, self.build_candidates(specDirectory, element))
      endif
    endfor

    " list spec files
    let specFiles = s:Prelude.globpath(specDirectory, '**/*_spec.rb')
    for specFile in specFiles
      let filesList = s:List.push(filesList, self.build_candidates(specDirectory, specFile))
    endfor

    return filesList
  else
    return []
  endif
endfunction "}}}

function! s:source.build_candidates(prefix, element) abort "{{{
  let abbr = s:String.replace(a:element, a:prefix, "")

  let kind = ['command']
  if isdirectory(a:element)
    let kind = s:List.unshift(kind, 'directory')
  else
    let kind = s:List.unshift(kind, 'file')
  endif

  return {
    \ 'word' : a:element,
    \ 'kind' : kind,
    \ 'abbr' : s:String.replace_first(abbr, '/', ''),
    \ "action__command": self.build_command(a:element),
    \ "action__path": a:element
    \}
endfunction "}}}

function! s:source.build_command(spec) abort "{{{
  let uniteOptions = '-log'
  let shellcmd = 'rspec\\ --format\\ documentation\\ '.a:spec
  return ':Unite '.uniteOptions.' output/shellcmd:'.shellcmd
endfunction "}}}

