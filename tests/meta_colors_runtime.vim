set nocompatible

let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')
execute 'set runtimepath^=' . fnameescape(s:root)
execute 'runtime plugin/lan.vim'

function! s:fail(msg) abort
  echoerr a:msg
  cquit 1
endfunction

let s:tmp = tempname() . '.md'
call lan#setup({
      \ 'file': s:tmp,
      \ 'meta_colors': {
      \   'label': {'ctermfg': '196', 'guifg': '#ff0000'},
      \   'priority': {'ctermfg': '46', 'guifg': '#00ff00'},
      \   'due': {'ctermfg': '21', 'guifg': '#0000ff'},
      \ }
      \ })

call writefile([
      \ '## ' . strftime('%Y-%m-%d') . ' (' . strftime('%a') . ')',
      \ '',
      \ '### 🔥 Blocking Tasks',
      \ '',
      \ '- [ ] sample_task @work p1 due:2026-03-03',
      \ '',
      \ '### 📥 Queue',
      \ '',
      \ '### 🧠 Notes',
      \ '',
      \ '---',
      \ ''
      \ ], s:tmp)

execute 'edit ' . fnameescape(s:tmp)

if !exists('b:lan_label_matchid') || !exists('b:lan_priority_matchid') || !exists('b:lan_due_matchid')
  call s:fail('meta colors runtime: metadata highlight match ids are missing')
endif

let s:label_hl = execute('silent highlight lanLabelMeta')
let s:priority_hl = execute('silent highlight lanPriorityMeta')
let s:due_hl = execute('silent highlight lanDueMeta')

if s:label_hl !~# 'ctermfg=196' || s:label_hl !~? 'guifg=#ff0000'
  call s:fail('meta colors runtime: label colors were not applied')
endif
if s:priority_hl !~# 'ctermfg=46' || s:priority_hl !~? 'guifg=#00ff00'
  call s:fail('meta colors runtime: priority colors were not applied')
endif
if s:due_hl !~# 'ctermfg=21' || s:due_hl !~? 'guifg=#0000ff'
  call s:fail('meta colors runtime: due colors were not applied')
endif

call delete(s:tmp)
cquit 0
