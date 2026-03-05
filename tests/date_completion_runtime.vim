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
      \ '- [ ] item',
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

if empty(maparg(':', 'i', 0, 1))
  call s:fail('date completion runtime: insert map for : is missing')
endif

let s:task = search('^\s*-\s\[\s\]\s*item$', 'n')
call setline(s:task, '- [ ] item due')
call cursor(s:task, strlen(getline(s:task)) + 1)

let s:ret = lan#note_buffer#eval_date_complete_map(':')
if s:ret[0] !=# ':'
  call s:fail('date completion runtime: due map return value is invalid')
endif
let s:items = lan#note_buffer#date_completefunc(0, '')
if empty(s:items)
  call s:fail('date completion runtime: due candidates are empty')
endif
if s:items[0].word !=# strftime('%Y-%m-%d')
  call s:fail('date completion runtime: first due candidate must be today')
endif

call setline(s:task, '- [ ] item deadline')
call cursor(s:task, strlen(getline(s:task)) + 1)
let s:ret2 = lan#note_buffer#eval_date_complete_map(':')
if s:ret2[0] !=# ':'
  call s:fail('date completion runtime: deadline map return value is invalid')
endif
let s:items2 = lan#note_buffer#date_completefunc(0, '')
if empty(s:items2) || s:items2[0].word !~# '^\d\{4}-\d\{2}-\d\{2}$'
  call s:fail('date completion runtime: deadline candidate format is invalid')
endif

call delete(s:tmp)
cquit 0
