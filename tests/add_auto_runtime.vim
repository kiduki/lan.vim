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

function! s:open_note(lines) abort
  call writefile(a:lines, s:tmp)
  execute 'edit! ' . fnameescape(s:tmp)
endfunction

let s:tmp = tempname() . '.md'
call lan#setup({'file': s:tmp})

call s:open_note([
      \ s:today_header(),
      \ '',
      \ '### 🔥 Blocking Tasks',
      \ '',
      \ '- [ ] first_task',
      \ 'first desc',
      \ '- [ ] second_task',
      \ '',
      \ '### 📥 Queue',
      \ '',
      \ '### 🧠 Notes',
      \ '',
      \ '---',
      \ ''
      \ ])
let s:first = search('first_task', 'n')
call cursor(s:first, 1)
call lan#note_buffer#insert_auto()
stopinsert
let s:second = search('second_task', 'n')
if getline(s:second - 1) !~# '^\s*-\s\[\s\]\s*$'
  call s:fail('add_auto runtime: rule1 insert position mismatch')
endif

call s:open_note([
      \ s:today_header(),
      \ '',
      \ '### 🔥 Blocking Tasks',
      \ '',
      \ '### 📥 Queue',
      \ '',
      \ '- [ ] queue_task',
      \ 'queue desc',
      \ '',
      \ '### 🧠 Notes',
      \ '',
      \ '---',
      \ ''
      \ ])
let s:queue_task = search('queue_task', 'n')
call cursor(s:queue_task, 1)
call lan#note_buffer#insert_auto()
stopinsert
if getline(s:queue_task + 1) !~# '^\s*-\s\[\s\]\s*$'
  call s:fail('add_auto runtime: rule2 insert position mismatch')
endif

call s:open_note([
      \ s:today_header(),
      \ '',
      \ '### 🔥 Blocking Tasks',
      \ '',
      \ '- [ ] lone_task',
      \ 'detail line',
      \ '',
      \ '### 📥 Queue',
      \ '',
      \ '### 🧠 Notes',
      \ '',
      \ '---',
      \ ''
      \ ])
let s:lone = search('lone_task', 'n')
let s:detail = search('detail line', 'n')
call cursor(s:detail, 1)
call lan#note_buffer#insert_auto()
stopinsert
if getline(s:lone + 1) !~# '^\s*-\s\[\s\]\s*$'
  call s:fail('add_auto runtime: rule3 insert position mismatch')
endif

call s:open_note([
      \ s:today_header(),
      \ '',
      \ '### 🔥 Blocking Tasks',
      \ '',
      \ 'plain note line',
      \ '',
      \ '### 📥 Queue',
      \ '',
      \ '### 🧠 Notes',
      \ '',
      \ '---',
      \ ''
      \ ])
let s:block_hdr = search('^### 🔥 Blocking Tasks$', 'n')
let s:plain = search('plain note line', 'n')
call cursor(s:plain, 1)
call lan#note_buffer#insert_auto()
stopinsert
if getline(s:block_hdr + 1) !~# '^\s*-\s\[\s\]\s*$'
  call s:fail('add_auto runtime: rule4 insert position mismatch')
endif

call delete(s:tmp)
cquit 0
