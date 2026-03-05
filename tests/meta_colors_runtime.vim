set nocompatible

let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')
execute 'set runtimepath^=' . fnameescape(s:root)
execute 'runtime plugin/lan.vim'

function! s:fail(msg) abort
  echoerr a:msg
  cquit 1
endfunction

function! s:match_pattern(group) abort
  for l:m in getmatches()
    if get(l:m, 'group', '') ==# a:group
      return get(l:m, 'pattern', '')
    endif
  endfor
  return ''
endfunction

let s:tmp = tempname() . '.md'
call lan#setup({
      \ 'file': s:tmp,
      \ 'meta_colors': {
      \   'label': {'ctermfg': '196', 'guifg': '#ff0000'},
      \   'assignee': {'ctermfg': '33', 'guifg': '#00aaff'},
      \   'priority': {'ctermfg': '46', 'guifg': '#00ff00'},
      \   'due': {'ctermfg': '21', 'guifg': '#0000ff'},
      \   'deadline': {'ctermfg': '201', 'guifg': '#ff00ff'},
      \ }
      \ })

call writefile([
      \ '## ' . strftime('%Y-%m-%d') . ' (' . strftime('%a') . ')',
      \ '',
      \ '### 🔥 Blocking Tasks',
      \ '',
      \ '- [ ] sample_task @step1 @step2 +alice p1 due:2026-03-03T11:45 deadline:2026-03-06',
      \ '',
      \ '### 📥 Queue',
      \ '',
      \ '### 🧠 Notes',
      \ '',
      \ '---',
      \ ''
      \ ], s:tmp)

execute 'edit ' . fnameescape(s:tmp)

if !exists('b:lan_label_matchid') || !exists('b:lan_assignee_matchid') || !exists('b:lan_priority_matchid') || !exists('b:lan_due_matchid') || !exists('b:lan_deadline_matchid')
  call s:fail('meta colors runtime: metadata highlight match ids are missing')
endif

let s:label_pat = s:match_pattern('lanLabelMeta')
let s:assignee_pat = s:match_pattern('lanAssigneeMeta')
let s:priority_pat = s:match_pattern('lanPriorityMeta')
let s:due_pat = s:match_pattern('lanDueMeta')
let s:deadline_pat = s:match_pattern('lanDeadlineMeta')
if s:label_pat ==# '' || s:assignee_pat ==# '' || s:priority_pat ==# '' || s:due_pat ==# '' || s:deadline_pat ==# ''
  call s:fail('meta colors runtime: match patterns are missing')
endif

let s:task_line = getline(5)
if matchstr('@step1', s:label_pat) !=# '@step1'
  call s:fail('meta colors runtime: label pattern did not match @label')
endif
if matchstr('+alice', s:assignee_pat) !=# '+alice'
  call s:fail('meta colors runtime: assignee pattern did not match +assignee')
endif
if matchstr('+ななし', s:assignee_pat) !=# '+ななし'
  call s:fail('meta colors runtime: assignee pattern did not match japanese +assignee')
endif
if matchstr(s:task_line, s:priority_pat) !=# 'p1'
  call s:fail('meta colors runtime: priority pattern did not match p1')
endif
if matchstr(s:task_line, s:due_pat) !=# 'due:2026-03-03T11:45'
  call s:fail('meta colors runtime: due pattern did not match due date')
endif
if matchstr(s:task_line, s:deadline_pat) !=# 'deadline:2026-03-06'
  call s:fail('meta colors runtime: deadline pattern did not match deadline date')
endif
if matchstr('@step1', s:priority_pat) !=# ''
  call s:fail('meta colors runtime: priority pattern must not match inside @label')
endif
if matchstr('- [ ] invalid_due due:xxxx-xx-xx', s:due_pat) !=# ''
  call s:fail('meta colors runtime: due pattern matched invalid due token')
endif
if matchstr('- [ ] invalid_deadline deadline:xxxx-xx-xx', s:deadline_pat) !=# ''
  call s:fail('meta colors runtime: deadline pattern matched invalid deadline token')
endif

let s:label_hl = execute('silent highlight lanLabelMeta')
let s:assignee_hl = execute('silent highlight lanAssigneeMeta')
let s:priority_hl = execute('silent highlight lanPriorityMeta')
let s:due_hl = execute('silent highlight lanDueMeta')
let s:deadline_hl = execute('silent highlight lanDeadlineMeta')

if s:label_hl !~# 'ctermfg=196' || s:label_hl !~? 'guifg=#ff0000'
  call s:fail('meta colors runtime: label colors were not applied')
endif
if get(b:, 'lan_label_dynamic_enabled', -1) != 0
  call s:fail('meta colors runtime: label dynamic color must be disabled when label color is configured')
endif
if !empty(get(b:, 'lan_label_dynamic_matchids', []))
  call s:fail('meta colors runtime: label dynamic matches must not remain in fixed mode')
endif
if s:assignee_hl !~# 'ctermfg=33' || s:assignee_hl !~? 'guifg=#00aaff'
  call s:fail('meta colors runtime: assignee colors were not applied')
endif
if s:priority_hl !~# 'ctermfg=46' || s:priority_hl !~? 'guifg=#00ff00'
  call s:fail('meta colors runtime: priority colors were not applied')
endif
if s:due_hl !~# 'ctermfg=21' || s:due_hl !~? 'guifg=#0000ff'
  call s:fail('meta colors runtime: due colors were not applied')
endif
if s:deadline_hl !~# 'ctermfg=201' || s:deadline_hl !~? 'guifg=#ff00ff'
  call s:fail('meta colors runtime: deadline colors were not applied')
endif

call delete(s:tmp)
cquit 0
