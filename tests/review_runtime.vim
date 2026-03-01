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

function! s:day_header(delta_days) abort
  let l:ts = localtime() + (a:delta_days * 86400)
  return '## ' . strftime('%Y-%m-%d', l:ts) . ' (' . strftime('%a', l:ts) . ')'
endfunction

let s:tmp = tempname() . '.md'
let s:today = strftime('%Y-%m-%d')
let s:yesterday = strftime('%Y-%m-%d', localtime() - 86400)
let s:in_two_days = strftime('%Y-%m-%d', localtime() + (2 * 86400))

call writefile([
      \ s:day_header(0),
      \ '',
      \ '### 🔥 Blocking Tasks',
      \ '',
      \ '- [ ] overdue_task @work +alice p1 due:' . s:yesterday,
      \ '- [ ] due_this_week @ops +bob p3 due:' . s:in_two_days,
      \ '- [ ] dup_title @same +carol p1 due:' . s:yesterday,
      \ '- [ ] dup_title @same +carol p3 due:' . s:in_two_days,
      \ '- [x] done_now_task @delta p1',
      \ '- [ ] invalid_due_should_remain due:2026-02-31',
      \ '',
      \ '### 📥 Queue',
      \ '',
      \ '- [ ] current_queue',
      \ '',
      \ '### 🧠 Notes',
      \ '',
      \ '---',
      \ '',
      \ s:day_header(-8),
      \ '',
      \ '### 🔥 Blocking Tasks',
      \ '',
      \ '- [ ] stale_priority @alpha p1',
      \ '- [ ] done_now_task @delta p1',
      \ '- [ ] 🚩 progress_priority @beta p1',
      \ '- [ ] ⌛ waiting_task @gamma p3',
      \ '',
      \ '### 📥 Queue',
      \ '',
      \ '### 🧠 Notes',
      \ '',
      \ '---',
      \ ''
      \ ], s:tmp)

call lan#setup({'file': s:tmp})

try
  execute 'LanReview 7'
catch
  call s:fail('review runtime: :LanReview failed: ' . v:exception)
endtry

if expand('%:t') !=# '[lan-review]'
  call s:fail('review runtime: expected [lan-review], got ' . expand('%:t'))
endif

if !exists('b:lan_label_matchid') || !exists('b:lan_assignee_matchid') || !exists('b:lan_priority_matchid') || !exists('b:lan_due_matchid')
  call s:fail('review runtime: metadata highlight match ids are missing')
endif

let s:label_pat = s:match_pattern('lanLabelMeta')
let s:assignee_pat = s:match_pattern('lanAssigneeMeta')
let s:priority_pat = s:match_pattern('lanPriorityMeta')
let s:due_pat = s:match_pattern('lanDueMeta')
if s:label_pat ==# '' || s:assignee_pat ==# '' || s:priority_pat ==# '' || s:due_pat ==# ''
  call s:fail('review runtime: match patterns are missing')
endif

if matchstr('@same', s:label_pat) !=# '@same'
  call s:fail('review runtime: label pattern did not match @label')
endif
if matchstr('+carol', s:assignee_pat) !=# '+carol'
  call s:fail('review runtime: assignee pattern did not match +assignee')
endif
if matchstr('p3', s:priority_pat) !=# 'p3'
  call s:fail('review runtime: priority pattern did not match pN')
endif
if matchstr('due:' . s:in_two_days, s:due_pat) !=# 'due:' . s:in_two_days
  call s:fail('review runtime: due pattern did not match due date')
endif

let s:content = join(getline(1, '$'), "\n")

if s:content !~# '## Overdue (1)'
  call s:fail('review runtime: overdue count mismatch')
endif
if s:content !~# '## DueThisWeek (2)'
  call s:fail('review runtime: due-this-week count mismatch')
endif
if s:content !~# '## HighPriorityStale (0)'
  call s:fail('review runtime: high-priority-stale count mismatch')
endif
if s:content !~# '## WaitingStale (0)'
  call s:fail('review runtime: waiting-stale count mismatch')
endif

if s:content =~# 'progress_priority'
  call s:fail('review runtime: progress task must not be in HighPriorityStale')
endif

if s:content =~# 'done_now_task'
  call s:fail('review runtime: completed latest task should not appear in review')
endif

if s:content =~# 'stale_priority'
  call s:fail('review runtime: non-today task should be out of review scope')
endif

if s:content =~# 'waiting_task'
  call s:fail('review runtime: non-today waiting task should be out of review scope')
endif

if s:content !~# 'dup_title @same +carol p3 due:' . s:in_two_days
  call s:fail('review runtime: duplicate title latest task missing')
endif

let s:parsed = lan#metadata#parse_task_line('- [ ] invalid_due_should_remain due:2026-02-31')
if get(s:parsed, 'text', '') !~# 'due:2026-02-31'
  call s:fail('review runtime: invalid due token should remain in parsed task text')
endif

let s:assignee_parsed = lan#metadata#parse_task_line('- [ ] assign_task +alice +alice')
if len(get(s:assignee_parsed, 'assignees', [])) != 1 || get(s:assignee_parsed, 'assignees', [])[0] !=# '+alice'
  call s:fail('review runtime: assignee token parse/dedup failed')
endif

let s:assignee_ja_parsed = lan#metadata#parse_task_line('- [ ] assign_task +ななし')
if len(get(s:assignee_ja_parsed, 'assignees', [])) != 1 || get(s:assignee_ja_parsed, 'assignees', [])[0] !=# '+ななし'
  call s:fail('review runtime: japanese assignee token parse failed')
endif

call delete(s:tmp)
cquit 0
