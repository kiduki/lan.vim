" autoload/lan/core.vim
" Shared constants and helpers.

let s:RX_DATE = '^## \d\{4}-\d\{2}-\d\{2} ([^)]\+)$'
let s:RX_DASH = '^-\{3,}$'
let s:RX_TASK = '^\s*-\s\[\( \|x\)\]\s*'
let s:RX_PROGRESS = '^\s*-\s\[\s\]\s*🚩\s*'
let s:RX_WAITING = '^\s*-\s\[\s\]\s*⌛\s*'

let s:HDR_BLOCK = '### 🔥 Blocking Tasks'
let s:HDR_QUEUE = '### 📥 Queue'
let s:HDR_NOTES = '### 🧠 Notes'

let s:undo_join_next = 0

function! lan#core#rx_date() abort
  return s:RX_DATE
endfunction

function! lan#core#rx_dash() abort
  return s:RX_DASH
endfunction

function! lan#core#rx_task() abort
  return s:RX_TASK
endfunction

function! lan#core#rx_progress() abort
  return s:RX_PROGRESS
endfunction

function! lan#core#rx_waiting() abort
  return s:RX_WAITING
endfunction

function! lan#core#hdr_block() abort
  return s:HDR_BLOCK
endfunction

function! lan#core#hdr_queue() abort
  return s:HDR_QUEUE
endfunction

function! lan#core#hdr_notes() abort
  return s:HDR_NOTES
endfunction

function! lan#core#die(msg) abort
  echoerr '[lan] ' . a:msg
  throw 'lan_error'
endfunction

function! lan#core#today_header() abort
  return '## ' . strftime('%Y-%m-%d') . ' (' . strftime('%a') . ')'
endfunction

function! lan#core#note_file_path() abort
  return fnamemodify(expand(g:lan_file), ':p')
endfunction

function! lan#core#today_template_lines() abort
  return [
        \ lan#core#today_header(),
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

function! lan#core#is_header_line_str(line) abort
  return a:line =~# '^###\s' || a:line =~# '^##\s' || a:line =~# s:RX_DASH
endfunction

function! lan#core#ws_only(line) abort
  return a:line =~# '^\s\+$'
endfunction

function! lan#core#is_note_buffer() abort
  return expand('%:p') ==# lan#core#note_file_path()
endfunction

function! lan#core#require_note_buffer() abort
  if !lan#core#is_note_buffer()
    echoerr '[lan] Open note buffer first with :Lan.'
    return 0
  endif
  return 1
endfunction

function! lan#core#undo_block_begin() abort
  let s:undo_join_next = 0
endfunction

function! lan#core#undo_block_end() abort
  let s:undo_join_next = 0
endfunction

function! lan#core#setline_with_undo(lnum, text) abort
  if getline(a:lnum) ==# a:text
    return 0
  endif
  if s:undo_join_next
    silent! undojoin
  endif
  call setline(a:lnum, a:text)
  let s:undo_join_next = 1
  return 1
endfunction

function! lan#core#startinsert_for_new_item(lnum) abort
  call cursor(a:lnum, strlen(getline(a:lnum)) + 1)
  startinsert!
endfunction

function! lan#core#help() abort
  let l:lines = [
        \ '[lan] Commands',
        \ '  :Lan                       Open/create today note',
        \ '  :Lanb {text} / :Lanq {text} / :Lann {text}',
        \ '  :LanToggleDone             Toggle done on target task',
        \ '  :LanToggleProgress         Toggle progress flag 🚩',
        \ '  :LanToggleWaiting          Toggle waiting flag ⌛',
        \ '  :LanHelp                   Show this help',
        \ '[lan] Note mappings',
        \ '  add-block=' . g:lan_note_map_add_block,
        \ '  add-queue=' . g:lan_note_map_add_queue,
        \ '  add-note=' . g:lan_note_map_add_note,
        \ '  add-auto=' . g:lan_note_map_add_auto,
        \ '  toggle-done=' . g:lan_note_map_toggle,
        \ '  toggle-progress=' . g:lan_note_map_progress,
        \ '  toggle-waiting=' . g:lan_note_map_waiting,
        \ '  toggle-fold=' . g:lan_note_map_toggle_fold
        \ ]
  for l:line in l:lines
    echom l:line
  endfor
  echo '[lan] Help printed to :messages.'
endfunction
