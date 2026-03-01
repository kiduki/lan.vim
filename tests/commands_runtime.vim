set nocompatible

let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')
execute 'set runtimepath^=' . fnameescape(s:root)
execute 'runtime plugin/lan.vim'

function! s:fail(msg) abort
  echoerr a:msg
  cquit 1
endfunction

let s:tmp = tempname() . '.md'
call lan#setup({'file': s:tmp})

execute 'Lanb block_task'
execute 'Lanq queue_task'
execute 'Lann note_line'

let s:lines = readfile(s:tmp)
let s:blob = join(s:lines, "\n")
if s:blob !~# '- \[ \] block_task'
  call s:fail('commands runtime: :Lanb did not append task')
endif
if s:blob !~# '- \[ \] queue_task'
  call s:fail('commands runtime: :Lanq did not append task')
endif
if s:blob !~# '- note_line'
  call s:fail('commands runtime: :Lann did not append note')
endif

execute 'Lan'
let s:lnum = search('block_task', 'n')
if s:lnum <= 0
  call s:fail('commands runtime: block_task not found in buffer')
endif
call cursor(s:lnum, 1)

execute 'LanToggleProgress'
if getline(s:lnum) !~# '^\s*-\s\[\s\]\s*🚩\s*block_task'
  call s:fail('commands runtime: :LanToggleProgress failed')
endif

execute 'LanToggleWaiting'
if getline(s:lnum) !~# '^\s*-\s\[\s\]\s*⌛\s*block_task'
  call s:fail('commands runtime: :LanToggleWaiting failed')
endif

execute 'LanToggleDone'
if getline(s:lnum) !~# '^\s*-\s\[x\]\s*block_task'
  call s:fail('commands runtime: :LanToggleDone failed')
endif

call delete(s:tmp)
cquit 0
