" autoload/lan/note_buffer.vim
" Buffer-based operations used by :Lan and note-local inserts.

" ------------------------------
" generic buffer scanners
" ------------------------------

function! s:open_note_buf() abort
  execute 'silent keepalt edit' fnameescape(lan#core#note_file_path())
endfunction

function! lan#note_buffer#find_line_exact(text) abort
  let l:lnum = 1
  let l:last = line('$')
  while l:lnum <= l:last
    if getline(l:lnum) ==# a:text
      return l:lnum
    endif
    let l:lnum += 1
  endwhile
  return 0
endfunction

function! lan#note_buffer#find_next_by_rx(start_lnum, rx) abort
  let l:lnum = a:start_lnum
  let l:last = line('$')
  while l:lnum <= l:last
    if getline(l:lnum) =~# a:rx
      return l:lnum
    endif
    let l:lnum += 1
  endwhile
  return 0
endfunction

function! lan#note_buffer#section_end(date_lnum) abort
  let l:next = lan#note_buffer#find_next_by_rx(a:date_lnum + 1, lan#core#rx_date())
  return (l:next > 0) ? (l:next - 1) : line('$')
endfunction

function! s:find_subheader_in_range_buf(start_lnum, end_lnum, header_text) abort
  let l:i = a:start_lnum
  while l:i <= a:end_lnum
    if getline(l:i) ==# a:header_text
      return l:i
    endif
    let l:i += 1
  endwhile
  return 0
endfunction

function! s:extract_unfinished_buf(prev_date_lnum, header_text) abort
  let l:prev_end = lan#note_buffer#section_end(a:prev_date_lnum)
  let l:h = s:find_subheader_in_range_buf(a:prev_date_lnum, l:prev_end, a:header_text)
  if l:h == 0
    return []
  endif

  let l:out = []
  let l:in_block = 0
  let l:blocked_indent = -1

  let l:i = l:h + 1
  while l:i <= l:prev_end
    let l:line = getline(l:i)

    if l:line =~# '^###\s' || l:line =~# '^##\s'
      break
    endif

    if l:line ==# ''
      let l:in_block = 0
      let l:blocked_indent = -1
      let l:i += 1
      continue
    endif

    let l:indent = indent(l:i)

    if l:blocked_indent >= 0 && l:indent > l:blocked_indent
      let l:i += 1
      continue
    endif
    if l:blocked_indent >= 0 && l:indent <= l:blocked_indent
      let l:blocked_indent = -1
    endif

    if l:line =~# '^\s*-\s\[\( \|x\)\]\s*'
      let l:in_block = 0

      if l:line =~# '^\s*-\s\[x\]\s*'
        let l:blocked_indent = l:indent
        let l:i += 1
        continue
      endif

      if l:line =~# '^\s*-\s\[ \]\s*'
        let l:in_block = 1
        call add(l:out, l:line)
        let l:i += 1
        continue
      endif
    endif

    if l:in_block
      call add(l:out, l:line)
    endif

    let l:i += 1
  endwhile

  return l:out
endfunction

function! s:append_lines_under_buf(today_lnum, header_text, lines) abort
  if empty(a:lines)
    return 0
  endif

  let l:today_end = lan#note_buffer#section_end(a:today_lnum)
  let l:h = s:find_subheader_in_range_buf(a:today_lnum, l:today_end, a:header_text)
  if l:h == 0
    call lan#core#die('Missing required header in TODAY: ' . a:header_text)
  endif

  let l:sec_end = l:today_end + 1
  for l:i in range(l:h + 1, l:today_end)
    let l:line = getline(l:i)
    if lan#core#is_header_line_str(l:line)
      let l:sec_end = l:i
      break
    endif
  endfor

  let l:ins = l:sec_end - 1
  while l:ins > l:h
    let l:cur = getline(l:ins)
    if l:cur ==# '' || lan#core#ws_only(l:cur)
      let l:ins -= 1
      continue
    endif
    break
  endwhile
  if l:ins <= l:h
    let l:ins = l:h
  endif

  call append(l:ins, a:lines)
  return l:ins + len(a:lines)
endfunction

function! s:insert_today_template_buf() abort
  let l:tmpl = lan#core#today_template_lines()
  if line('$') == 1 && getline(1) ==# ''
    call setline(1, l:tmpl[0])
    if len(l:tmpl) > 1
      call append(1, l:tmpl[1:])
    endif
  else
    call append(0, l:tmpl)
  endif
  return len(l:tmpl)
endfunction

function! s:carry_over_from_prev_buf(today_lnum, inserted_lines) abort
  let l:start = a:inserted_lines + 1
  let l:prev = lan#note_buffer#find_next_by_rx(l:start, lan#core#rx_date())
  if l:prev == 0
    return
  endif

  let l:block_lines = s:extract_unfinished_buf(l:prev, lan#core#hdr_block())
  let l:queue_lines = s:extract_unfinished_buf(l:prev, lan#core#hdr_queue())

  call s:append_lines_under_buf(a:today_lnum, lan#core#hdr_block(), l:block_lines)
  call s:append_lines_under_buf(a:today_lnum, lan#core#hdr_queue(), l:queue_lines)
endfunction

function! lan#note_buffer#open() abort
  call s:open_note_buf()

  let l:today_lnum = lan#note_buffer#find_line_exact(lan#core#today_header())
  if l:today_lnum > 0
    return
  endif

  let l:inserted = s:insert_today_template_buf()
  call s:carry_over_from_prev_buf(1, l:inserted)
endfunction

function! s:header_and_seed_line(kind) abort
  if a:kind ==# 'block'
    return [lan#core#hdr_block(), '- [ ] ']
  elseif a:kind ==# 'queue'
    return [lan#core#hdr_queue(), '- [ ] ']
  endif
  return [lan#core#hdr_notes(), '- ']
endfunction

function! lan#note_buffer#insert_strict(kind) abort
  try
    let l:today_lnum = lan#note_buffer#find_line_exact(lan#core#today_header())
    if l:today_lnum == 0
      call lan#core#die('Today section missing. Run :Lan first.')
    endif

    let [l:hdr, l:seed] = s:header_and_seed_line(a:kind)
    let l:inserted = s:append_lines_under_buf(l:today_lnum, l:hdr, [l:seed])
    if l:inserted == 0
      call cursor(line('$'), 1)
      startinsert!
      return
    endif
    call lan#core#startinsert_for_new_item(l:inserted)
  catch /^lan_error$/
  endtry
endfunction

function! s:find_date_header_from_cursor() abort
  for l:i in range(line('.'), 1, -1)
    if getline(l:i) =~# lan#core#rx_date()
      return l:i
    endif
  endfor
  return 0
endfunction

function! s:find_section_kind_from_cursor(date_lnum) abort
  for l:i in range(line('.'), a:date_lnum + 1, -1)
    let l:line = getline(l:i)
    if l:line ==# lan#core#hdr_block()
      return 'block'
    elseif l:line ==# lan#core#hdr_queue()
      return 'queue'
    elseif l:line ==# lan#core#hdr_notes()
      return 'memo'
    endif
  endfor
  return ''
endfunction

function! lan#note_buffer#map_add_auto_keys() abort
  let l:key_notation = substitute(g:lan_note_map_add_auto, '<\([^>]\+\)>', '\= "\\<" . toupper(submatch(1)) . ">"', 'g')
  return eval('"' . escape(l:key_notation, '"') . '"')
endfunction

function! lan#note_buffer#can_insert_auto() abort
  let l:col = col('.')
  if l:col <= 1
    return 0
  endif

  let l:line = getline('.')
  let l:prev_char = strpart(l:line, l:col - 2, 1)
  return l:prev_char !~# '[ \t]'
endfunction

function! lan#note_buffer#insert_auto() abort
  try
    let l:date_lnum = s:find_date_header_from_cursor()
    if l:date_lnum == 0
      call lan#core#die('Date section not found above cursor.')
    endif

    let l:sec_end = lan#note_buffer#section_end(l:date_lnum)
    if line('.') < l:date_lnum || line('.') > l:sec_end
      call lan#core#die('Cursor is outside the date section.')
    endif

    let l:kind = s:find_section_kind_from_cursor(l:date_lnum)
    if empty(l:kind)
      call lan#core#die('Section header not found above cursor.')
    endif

    let [l:hdr, l:seed] = s:header_and_seed_line(l:kind)

    let l:inserted = s:append_lines_under_buf(l:date_lnum, l:hdr, [l:seed])
    if l:inserted == 0
      call cursor(line('$'), 1)
      startinsert!
      return
    endif
    call lan#core#startinsert_for_new_item(l:inserted)
  catch /^lan_error$/
  endtry
endfunction
