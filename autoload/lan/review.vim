" autoload/lan/review.vim
" Weekly review report for lan tasks.

function! s:parse_date_header(line) abort
  if a:line =~# lan#core#rx_date()
    return matchstr(a:line, '^## \zs\d\{4}-\d\{2}-\d\{2}\ze ')
  endif
  return ''
endfunction

function! s:days_between(from_ymd, to_ymd) abort
  let l:from_ts = strptime('%Y-%m-%d', a:from_ymd)
  let l:to_ts = strptime('%Y-%m-%d', a:to_ymd)
  if l:from_ts < 0 || l:to_ts < 0
    return -1
  endif
  return float2nr((l:to_ts - l:from_ts) / 86400.0)
endfunction

function! s:is_valid_ymd(date_str) abort
  return a:date_str =~# '^\d\{4}-\d\{2}-\d\{2}$'
endfunction

function! s:task_identity(task) abort
  let l:labels = sort(copy(get(a:task, 'labels', [])))
  return get(a:task, 'text', '')
        \ . '|' . join(l:labels, ',')
endfunction

function! s:compare_tasks(a, b) abort
  let l:ad = get(a:a, 'source_date', '')
  let l:bd = get(a:b, 'source_date', '')
  if l:ad !=# l:bd
    return (l:ad <# l:bd) ? -1 : 1
  endif

  let l:al = get(a:a, 'lnum', 0)
  let l:bl = get(a:b, 'lnum', 0)
  if l:al == l:bl
    return 0
  endif
  return (l:al < l:bl) ? -1 : 1
endfunction

function! s:collect_active_tasks(tasks) abort
  let l:ordered = sort(copy(a:tasks), function('s:compare_tasks'))
  let l:state = {}
  let l:key_order = []

  for l:task in l:ordered
    let l:key = s:task_identity(l:task)
    if !has_key(l:state, l:key)
      let l:state[l:key] = {
            \ 'is_open': 0,
            \ 'open_start': '',
            \ 'latest': {}
            \ }
      call add(l:key_order, l:key)
    endif

    if get(l:task, 'done', 0)
      let l:state[l:key].is_open = 0
      let l:state[l:key].open_start = ''
      let l:state[l:key].latest = copy(l:task)
      continue
    endif

    let l:src = get(l:task, 'source_date', '')
    if l:state[l:key].open_start ==# '' && s:is_valid_ymd(l:src)
      let l:state[l:key].open_start = l:src
    endif

    let l:state[l:key].is_open = 1
    let l:state[l:key].latest = copy(l:task)
  endfor

  let l:out = []
  for l:key in l:key_order
    if !get(l:state[l:key], 'is_open', 0)
      continue
    endif

    let l:task = copy(l:state[l:key].latest)
    if get(l:state[l:key], 'open_start', '') !=# ''
      let l:task.first_seen_date = l:state[l:key].open_start
    else
      let l:task.first_seen_date = get(l:task, 'source_date', '')
    endif
    call add(l:out, l:task)
  endfor
  return l:out
endfunction

function! s:categorize(tasks, stale_days) abort
  let l:cats = s:empty_categories()
  let l:today = strftime('%Y-%m-%d')
  let l:week_end = strftime('%Y-%m-%d', localtime() + (6 * 86400))
  let l:active_tasks = s:collect_active_tasks(a:tasks)

  for l:task in l:active_tasks
    let l:due = get(l:task, 'due', '')
    if l:due !=# ''
      if l:due <# l:today
        call add(l:cats.overdue, l:task)
      elseif l:due <=# l:week_end
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

function! s:collect_tasks(lines) abort
  let l:tasks = []
  let l:current_date = ''
  if empty(a:lines)
    return l:tasks
  endif

  for l:idx in range(0, len(a:lines) - 1)
    let l:line = a:lines[l:idx]
    let l:date_header = s:parse_date_header(l:line)
    if l:date_header !=# ''
      let l:current_date = l:date_header
      continue
    endif

    let l:task = lan#metadata#parse_task_line(l:line)
    if !get(l:task, 'is_task', 0)
      continue
    endif

    let l:task.source_date = l:current_date
    let l:task.lnum = l:idx + 1
    call add(l:tasks, l:task)
  endfor

  return l:tasks
endfunction

function! s:empty_categories() abort
  return {
        \ 'overdue': [],
        \ 'due_week': [],
        \ 'priority_stale': [],
        \ 'waiting_stale': []
        \ }
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

function! s:add_section(lines, title, tasks, detailed) abort
  call add(a:lines, '## ' . a:title . ' (' . len(a:tasks) . ')')
  if empty(a:tasks)
    call add(a:lines, '- none')
  else
    for l:task in a:tasks
      call add(a:lines, s:task_line(l:task, a:detailed))
    endfor
  endif
  call add(a:lines, '')
endfunction

function! s:open_report(lines) abort
  belowright new
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
  silent file [lan-review]
  call setline(1, a:lines)
  setlocal nomodifiable
  normal! gg
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

  let l:path = lan#core#note_file_path()
  if !filereadable(l:path)
    echoerr '[lan] Note file not found: ' . l:path
    return
  endif

  let l:bn = bufnr(l:path)
  if l:bn > 0 && getbufvar(l:bn, '&modified')
    let l:lines = getbufline(l:bn, 1, '$')
  else
    let l:lines = readfile(l:path)
  endif
  let l:tasks = s:collect_tasks(l:lines)
  let l:cats = s:categorize(l:tasks, l:stale_days)

  let l:out = [
        \ '# Lan Review',
        \ 'generated: ' . strftime('%Y-%m-%d'),
        \ 'stale_days: ' . l:stale_days,
        \ ''
        \ ]

  call s:add_section(l:out, 'Overdue', l:cats.overdue, a:bang)
  call s:add_section(l:out, 'DueThisWeek', l:cats.due_week, a:bang)
  call s:add_section(l:out, 'HighPriorityStale', l:cats.priority_stale, a:bang)
  call s:add_section(l:out, 'WaitingStale', l:cats.waiting_stale, a:bang)

  call s:open_report(l:out)
  echo '[lan] Review generated.'
endfunction
