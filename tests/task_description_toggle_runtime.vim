set nocompatible

let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')
execute 'set runtimepath^=' . fnameescape(s:root)
execute 'runtime plugin/lan.vim'

function! s:fail(msg) abort
  echoerr a:msg
  cquit 1
endfunction

function! s:today_header() abort
  return '## ' . strftime('%Y-%m-%d') . ' (' . strftime('%a') . ')'
endfunction

let s:tmp = tempname() . '.md'

call writefile([
      \ s:today_header(),
      \ '',
      \ '### 🔥 Blocking Tasks',
      \ '',
      \ '- [ ] main_task',
      \ 'main task description',
      \ '---',
      \ '',
      \ '### 📥 Queue',
      \ '',
      \ '### 🧠 Notes',
      \ '',
      \ '---',
      \ ''
      \ ], s:tmp)

call lan#setup({'file': s:tmp})
execute 'edit ' . fnameescape(s:tmp)

let s:task = search('main_task', 'n')
let s:desc = search('main task description', 'n')
if s:task <= 0 || s:desc <= 0
  call s:fail('task description toggle runtime: fixture lines not found')
endif

call cursor(s:desc, 1)
execute 'LanToggleDone'
if getline(s:task) !~# '^\s*-\s\[x\]\s*main_task'
  call s:fail('task description toggle runtime: toggle from description failed')
endif

let s:sep = search('^---$', 'n')
if s:sep <= 0
  call s:fail('task description toggle runtime: separator line not found')
endif
call cursor(s:sep, 1)
execute 'LanToggleDone'
if getline(s:task) !~# '^\s*-\s\[\s\]\s*main_task'
  call s:fail('task description toggle runtime: toggle from separator failed')
endif

call delete(s:tmp)
cquit 0
