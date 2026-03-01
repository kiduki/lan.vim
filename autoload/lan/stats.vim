" autoload/lan/stats.vim
" Weekly/today task metrics.

function! s:is_valid_ymd(date_str) abort
  return a:date_str =~# '^\d\{4}-\d\{2}-\d\{2}$'
endfunction

function! s:is_in_range(date_str, start_ymd, end_ymd) abort
  if !s:is_valid_ymd(a:date_str)
    return 0
  endif
  return a:date_str >=# a:start_ymd && a:date_str <=# a:end_ymd
endfunction

function! s:week_start_ymd(today_ymd) abort
  if !s:is_valid_ymd(a:today_ymd)
    return ''
  endif
  let l:today_ts = strptime('%Y-%m-%d', a:today_ymd)
  if l:today_ts < 0
    return ''
  endif
  let l:weekday = str2nr(strftime('%u', l:today_ts))
  return strftime('%Y-%m-%d', l:today_ts - ((l:weekday - 1) * 86400))
endfunction

function! s:compute(tasks, today_ymd) abort
  let l:week_start = s:week_start_ymd(a:today_ymd)
  if l:week_start ==# ''
    let l:week_start = a:today_ymd
  endif
  let l:ordered = sort(copy(a:tasks), function('lan#task_scan#compare_tasks'))
  let l:state = {}
  let l:out = {
        \ 'week_done': 0,
        \ 'today_done': 0,
        \ 'added': 0,
        \ 'remaining': 0
        \ }

  for l:task in l:ordered
    let l:key = lan#task_scan#task_identity(l:task)
    let l:src = get(l:task, 'source_date', '')
    if !has_key(l:state, l:key)
      let l:state[l:key] = {'is_open': 0, 'seen': 0}
    endif

    if !l:state[l:key].seen
      let l:state[l:key].seen = 1
      if s:is_in_range(l:src, l:week_start, a:today_ymd)
        let l:out.added += 1
      endif
    endif

    if get(l:task, 'done', 0)
      if s:is_in_range(l:src, l:week_start, a:today_ymd)
        let l:out.week_done += 1
      endif
      if l:src ==# a:today_ymd
        let l:out.today_done += 1
      endif
      let l:state[l:key].is_open = 0
      continue
    endif

    let l:state[l:key].is_open = 1
  endfor

  for l:key in keys(l:state)
    if get(l:state[l:key], 'is_open', 0)
      let l:out.remaining += 1
    endif
  endfor

  return l:out
endfunction

function! lan#stats#run() abort
  let l:today = strftime('%Y-%m-%d')
  let l:week_start = s:week_start_ymd(l:today)
  if l:week_start ==# ''
    let l:week_start = l:today
  endif
  try
    let l:lines = lan#task_scan#read_note_lines()
  catch
    echoerr v:exception
    return
  endtry

  let l:tasks = lan#task_scan#collect_tasks_between(l:lines, l:week_start, l:today)
  let l:stats = s:compute(l:tasks, l:today)

  echo '[lan] week_done=' . l:stats.week_done
        \ . ' today_done=' . l:stats.today_done
        \ . ' added=' . l:stats.added
        \ . ' remaining=' . l:stats.remaining
endfunction
