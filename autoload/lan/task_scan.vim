" autoload/lan/task_scan.vim
" Shared task scanners for review/stats.

function! s:parse_date_header(line) abort
  if a:line =~# lan#core#rx_date()
    return matchstr(a:line, '^## \zs\d\{4}-\d\{2}-\d\{2}\ze ')
  endif
  return ''
endfunction

function! s:is_valid_ymd(date_str) abort
  return a:date_str =~# '^\d\{4}-\d\{2}-\d\{2}$'
endfunction

function! s:is_in_range(date_str, start_ymd, end_ymd) abort
  if !s:is_valid_ymd(a:date_str)
    return 0
  endif
  return a:date_str >=# a:start_ymd && a:date_str <=# a:end_ymd
endfunction

function! lan#task_scan#read_note_lines() abort
  let l:path = lan#core#note_file_path()
  if !filereadable(l:path)
    throw '[lan] Note file not found: ' . l:path
  endif

  let l:bn = bufnr(l:path)
  if l:bn > 0 && getbufvar(l:bn, '&modified')
    return getbufline(l:bn, 1, '$')
  endif
  return readfile(l:path)
endfunction

function! lan#task_scan#task_identity(task) abort
  let l:labels = sort(copy(get(a:task, 'labels', [])))
  let l:assignees = sort(copy(get(a:task, 'assignees', [])))
  return get(a:task, 'text', '')
        \ . '|' . join(l:labels, ',')
        \ . '|' . join(l:assignees, ',')
endfunction

function! lan#task_scan#compare_tasks(a, b) abort
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

function! lan#task_scan#collect_tasks(lines) abort
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

function! lan#task_scan#collect_tasks_between(lines, start_ymd, end_ymd) abort
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

    if !s:is_in_range(l:current_date, a:start_ymd, a:end_ymd)
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

function! lan#task_scan#collect_active_tasks(tasks) abort
  let l:ordered = sort(copy(a:tasks), function('lan#task_scan#compare_tasks'))
  let l:state = {}
  let l:key_order = []

  for l:task in l:ordered
    let l:key = lan#task_scan#task_identity(l:task)
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
