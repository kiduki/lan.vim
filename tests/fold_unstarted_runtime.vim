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
      \ '- [ ] plain_task',
      \ 'plain detail',
      \ '- [ ] 🚩 progress_task',
      \ '- [ ] ⌛ waiting_task',
      \ '- [x] done_task',
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

let s:plain = search('plain_task', 'n')
let s:progress = search('progress_task', 'n')
let s:waiting = search('waiting_task', 'n')
let s:done = search('done_task', 'n')

execute 'LanFoldUnstarted'

if foldlevel(s:plain) <= 0
  call s:fail('fold unstarted runtime: plain task should be folded')
endif
if foldlevel(s:progress) > 0
  call s:fail('fold unstarted runtime: progress task should not be folded')
endif
if foldlevel(s:waiting) > 0
  call s:fail('fold unstarted runtime: waiting task should not be folded')
endif
if foldlevel(s:done) > 0
  call s:fail('fold unstarted runtime: done task should not be folded')
endif

call delete(s:tmp)
cquit 0
