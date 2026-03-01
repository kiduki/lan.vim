set nocompatible

let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')
execute 'set runtimepath^=' . fnameescape(s:root)
execute 'runtime plugin/lan.vim'

function! s:fail(msg) abort
  echoerr a:msg
  cquit 1
endfunction

function! s:day_header(date_ymd) abort
  let l:ts = strptime('%Y-%m-%d', a:date_ymd)
  return '## ' . a:date_ymd . ' (' . strftime('%a', l:ts) . ')'
endfunction

let s:today = strftime('%Y-%m-%d')
let s:today_ts = strptime('%Y-%m-%d', s:today)
let s:weekday = str2nr(strftime('%u', s:today_ts))
let s:week_start = strftime('%Y-%m-%d', s:today_ts - ((s:weekday - 1) * 86400))
let s:prev_week = strftime('%Y-%m-%d', strptime('%Y-%m-%d', s:week_start) - 86400)

let s:tmp = tempname() . '.md'
call writefile([
      \ s:day_header(s:today),
      \ '',
      \ '### 🔥 Blocking Tasks',
      \ '',
      \ '- [x] task_a',
      \ '- [ ] task_b',
      \ '- [x] task_c',
      \ '- [ ] task_d',
      \ '',
      \ '### 📥 Queue',
      \ '',
      \ '### 🧠 Notes',
      \ '',
      \ '---',
      \ '',
      \ s:day_header(s:week_start),
      \ '',
      \ '### 🔥 Blocking Tasks',
      \ '',
      \ '- [ ] task_a',
      \ '',
      \ '### 📥 Queue',
      \ '',
      \ '### 🧠 Notes',
      \ '',
      \ '---',
      \ '',
      \ s:day_header(s:prev_week),
      \ '',
      \ '### 🔥 Blocking Tasks',
      \ '',
      \ '- [ ] task_c',
      \ '- [ ] task_d',
      \ '',
      \ '### 📥 Queue',
      \ '',
      \ '### 🧠 Notes',
      \ '',
      \ '---',
      \ ''
      \ ], s:tmp)

call lan#setup({'file': s:tmp})

let s:out = execute('LanStats')

if s:out !~# 'week_done=2'
  call s:fail('stats runtime: week_done mismatch: ' . s:out)
endif
if s:out !~# 'today_done=2'
  call s:fail('stats runtime: today_done mismatch: ' . s:out)
endif
if s:out !~# 'added=4'
  call s:fail('stats runtime: added mismatch: ' . s:out)
endif
if s:out !~# 'remaining=2'
  call s:fail('stats runtime: remaining mismatch: ' . s:out)
endif

call delete(s:tmp)
cquit 0
