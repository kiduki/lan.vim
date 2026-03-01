set nocompatible

let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')
execute 'set runtimepath^=' . fnameescape(s:root)
execute 'runtime plugin/lan.vim'

function! s:fail(msg) abort
  echoerr a:msg
  cquit 1
endfunction

function! s:day_header(delta_days) abort
  let l:ts = localtime() + (a:delta_days * 86400)
  return '## ' . strftime('%Y-%m-%d', l:ts) . ' (' . strftime('%a', l:ts) . ')'
endfunction

let s:tmp = tempname() . '.md'
let s:yesterday = strftime('%Y-%m-%d', localtime() - 86400)

call writefile([
      \ s:day_header(0),
      \ '',
      \ '### 🔥 Blocking Tasks',
      \ '',
      \ '- [ ] carried_task @work p1',
      \ '',
      \ '### 📥 Queue',
      \ '',
      \ '### 🧠 Notes',
      \ '',
      \ '---',
      \ '',
      \ s:day_header(-8),
      \ '',
      \ '### 🔥 Blocking Tasks',
      \ '',
      \ '- [ ] carried_task @work p1',
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

let s:ins = search('### 🔥 Blocking Tasks', 'n')
if s:ins <= 0
  call s:fail('review unsaved runtime: could not find blocking header')
endif
call append(s:ins + 1, '- [ ] unsaved_overdue due:' . s:yesterday)

try
  execute 'LanReview 7'
catch
  call s:fail('review unsaved runtime: :LanReview failed: ' . v:exception)
endtry

let s:content = join(getline(1, '$'), "\n")

if s:content !~# '## Overdue (1)'
  call s:fail('review unsaved runtime: overdue count mismatch (unsaved task not reflected)')
endif

if s:content !~# '## HighPriorityStale (1)'
  call s:fail('review unsaved runtime: stale continuity mismatch for carried_task')
endif

call delete(s:tmp)
cquit 0
