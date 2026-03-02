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

call writefile([
      \ s:day_header(-1),
      \ '',
      \ '### 🔥 Blocking Tasks',
      \ '',
      \ '- [ ] carry_task',
      \ 'carry detail line',
      \ '',
      \ '### 📥 Queue',
      \ '',
      \ '### 🧠 Notes',
      \ '',
      \ '---',
      \ ''
      \ ], s:tmp)

call lan#setup({'file': s:tmp})
execute 'Lan'

let s:block_hdr = search('^### 🔥 Blocking Tasks$', 'n')
let s:queue_hdr = search('^### 📥 Queue$', 'n')
if s:block_hdr <= 0 || s:queue_hdr <= 0
  call s:fail('carryover separator runtime: section headers not found')
endif

let s:carry_sep = 0
for s:i in range(s:block_hdr + 1, s:queue_hdr - 1)
  if getline(s:i) ==# '---'
    let s:carry_sep = s:i
    break
  endif
endfor
if s:carry_sep <= 0
  call s:fail('carryover separator runtime: separator not carried')
endif
if getline(s:carry_sep - 1) !=# ''
  call s:fail('carryover separator runtime: blank line missing before separator')
endif

call delete(s:tmp)
cquit 0
