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
      \ '- [ ] sample @bbb @aaa +charlie +alice',
      \ '- [ ] next',
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

let s:imap_label = maparg('@', 'i', 0, 1)
let s:imap_assignee = maparg('+', 'i', 0, 1)
if empty(s:imap_label) || empty(s:imap_assignee)
  call s:fail('meta completion runtime: insert maps for @/+ are missing')
endif

let s:task = search('^\s*-\s\[\s\]\s*next$', 'n')
call cursor(s:task, strlen(getline(s:task)) + 1)
call setline(s:task, getline(s:task) . ' @')
call cursor(s:task, strlen(getline(s:task)) + 1)

let s:ret = lan#note_buffer#eval_meta_complete_map('@')
if s:ret[0] !=# '@'
  call s:fail('meta completion runtime: @ map return value is invalid')
endif
let s:items = lan#note_buffer#meta_completefunc(0, '')
if len(filter(copy(s:items), 'v:val.word ==# "aaa"')) == 0
  call s:fail('meta completion runtime: @ candidates did not include aaa')
endif
if len(filter(copy(s:items), 'v:val.word ==# "bbb"')) == 0
  call s:fail('meta completion runtime: @ candidates did not include bbb')
endif

call setline(s:task, substitute(getline(s:task), '\s*@$', '', '') . ' +')
call cursor(s:task, strlen(getline(s:task)) + 1)
let s:ret2 = lan#note_buffer#eval_meta_complete_map('+')
if s:ret2[0] !=# '+'
  call s:fail('meta completion runtime: + map return value is invalid')
endif
let s:items2 = lan#note_buffer#meta_completefunc(0, '')
if len(filter(copy(s:items2), 'v:val.word ==# "alice"')) == 0
  call s:fail('meta completion runtime: + candidates did not include alice')
endif
if len(filter(copy(s:items2), 'v:val.word ==# "charlie"')) == 0
  call s:fail('meta completion runtime: + candidates did not include charlie')
endif

call delete(s:tmp)
cquit 0
