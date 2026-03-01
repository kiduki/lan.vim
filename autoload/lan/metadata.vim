" autoload/lan/metadata.vim
" Task metadata parser for labels / assignees / priority / due date.

function! s:is_valid_date_ymd(date_str) abort
  if a:date_str !~# '^\d\{4}-\d\{2}-\d\{2}$'
    return 0
  endif
  let l:ts = strptime('%Y-%m-%d', a:date_str)
  if l:ts < 0
    return 0
  endif
  return strftime('%Y-%m-%d', l:ts) ==# a:date_str
endfunction

function! s:add_unique(list, value) abort
  if index(a:list, a:value) < 0
    call add(a:list, a:value)
  endif
endfunction

function! lan#metadata#parse_task_line(line) abort
  let l:empty = {
        \ 'is_task': 0,
        \ 'done': 0,
        \ 'text': '',
        \ 'labels': [],
        \ 'assignees': [],
        \ 'priority': 0,
        \ 'due': '',
        \ 'progress': 0,
        \ 'waiting': 0
        \ }

  if a:line !~# lan#core#rx_task()
    return l:empty
  endif

  let l:out = copy(l:empty)
  let l:out.is_task = 1
  let l:out.done = (a:line =~# '^\s*-\s\[x\]\s*') ? 1 : 0

  let l:rest = substitute(a:line, '^\s*-\s\[[x ]\]\s*', '', '')
  if l:rest =~# '^🚩\s*'
    let l:out.progress = 1
    let l:rest = substitute(l:rest, '^🚩\s*', '', '')
  elseif l:rest =~# '^⌛\s*'
    let l:out.waiting = 1
    let l:rest = substitute(l:rest, '^⌛\s*', '', '')
  endif

  let l:body_tokens = []
  for l:token in split(l:rest)
    if l:token =~# '^[@+]\%([[:alnum:]_]\|[^ -~[:space:]]\)\%([[:alnum:]_-]\|[^ -~[:space:]]\)*$'
      if l:token[0] ==# '@'
        call s:add_unique(l:out.labels, l:token)
      else
        call s:add_unique(l:out.assignees, l:token)
      endif
      continue
    endif

    if l:token =~# '^p[1-4]$'
      let l:out.priority = str2nr(strpart(l:token, 1))
      continue
    endif

    if l:token =~# '^due:\d\{4}-\d\{2}-\d\{2}$'
      let l:candidate = strpart(l:token, 4)
      if s:is_valid_date_ymd(l:candidate)
        let l:out.due = l:candidate
      else
        " Keep invalid due token in task text so users can fix it manually.
        call add(l:body_tokens, l:token)
      endif
      continue
    endif

    call add(l:body_tokens, l:token)
  endfor

  let l:out.text = join(l:body_tokens, ' ')
  return l:out
endfunction

function! lan#metadata#format_tokens(task) abort
  let l:tokens = []
  for l:label in get(a:task, 'labels', [])
    call add(l:tokens, l:label)
  endfor
  for l:assignee in get(a:task, 'assignees', [])
    call add(l:tokens, l:assignee)
  endfor
  if get(a:task, 'priority', 0) > 0
    call add(l:tokens, 'p' . a:task.priority)
  endif
  if get(a:task, 'due', '') !=# ''
    call add(l:tokens, 'due:' . a:task.due)
  endif
  return join(l:tokens, ' ')
endfunction
