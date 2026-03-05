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
      \ '- [ ] due_only due:2026-03-05',
      \ '- [ ] both due:2026-03-05 deadline:2026-03-06T10:00',
      \ '',
      \ '### 📥 Queue',
      \ '',
      \ '123',
      \ '',
      \ '### 🧠 Notes',
      \ '',
      \ '---',
      \ ''
      \ ], s:tmp)

call lan#setup({'file': s:tmp})
execute 'edit ' . fnameescape(s:tmp)

let s:task1 = search('due_only', 'n')
call cursor(s:task1, match(getline(s:task1), 'due:') + 5)
call lan#ui#eval_ctrl_ax_map(1)
if getline(s:task1) !~# 'due:2026-03-06'
  call s:fail('date increment runtime: due date increment failed')
endif

let s:task2 = search('both due', 'n')
call cursor(s:task2, match(getline(s:task2), 'deadline:') + 10)
call lan#ui#eval_ctrl_ax_map(-1)
if getline(s:task2) !~# 'deadline:2026-03-05T10:00'
  call s:fail('date increment runtime: deadline date decrement failed')
endif

call cursor(s:task2, 1)
call lan#ui#eval_ctrl_ax_map(1)
if getline(s:task2) !~# 'due:2026-03-06'
  call s:fail('date increment runtime: due should be priority when cursor is outside tokens')
endif

let s:numline = search('^123$', 'n')
call cursor(s:numline, 2)
call lan#ui#eval_ctrl_ax_map(1)
if getline(s:numline) !=# '124'
  call s:fail('date increment runtime: default <C-a> fallback failed')
endif

call delete(s:tmp)
cquit 0
