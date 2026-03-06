" autoload/lan/review.vim
" Weekly review report for lan tasks.

function! s:days_between(from_ymd, to_ymd) abort
  let l:from_ts = strptime('%Y-%m-%d', a:from_ymd)
  let l:to_ts = strptime('%Y-%m-%d', a:to_ymd)
  if l:from_ts < 0 || l:to_ts < 0
    return -1
  endif
  return float2nr((l:to_ts - l:from_ts) / 86400.0)
endfunction

function! s:due_date_ymd(due_value) abort
  if a:due_value =~# '^\d\{4}-\d\{2}-\d\{2}$'
    return a:due_value
  endif
  if a:due_value =~# '^\d\{4}-\d\{2}-\d\{2}T\d\{2}:\d\{2}$'
    return strpart(a:due_value, 0, 10)
  endif
  return ''
endfunction

function! s:categorize(tasks, stale_days) abort
  let l:cats = s:empty_categories()
  let l:today = strftime('%Y-%m-%d')
  let l:week_end = strftime('%Y-%m-%d', localtime() + (6 * 86400))
  let l:active_tasks = lan#task_scan#collect_active_tasks(a:tasks)

  for l:task in l:active_tasks
    let l:due_date = s:due_date_ymd(get(l:task, 'due', ''))
    if l:due_date !=# ''
      if l:due_date <# l:today
        call add(l:cats.overdue, l:task)
      elseif l:due_date <=# l:week_end
        call add(l:cats.due_week, l:task)
      endif
    endif

    let l:age_days = -1
    let l:source_date = get(l:task, 'first_seen_date', get(l:task, 'source_date', ''))
    if l:source_date !=# ''
      let l:age_days = s:days_between(l:source_date, l:today)
    endif

    if l:age_days >= a:stale_days
      if get(l:task, 'priority', 0) <= 2
            \ && get(l:task, 'priority', 0) > 0
            \ && !get(l:task, 'progress', 0)
        call add(l:cats.priority_stale, l:task)
      endif

      if get(l:task, 'waiting', 0)
        call add(l:cats.waiting_stale, l:task)
      endif
    endif
  endfor

  return l:cats
endfunction

function! s:empty_categories() abort
  return {
        \ 'overdue': [],
        \ 'due_week': [],
        \ 'priority_stale': [],
        \ 'waiting_stale': []
        \ }
endfunction

function! s:today_task_id_set(tasks, today_ymd) abort
  let l:ids = {}
  for l:task in a:tasks
    if get(l:task, 'source_date', '') !=# a:today_ymd
      continue
    endif
    let l:ids[lan#task_scan#task_identity(l:task)] = 1
  endfor
  return l:ids
endfunction

function! s:filter_tasks_by_id(tasks, id_set) abort
  if empty(a:id_set)
    return []
  endif

  let l:out = []
  for l:task in a:tasks
    if has_key(a:id_set, lan#task_scan#task_identity(l:task))
      call add(l:out, l:task)
    endif
  endfor
  return l:out
endfunction

function! s:task_line(task, detailed) abort
  let l:text = get(a:task, 'text', '')
  if l:text ==# ''
    let l:text = '(no title)'
  endif

  let l:line = '- [ ] ' . l:text
  let l:tokens = lan#metadata#format_tokens(a:task)
  if l:tokens !=# ''
    let l:line .= ' ' . l:tokens
  endif

  if get(a:task, 'progress', 0)
    let l:line .= ' 🚩'
  endif
  if get(a:task, 'waiting', 0)
    let l:line .= ' ⌛'
  endif

  if get(a:task, 'first_seen_date', '') !=# ''
    let l:line .= ' | since:' . a:task.first_seen_date
  endif

  if a:detailed
    let l:line .= ' | lnum:' . a:task.lnum
  endif
  return l:line
endfunction

function! s:sort_datetime_key(value) abort
  if a:value =~# '^\d\{4}-\d\{2}-\d\{2}T\d\{2}:\d\{2}$'
    return a:value
  endif
  if a:value =~# '^\d\{4}-\d\{2}-\d\{2}$'
    return a:value . 'T00:00'
  endif
  return '9999-12-31T23:59'
endfunction

function! s:compare_due_deadline(a, b) abort
  let l:adue = s:sort_datetime_key(get(a:a, 'due', ''))
  let l:bdue = s:sort_datetime_key(get(a:b, 'due', ''))
  if l:adue !=# l:bdue
    return (l:adue <# l:bdue) ? -1 : 1
  endif

  let l:adead = s:sort_datetime_key(get(a:a, 'deadline', ''))
  let l:bdead = s:sort_datetime_key(get(a:b, 'deadline', ''))
  if l:adead !=# l:bdead
    return (l:adead <# l:bdead) ? -1 : 1
  endif

  let l:alnum = get(a:a, 'lnum', 0)
  let l:blnum = get(a:b, 'lnum', 0)
  if l:alnum == l:blnum
    return 0
  endif
  return (l:alnum < l:blnum) ? -1 : 1
endfunction

function! s:sort_tasks_by_due_deadline(tasks) abort
  if len(a:tasks) <= 1
    return copy(a:tasks)
  endif
  return sort(copy(a:tasks), function('s:compare_due_deadline'))
endfunction

function! s:add_section_with_jump(lines, jump_map, title, tasks, detailed) abort
  let l:sorted = s:sort_tasks_by_due_deadline(a:tasks)
  call add(a:lines, '## ' . a:title . ' (' . len(l:sorted) . ')')
  if empty(l:sorted)
    call add(a:lines, '- none')
    call add(a:lines, '')
    return
  endif

  for l:task in l:sorted
    call add(a:lines, s:task_line(l:task, a:detailed))
    let l:line_nr = len(a:lines)
    let a:jump_map[l:line_nr] = {'lnum': get(l:task, 'lnum', 0)}
  endfor
  call add(a:lines, '')
endfunction

function! s:open_note_at_lnum(target_lnum) abort
  let l:path = lan#core#note_file_path()
  let l:review_bufnr = bufnr('%')
  let l:bn = bufnr(l:path)
  let l:note_wins = (l:bn > 0) ? win_findbuf(l:bn) : []

  if !empty(l:note_wins)
    call win_gotoid(l:note_wins[0])
  elseif l:bn > 0
    execute 'silent keepalt buffer ' . l:bn
  else
    execute 'silent keepalt edit' fnameescape(l:path)
  endif

  if line('$') <= 0
    if bufexists(l:review_bufnr)
      execute 'silent! bwipeout ' . l:review_bufnr
    endif
    return
  endif

  let l:lnum = a:target_lnum
  if l:lnum <= 0
    let l:lnum = 1
  elseif l:lnum > line('$')
    let l:lnum = line('$')
  endif
  call cursor(l:lnum, 1)
  if bufexists(l:review_bufnr)
    execute 'silent! bwipeout ' . l:review_bufnr
  endif
endfunction

function! s:open_report(lines, jump_map) abort
  belowright new
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
  silent file [lan-review]
  call setline(1, a:lines)
  let b:lan_review_jump_map = copy(a:jump_map)
  nnoremap <silent><buffer> <C-]> :call lan#review#jump_from_report()<CR>
  call lan#ui#ensure_meta_syntax()
  setlocal nomodifiable
  normal! gg
endfunction

function! lan#review#jump_from_report() abort
  if !exists('b:lan_review_jump_map')
    echo '[lan] This buffer has no review jump map.'
    return
  endif

  let l:current = line('.')
  if !has_key(b:lan_review_jump_map, l:current)
    echo '[lan] Place cursor on a review task line.'
    return
  endif

  let l:target = get(b:lan_review_jump_map[l:current], 'lnum', 0)
  call s:open_note_at_lnum(l:target)
endfunction

function! lan#review#run(qargs, bang) abort
  let l:stale_days = 7
  if a:qargs !=# ''
    if a:qargs !~# '^\d\+$'
      echoerr '[lan] LanReview expects optional integer stale_days.'
      return
    endif
    let l:stale_days = str2nr(a:qargs)
    if l:stale_days <= 0
      echoerr '[lan] stale_days must be greater than zero.'
      return
    endif
  endif

  try
    let l:lines = lan#task_scan#read_note_lines()
  catch
    echoerr v:exception
    return
  endtry

  let l:tasks = lan#task_scan#collect_tasks(l:lines)
  let l:today_ids = s:today_task_id_set(l:tasks, strftime('%Y-%m-%d'))
  let l:targets = s:filter_tasks_by_id(l:tasks, l:today_ids)
  let l:cats = s:categorize(l:targets, l:stale_days)

  let l:out = [
        \ '# Lan Review',
        \ 'generated: ' . strftime('%Y-%m-%d'),
        \ 'stale_days: ' . l:stale_days,
        \ ''
        \ ]

  let l:jump_map = {}
  call s:add_section_with_jump(l:out, l:jump_map, 'Overdue', l:cats.overdue, a:bang)
  call s:add_section_with_jump(l:out, l:jump_map, 'DueThisWeek', l:cats.due_week, a:bang)
  call s:add_section_with_jump(l:out, l:jump_map, 'HighPriorityStale', l:cats.priority_stale, a:bang)
  call s:add_section_with_jump(l:out, l:jump_map, 'WaitingStale', l:cats.waiting_stale, a:bang)

  call s:open_report(l:out, l:jump_map)
  echo '[lan] Review generated.'
endfunction
