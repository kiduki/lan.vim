" autoload/lan/task_toggle.vim
" Task toggles with hierarchy propagation.

function! s:is_task_line(lnum) abort
  return getline(a:lnum) =~# lan#core#rx_task()
endfunction

function! s:task_is_done(lnum) abort
  return getline(a:lnum) =~# '^\s*-\s\[x\]\s*'
endfunction

function! s:strip_progress_flag(line) abort
  return substitute(a:line, '^\(\s*-\s\[[x ]\]\s*\)🚩\s*', '\1', '')
endfunction

function! s:strip_waiting_flag(line) abort
  return substitute(a:line, '^\(\s*-\s\[[x ]\]\s*\)⌛\s*', '\1', '')
endfunction

function! s:toggle_progress_flag_line(line) abort
  if a:line =~# lan#core#rx_progress()
    return s:strip_progress_flag(a:line)
  endif
  let l:line = s:strip_waiting_flag(a:line)
  return substitute(l:line, '^\(\s*-\s\[\s\]\s*\)', '\1🚩 ', '')
endfunction

function! s:toggle_waiting_flag_line(line) abort
  if a:line =~# lan#core#rx_waiting()
    return s:strip_waiting_flag(a:line)
  endif
  let l:line = s:strip_progress_flag(a:line)
  return substitute(l:line, '^\(\s*-\s\[\s\]\s*\)', '\1⌛ ', '')
endfunction

function! s:set_task_done(lnum, done) abort
  let l:line = getline(a:lnum)
  if a:done
    let l:new = substitute(l:line, '^\(\s*-\s\)\[\s\]\(\s*\)', '\1[x]\2', '')
    let l:new = s:strip_progress_flag(l:new)
    let l:new = s:strip_waiting_flag(l:new)
  else
    let l:new = substitute(l:line, '^\(\s*-\s\)\[x\]\(\s*\)', '\1[ ]\2', '')
  endif
  call lan#core#setline_with_undo(a:lnum, l:new)
endfunction

function! s:is_section_break_lnum(lnum) abort
  let l:line = getline(a:lnum)
  return l:line ==# '' || l:line =~# '^###\s' || l:line =~# '^##\s' || l:line =~# lan#core#rx_dash()
endfunction

function! s:find_target_task_lnum_from_cursor() abort
  let l:cur = line('.')
  if s:is_task_line(l:cur)
    return l:cur
  endif

  for l:i in range(l:cur - 1, 1, -1)
    if s:is_section_break_lnum(l:i)
      break
    endif
    if s:is_task_line(l:i)
      return l:i
    endif
  endfor
  return 0
endfunction

function! s:apply_done_to_descendants(root_lnum, done) abort
  let l:root_indent = indent(a:root_lnum)
  let l:last = line('$')

  for l:i in range(a:root_lnum + 1, l:last)
    if s:is_section_break_lnum(l:i)
      break
    endif

    let l:ind = indent(l:i)
    if l:ind <= l:root_indent
      break
    endif

    if s:is_task_line(l:i)
      call s:set_task_done(l:i, a:done)
    endif
  endfor
endfunction

function! s:all_descendants_done(root_lnum) abort
  let l:root_indent = indent(a:root_lnum)
  let l:last = line('$')

  for l:i in range(a:root_lnum + 1, l:last)
    if s:is_section_break_lnum(l:i)
      break
    endif

    let l:ind = indent(l:i)
    if l:ind <= l:root_indent
      break
    endif

    if s:is_task_line(l:i) && !s:task_is_done(l:i)
      return 0
    endif
  endfor
  return 1
endfunction

function! s:propagate_to_ancestors(start_lnum) abort
  let l:child = a:start_lnum
  let l:child_indent = indent(l:child)

  for l:i in range(l:child - 1, 1, -1)
    if s:is_section_break_lnum(l:i)
      break
    endif
    if !s:is_task_line(l:i)
      continue
    endif

    let l:ind = indent(l:i)
    if l:ind < l:child_indent
      let l:done = s:all_descendants_done(l:i)
      call s:set_task_done(l:i, l:done)
      let l:child_indent = l:ind
    endif
  endfor
endfunction

function! lan#task_toggle#done() abort
  if !lan#core#require_note_buffer()
    return
  endif
  let l:target = s:find_target_task_lnum_from_cursor()
  if l:target == 0
    echoerr '[lan] No task line found above cursor.'
    return
  endif

  call lan#core#undo_block_begin()
  let l:new_done = !s:task_is_done(l:target)
  call s:set_task_done(l:target, l:new_done)
  call s:apply_done_to_descendants(l:target, l:new_done)
  call s:propagate_to_ancestors(l:target)
  call lan#core#undo_block_end()
endfunction

function! lan#task_toggle#progress() abort
  if !lan#core#require_note_buffer()
    return
  endif
  let l:target = s:find_target_task_lnum_from_cursor()
  if l:target == 0
    echoerr '[lan] No task line found above cursor.'
    return
  endif
  if s:task_is_done(l:target)
    return
  endif

  let l:line = getline(l:target)
  let l:new = s:toggle_progress_flag_line(l:line)
  call lan#core#undo_block_begin()
  call lan#core#setline_with_undo(l:target, l:new)
  call lan#core#undo_block_end()
endfunction

function! lan#task_toggle#waiting() abort
  if !lan#core#require_note_buffer()
    return
  endif
  let l:target = s:find_target_task_lnum_from_cursor()
  if l:target == 0
    echoerr '[lan] No task line found above cursor.'
    return
  endif
  if s:task_is_done(l:target)
    return
  endif

  let l:line = getline(l:target)
  let l:new = s:toggle_waiting_flag_line(l:line)
  call lan#core#undo_block_begin()
  call lan#core#setline_with_undo(l:target, l:new)
  call lan#core#undo_block_end()
endfunction
