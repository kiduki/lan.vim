" plugin/lan.vim
" Long-Ass Note
"
" Commands:
"   :Lan            ノートを開く。今日が無ければ先頭に作成し、前日の未完了を引継。
"   :Lanb {text}    ノートを開かずに、今日の Blocking Tasks 末尾へ "- [ ] {text}" を追記。
"   :Lanq {text}    ノートを開かずに、今日の Queue 末尾へ "- [ ] {text}" を追記。
"   :Lann {text}    ノートを開かずに、今日の Notes 末尾へ "- {text}" を追記。
"
" Note-buffer mappings (STRICT; do NOT auto-create; error if missing):
"   g:lan_note_map_add_block   default: <Leader>lanb   -> TODAY Blocking に "- [ ] " を追加して挿入へ
"   g:lan_note_map_add_queue   default: <Leader>lanq   -> TODAY Queue    に "- [ ] " を追加して挿入へ
"   g:lan_note_map_add_note    default: <Leader>lann   -> TODAY Notes    に "- " を追加して挿入へ
"   g:lan_note_map_add_auto    default: <Leader>lana   -> カーソル位置のセクションへ追加して挿入へ（INSERT）
"   g:lan_note_map_toggle      default: <Leader>lanx   -> 親子も含めて完了トグル（階層対応）

if exists('g:loaded_lan_plugin')
  finish
endif
let g:loaded_lan_plugin = 1

" ---------------- user config ----------------
if !exists('g:lan_file')
  let g:lan_file = expand('~/long-ass-note.md')
endif

if !exists('g:lan_note_map_add_block')
  let g:lan_note_map_add_block = '<Leader>lanb'
endif
if !exists('g:lan_note_map_add_queue')
  let g:lan_note_map_add_queue = '<Leader>lanq'
endif
if !exists('g:lan_note_map_add_note')
  let g:lan_note_map_add_note = '<Leader>lann'
endif
if !exists('g:lan_note_map_add_auto')
  let g:lan_note_map_add_auto = '<Leader>lana'
endif
if !exists('g:lan_note_map_toggle')
  let g:lan_note_map_toggle = '<Leader>lanx'
endif

" ---------------- constants ----------------
let s:RX_DATE   = '^## \d\{4}-\d\{2}-\d\{2} (\u\l\l)$'
let s:RX_DASH   = '^-\{3,}$'
let s:RX_TASK   = '^\s*-\s\[\( \|x\)\]\s*'

let s:HDR_BLOCK = '### 🔥 Blocking Tasks'
let s:HDR_QUEUE = '### 📥 Queue'
let s:HDR_NOTES = '### 🧠 Notes'

" ---------------- commands ----------------
command! Lan  call s:lan_open()
command! -nargs=+ Lanb call s:lan_add_file('block', <q-args>)
command! -nargs=+ Lanq call s:lan_add_file('queue', <q-args>)
command! -nargs=+ Lann call s:lan_add_file('memo',  <q-args>)

" ---------------- mappings (note buffer only) ----------------
augroup lan_note_maps
  autocmd!
  autocmd BufEnter * call s:maybe_define_note_maps()
augroup END

function! s:maybe_define_note_maps() abort
  if expand('%:p') !=# expand(g:lan_file)
    return
  endif

  " buffer-local only; do not override if user already mapped
  if empty(maparg(g:lan_note_map_add_block, 'n'))
    execute 'nnoremap <silent><buffer> ' . g:lan_note_map_add_block .
          \ ' :call <SID>lan_note_insert_strict("block")<CR>'
  endif
  if empty(maparg(g:lan_note_map_add_queue, 'n'))
    execute 'nnoremap <silent><buffer> ' . g:lan_note_map_add_queue .
          \ ' :call <SID>lan_note_insert_strict("queue")<CR>'
  endif
  if empty(maparg(g:lan_note_map_add_note, 'n'))
    execute 'nnoremap <silent><buffer> ' . g:lan_note_map_add_note .
          \ ' :call <SID>lan_note_insert_strict("memo")<CR>'
  endif
  if empty(maparg(g:lan_note_map_add_auto, 'i'))
    execute 'inoremap <silent><buffer> ' . g:lan_note_map_add_auto .
          \ ' <C-o>:call <SID>lan_note_insert_auto()<CR>'
  endif
  if empty(maparg(g:lan_note_map_toggle, 'n'))
    execute 'nnoremap <silent><buffer> ' . g:lan_note_map_toggle .
          \ ' :call <SID>lan_toggle_done()<CR>'
  endif
endfunction

" ---------------- small error helper ----------------
function! s:die(msg) abort
  echoerr '[lan] ' . a:msg
  throw 'lan_error'
endfunction

" ---------------- shared helpers ----------------
function! s:today_header() abort
  return '## ' . strftime('%Y-%m-%d') . ' (' . strftime('%a') . ')'
endfunction

function! s:today_template_lines() abort
  return [
        \ s:today_header(),
        \ '',
        \ s:HDR_BLOCK,
        \ '',
        \ s:HDR_QUEUE,
        \ '',
        \ s:HDR_NOTES,
        \ '',
        \ '---',
        \ ''
        \ ]
endfunction

function! s:is_header_line_str(line) abort
  return a:line =~# '^###\s' || a:line =~# '^##\s' || a:line =~# s:RX_DASH
endfunction

function! s:ws_only(line) abort
  return a:line =~# '^\s\+$'
endfunction

" ===============================
"  Buffer-based (used by :Lan and note-local ops)
" ===============================

function! s:open_note_buf() abort
  execute 'silent keepalt edit' fnameescape(g:lan_file)
endfunction

function! s:find_line_exact_buf(text) abort
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

function! s:find_next_by_rx_buf(start_lnum, rx) abort
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

function! s:section_end_buf(date_lnum) abort
  let l:next = s:find_next_by_rx_buf(a:date_lnum + 1, s:RX_DATE)
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

" --- carry-over extractor (BUFFER) ---
" 未完了タスクを「複数行ブロック」として抽出し、完了タスク配下（より深いインデント）は除外
function! s:extract_unfinished_buf(prev_date_lnum, header_text) abort
  let l:prev_end = s:section_end_buf(a:prev_date_lnum)
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

  let l:today_end = s:section_end_buf(a:today_lnum)
  let l:h = s:find_subheader_in_range_buf(a:today_lnum, l:today_end, a:header_text)
  if l:h == 0
    call s:die('Missing required header in TODAY: ' . a:header_text)
  endif

  " 今日セクション内の対象ヘッダの「セクション末尾」に挿入
  let l:sec_end = l:today_end + 1
  for l:i in range(l:h + 1, l:today_end)
    let l:line = getline(l:i)
    if s:is_header_line_str(l:line)
      let l:sec_end = l:i
      break
    endif
  endfor

  let l:ins = l:sec_end - 1
  while l:ins > l:h
    let l:cur = getline(l:ins)
    if l:cur ==# '' || s:ws_only(l:cur)
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
  call append(0, s:today_template_lines())
  return len(s:today_template_lines())
endfunction

function! s:carry_over_from_prev_buf(today_lnum, inserted_lines) abort
  let l:start = a:inserted_lines + 1
  let l:prev = s:find_next_by_rx_buf(l:start, s:RX_DATE)
  if l:prev == 0
    return
  endif

  let l:block_lines = s:extract_unfinished_buf(l:prev, s:HDR_BLOCK)
  let l:queue_lines = s:extract_unfinished_buf(l:prev, s:HDR_QUEUE)

  call s:append_lines_under_buf(a:today_lnum, s:HDR_BLOCK, l:block_lines)
  call s:append_lines_under_buf(a:today_lnum, s:HDR_QUEUE, l:queue_lines)
endfunction

" :Lan
function! s:lan_open() abort
  call s:open_note_buf()

  let l:today_lnum = s:find_line_exact_buf(s:today_header())
  if l:today_lnum > 0
    return
  endif

  let l:inserted = s:insert_today_template_buf()
  call s:carry_over_from_prev_buf(1, l:inserted)
endfunction

" note-local STRICT insert (今日/見出しが無ければエラー。自動作成しない)
function! s:lan_note_insert_strict(kind) abort
  try
    let l:today_lnum = s:find_line_exact_buf(s:today_header())
    if l:today_lnum == 0
      call s:die('Today section missing. Run :Lan first.')
    endif

    if a:kind ==# 'block'
      let l:hdr = s:HDR_BLOCK
    elseif a:kind ==# 'queue'
      let l:hdr = s:HDR_QUEUE
    else
      let l:hdr = s:HDR_NOTES
    endif

    if a:kind ==# 'memo'
      let l:inserted = s:append_lines_under_buf(l:today_lnum, l:hdr, ['- '])
      if l:inserted == 0
        call cursor(line('$'), 1)
        startinsert!
        return
      endif
      call cursor(l:inserted, 1)
      startinsert!
    else
      let l:inserted = s:append_lines_under_buf(l:today_lnum, l:hdr, ['- [ ] '])
      " 追加した行（末尾）に移動して行末で挿入へ
      if l:inserted == 0
        " 念のため：末尾に移動して挿入へ
        call cursor(line('$'), 1)
        startinsert!
        return
      endif
      call cursor(l:inserted, 1)
      startinsert!
    endif
  catch /^lan_error$/
  endtry
endfunction

function! s:find_date_header_from_cursor() abort
  for l:i in range(line('.'), 1, -1)
    if getline(l:i) =~# s:RX_DATE
      return l:i
    endif
  endfor
  return 0
endfunction

function! s:find_section_kind_from_cursor(date_lnum) abort
  for l:i in range(line('.'), a:date_lnum + 1, -1)
    let l:line = getline(l:i)
    if l:line ==# s:HDR_BLOCK
      return 'block'
    elseif l:line ==# s:HDR_QUEUE
      return 'queue'
    elseif l:line ==# s:HDR_NOTES
      return 'memo'
    endif
  endfor
  return ''
endfunction

function! s:lan_note_insert_auto() abort
  try
    if col('.') != col('$')
      return
    endif

    let l:date_lnum = s:find_date_header_from_cursor()
    if l:date_lnum == 0
      call s:die('Date section not found above cursor.')
    endif

    let l:sec_end = s:section_end_buf(l:date_lnum)
    if line('.') < l:date_lnum || line('.') > l:sec_end
      call s:die('Cursor is outside the date section.')
    endif

    let l:kind = s:find_section_kind_from_cursor(l:date_lnum)
    if empty(l:kind)
      call s:die('Section header not found above cursor.')
    endif

    if l:kind ==# 'block'
      let l:hdr = s:HDR_BLOCK
      let l:lines = ['- [ ] ']
    elseif l:kind ==# 'queue'
      let l:hdr = s:HDR_QUEUE
      let l:lines = ['- [ ] ']
    else
      let l:hdr = s:HDR_NOTES
      let l:lines = ['- ']
    endif

    let l:inserted = s:append_lines_under_buf(l:date_lnum, l:hdr, l:lines)
    if l:inserted == 0
      call cursor(line('$'), 1)
      startinsert!
      return
    endif
    call cursor(l:inserted, 1)
    startinsert!
  catch /^lan_error$/
  endtry
endfunction

" ===============================
"  File-based (Lanb/Lanq/Lann): do NOT open buffer
" ===============================

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
  let l:next = s:find_next_by_rx_list(a:lines, a:date_idx + 1, s:RX_DATE)
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

" carry-over extractor (LIST) — buffer版と同等ルール
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
  let l:today = s:today_header()
  let l:today_idx = s:find_line_exact_list(a:lines, l:today)
  if l:today_idx >= 0
    return [a:lines, l:today_idx, 0]
  endif

  let l:tmpl = s:today_template_lines()
  let l:new = l:tmpl + a:lines
  return [l:new, 0, 1]
endfunction

function! s:carry_over_if_created_list(lines) abort
  " 今日が作成された直後（先頭テンプレの直下）から最初に見つかる date を前日扱いにして引継
  let l:tmpl_len = len(s:today_template_lines())
  let l:prev = s:find_next_by_rx_list(a:lines, l:tmpl_len, s:RX_DATE)
  if l:prev < 0
    return a:lines
  endif

  let l:block_lines = s:extract_unfinished_list(a:lines, l:prev, s:HDR_BLOCK)
  let l:queue_lines = s:extract_unfinished_list(a:lines, l:prev, s:HDR_QUEUE)

  " 今日の各セクション末尾へ挿入（末尾に積む＝要求）
  let l:today_end = s:section_end_list(a:lines, 0)

  let l:block_hdr = s:find_subheader_in_range_list(a:lines, 0, l:today_end, s:HDR_BLOCK)
  let l:queue_hdr = s:find_subheader_in_range_list(a:lines, 0, l:today_end, s:HDR_QUEUE)

  " テンプレが壊れてるなら引継は諦める（でもファイルは壊さない）
  if l:block_hdr < 0 || l:queue_hdr < 0
    return a:lines
  endif

  let l:lines2 = a:lines
  let l:lines2 = s:insert_at_section_end_list(l:lines2, 0, s:HDR_BLOCK, l:block_lines)
  let l:lines2 = s:insert_at_section_end_list(l:lines2, 0, s:HDR_QUEUE, l:queue_lines)
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

  " 対象セクションの終端（次の見出し/区切り or 今日セクション終端+1）
  let l:sec_end = l:today_end + 1
  for l:i in range(l:h + 1, l:today_end)
    let l:line = a:lines[l:i]
    if s:is_header_line_str(l:line)
      let l:sec_end = l:i
      break
    endif
  endfor

  " 次の見出し直前から、空行/空白のみ行を上に詰める
  let l:ins = l:sec_end - 1
  while l:ins > l:h
    let l:cur = a:lines[l:ins]
    if l:cur ==# '' || s:ws_only(l:cur)
      let l:ins -= 1
      continue
    endif
    break
  endwhile
  if l:ins <= l:h
    let l:ins = l:h
  endif

  let l:out = copy(a:lines)
  " 複数行を順に insert すると順序が逆になるので、後ろから入れる
  for l:j in reverse(copy(a:new_lines))
    call insert(l:out, l:j, l:ins + 1)
  endfor
  return l:out
endfunction

" Lanb/Lanq/Lann
function! s:lan_add_file(kind, text) abort
  let l:path = expand(g:lan_file)

  try
    if !filereadable(l:path)
      call writefile([], l:path)
    endif

    let l:lines = readfile(l:path)

    " 今日が無ければ作成（+ 引継）
    let [l:lines2, l:today_idx, l:created] = s:insert_today_if_missing_list(l:lines)
    let l:lines3 = l:lines2
    if l:created
      let l:lines3 = s:carry_over_if_created_list(l:lines3)
    endif

    " 追加先
    if a:kind ==# 'block'
      let l:hdr = s:HDR_BLOCK
      let l:add_lines = ['- [ ] ' . a:text]
    elseif a:kind ==# 'queue'
      let l:hdr = s:HDR_QUEUE
      let l:add_lines = ['- [ ] ' . a:text]
    else
      let l:hdr = s:HDR_NOTES
      let l:add_lines = ['- ' . a:text]
    endif

    " テンプレが壊れている場合はエラー
    let l:today_end = s:section_end_list(l:lines3, l:today_idx)
    let l:h = s:find_subheader_in_range_list(l:lines3, l:today_idx, l:today_end, l:hdr)
    if l:h < 0
      echoerr '[lan] Missing required header in TODAY: ' . l:hdr
      return
    endif

    " セクション末尾（次の見出し直前、末尾が空行/空白のみなら上へ詰める）へ追記
    let l:lines4 = s:insert_at_section_end_list(l:lines3, l:today_idx, l:hdr, l:add_lines)

    call writefile(l:lines4, l:path)

    " lan.md を既に開いているなら更新検知だけ（画面は変えない）
    let l:bn = bufnr(l:path)
    if l:bn > 0
      execute 'checktime ' . l:bn
    endif

  catch
    echoerr '[lan] Failed to add: ' . v:exception
  endtry
endfunction

" ===============================
"  Toggle done with hierarchy (note buffer)
" ===============================
function! s:is_task_line(lnum) abort
  return getline(a:lnum) =~# s:RX_TASK
endfunction

function! s:task_is_done(lnum) abort
  return getline(a:lnum) =~# '^\s*-\s\[x\]\s*'
endfunction

function! s:set_task_done(lnum, done) abort
  let l:line = getline(a:lnum)
  if a:done
    let l:new = substitute(l:line, '^\(\s*-\s\)\[\s\]\(\s*\)', '\1[x]\2', '')
  else
    let l:new = substitute(l:line, '^\(\s*-\s\)\[x\]\(\s*\)', '\1[ ]\2', '')
  endif
  call setline(a:lnum, l:new)
endfunction

function! s:is_section_break_lnum(lnum) abort
  let l:line = getline(a:lnum)
  return l:line ==# '' || l:line =~# '^###\s' || l:line =~# '^##\s' || l:line =~# s:RX_DASH
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

function! s:lan_toggle_done() abort
  let l:target = s:find_target_task_lnum_from_cursor()
  if l:target == 0
    echoerr '[lan] No task line found above cursor.'
    return
  endif

  let l:new_done = !s:task_is_done(l:target)
  call s:set_task_done(l:target, l:new_done)
  call s:apply_done_to_descendants(l:target, l:new_done)
  call s:propagate_to_ancestors(l:target)
endfunction
