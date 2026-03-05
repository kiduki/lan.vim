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
      \ '- [ ] title_text @x +alice p1 due:2026-03-05',
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

if empty(maparg('<Leader>li', 'n', 0, 1)) || empty(maparg('<Leader>la', 'n', 0, 1)) || empty(maparg('<Leader>lc', 'n', 0, 1))
  call s:fail('task edit maps runtime: expected mappings are missing')
endif

let s:task = search('^\s*-\s\[\s\]\s*title_text', 'n')
call cursor(s:task, 1)

call lan#note_buffer#edit_task_text('insert')
if col('.') != strlen('- [ ] ') + 1
  call s:fail('task edit maps runtime: insert mode cursor position mismatch')
endif
stopinsert

call lan#note_buffer#edit_task_text('append')
if col('.') < strlen('- [ ] title_text') + 1
  call s:fail('task edit maps runtime: append mode cursor position mismatch')
endif
stopinsert

call lan#note_buffer#edit_task_text('change')
stopinsert
if getline(s:task) !=# '- [ ] @x +alice p1 due:2026-03-05'
  call s:fail('task edit maps runtime: change mode did not preserve metadata')
endif

call delete(s:tmp)
cquit 0
