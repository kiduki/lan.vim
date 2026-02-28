" autoload/lan/file_ops.vim
" File-based operations for Lanb/Lanq/Lann.

" ------------------------------
" list scanners and section utils
" ------------------------------

function! s:find_line_exact_list(lines, text) abort
  for l:i in range(0, len(a:lines) - 1)
    if a:lines[l:i] ==# a:text
      return l:i
    endif
  endfor
  return -1
endfunction

function! s:find_next_by_rx_list(lines, start_idx, rx) abort
  for l:i in range(a:start_idx, len(a:lines) - 1)
    if a:lines[l:i] =~# a:rx
      return l:i
    endif
  endfor
  return -1
endfunction

function! s:section_end_list(lines, date_idx) abort
  let l:next = s:find_next_by_rx_list(a:lines, a:date_idx + 1, lan#core#rx_date())
  return (l:next >= 0) ? (l:next - 1) : (len(a:lines) - 1)
endfunction

function! s:find_subheader_in_range_list(lines, start_idx, end_idx, header_text) abort
  for l:i in range(a:start_idx, a:end_idx)
    if a:lines[l:i] ==# a:header_text
      return l:i
    endif
  endfor
  return -1
endfunction

function! s:extract_unfinished_list(lines, prev_date_idx, header_text) abort
  let l:prev_end = s:section_end_list(a:lines, a:prev_date_idx)
  let l:h = s:find_subheader_in_range_list(a:lines, a:prev_date_idx, l:prev_end, a:header_text)
  if l:h < 0
    return []
  endif

  let l:out = []
  let l:in_block = 0
  let l:blocked_indent = -1

  for l:i in range(l:h + 1, l:prev_end)
    let l:line = a:lines[l:i]

    if l:line =~# '^###\s' || l:line =~# '^##\s'
      break
    endif

    if l:line ==# ''
      let l:in_block = 0
      let l:blocked_indent = -1
      continue
    endif

    let l:indent = strlen(matchstr(l:line, '^\s*'))

    if l:blocked_indent >= 0 && l:indent > l:blocked_indent
      continue
    endif
    if l:blocked_indent >= 0 && l:indent <= l:blocked_indent
      let l:blocked_indent = -1
    endif

    if l:line =~# '^\s*-\s\[\( \|x\)\]\s*'
      let l:in_block = 0

      if l:line =~# '^\s*-\s\[x\]\s*'
        let l:blocked_indent = l:indent
        continue
      endif

      if l:line =~# '^\s*-\s\[ \]\s*'
        let l:in_block = 1
        call add(l:out, l:line)
        continue
      endif
    endif

    if l:in_block
      call add(l:out, l:line)
    endif
  endfor

  return l:out
endfunction

function! s:insert_today_if_missing_list(lines) abort
  let l:today = lan#core#today_header()
  let l:today_idx = s:find_line_exact_list(a:lines, l:today)
  if l:today_idx >= 0
    return [a:lines, l:today_idx, 0]
  endif

  let l:tmpl = lan#core#today_template_lines()
  let l:new = l:tmpl + a:lines
  return [l:new, 0, 1]
endfunction

function! s:carry_over_if_created_list(lines) abort
  let l:tmpl_len = len(lan#core#today_template_lines())
  let l:prev = s:find_next_by_rx_list(a:lines, l:tmpl_len, lan#core#rx_date())
  if l:prev < 0
    return a:lines
  endif

  let l:block_lines = s:extract_unfinished_list(a:lines, l:prev, lan#core#hdr_block())
  let l:queue_lines = s:extract_unfinished_list(a:lines, l:prev, lan#core#hdr_queue())

  let l:today_end = s:section_end_list(a:lines, 0)

  let l:block_hdr = s:find_subheader_in_range_list(a:lines, 0, l:today_end, lan#core#hdr_block())
  let l:queue_hdr = s:find_subheader_in_range_list(a:lines, 0, l:today_end, lan#core#hdr_queue())

  if l:block_hdr < 0 || l:queue_hdr < 0
    return a:lines
  endif

  let l:lines2 = a:lines
  let l:lines2 = s:insert_at_section_end_list(l:lines2, 0, lan#core#hdr_block(), l:block_lines)
  let l:lines2 = s:insert_at_section_end_list(l:lines2, 0, lan#core#hdr_queue(), l:queue_lines)
  return l:lines2
endfunction

function! s:insert_at_section_end_list(lines, today_idx, header_text, new_lines) abort
  if empty(a:new_lines)
    return a:lines
  endif

  let l:today_end = s:section_end_list(a:lines, a:today_idx)
  let l:h = s:find_subheader_in_range_list(a:lines, a:today_idx, l:today_end, a:header_text)
  if l:h < 0
    return a:lines
  endif

  let l:sec_end = l:today_end + 1
  for l:i in range(l:h + 1, l:today_end)
    let l:line = a:lines[l:i]
    if lan#core#is_header_line_str(l:line)
      let l:sec_end = l:i
      break
    endif
  endfor

  let l:ins = l:sec_end - 1
  while l:ins > l:h
    let l:cur = a:lines[l:ins]
    if l:cur ==# '' || lan#core#ws_only(l:cur)
      let l:ins -= 1
      continue
    endif
    break
  endwhile
  if l:ins <= l:h
    let l:ins = l:h
  endif

  let l:out = copy(a:lines)
  for l:j in reverse(copy(a:new_lines))
    call insert(l:out, l:j, l:ins + 1)
  endfor
  return l:out
endfunction

function! s:header_and_lines(kind, text) abort
  if a:kind ==# 'block'
    return [lan#core#hdr_block(), ['- [ ] ' . a:text]]
  elseif a:kind ==# 'queue'
    return [lan#core#hdr_queue(), ['- [ ] ' . a:text]]
  endif
  return [lan#core#hdr_notes(), ['- ' . a:text]]
endfunction

function! lan#file_ops#add(kind, text) abort
  let l:path = lan#core#note_file_path()

  try
    let l:dir = fnamemodify(l:path, ":h")
    if !isdirectory(l:dir)
      call mkdir(l:dir, "p")
    endif
    if !filereadable(l:path)
      call writefile([], l:path)
    endif

    let l:lines = readfile(l:path)

    let [l:lines2, l:today_idx, l:created] = s:insert_today_if_missing_list(l:lines)
    let l:lines3 = l:lines2
    if l:created
      let l:lines3 = s:carry_over_if_created_list(l:lines3)
    endif

    let [l:hdr, l:add_lines] = s:header_and_lines(a:kind, a:text)

    let l:today_end = s:section_end_list(l:lines3, l:today_idx)
    let l:h = s:find_subheader_in_range_list(l:lines3, l:today_idx, l:today_end, l:hdr)
    if l:h < 0
      echoerr '[lan] Missing required header in TODAY: ' . l:hdr
      return
    endif

    let l:lines4 = s:insert_at_section_end_list(l:lines3, l:today_idx, l:hdr, l:add_lines)

    call writefile(l:lines4, l:path)

    let l:bn = bufnr(l:path)
    if l:bn > 0
      execute 'checktime ' . l:bn
    endif

  catch
    echoerr '[lan] Failed to add: ' . v:exception
  endtry
endfunction
