" autoload/lan/ui.vim
" Note buffer local UI setup.

let s:label_rx = '@\%([0-9A-Za-z_]\|[^ -~[:space:]]\)\%([0-9A-Za-z_-]\|[^ -~[:space:]]\)*'
let s:label_palette = [
      \ {'ctermfg': '81',  'guifg': '#61afef'},
      \ {'ctermfg': '114', 'guifg': '#98c379'},
      \ {'ctermfg': '220', 'guifg': '#e5c07b'},
      \ {'ctermfg': '203', 'guifg': '#e06c75'},
      \ {'ctermfg': '39',  'guifg': '#56b6c2'},
      \ {'ctermfg': '213', 'guifg': '#c678dd'},
      \ {'ctermfg': '216', 'guifg': '#d19a66'},
      \ {'ctermfg': '75',  'guifg': '#5fafff'},
      \ {'ctermfg': '149', 'guifg': '#afdf5f'},
      \ {'ctermfg': '209', 'guifg': '#ff875f'},
      \ {'ctermfg': '141', 'guifg': '#af87ff'},
      \ {'ctermfg': '45',  'guifg': '#00d7ff'}
      \ ]
let s:max_dynamic_labels = 64

function! lan#ui#maybe_define_note_maps() abort
  call s:maybe_define_note_maps()
endfunction

function! lan#ui#maybe_define_note_syntax() abort
  call s:maybe_define_note_syntax()
endfunction

function! lan#ui#ensure_meta_syntax() abort
  call s:ensure_meta_syntax()
endfunction

function! lan#ui#refresh_dynamic_label_colors() abort
  if !lan#core#is_note_buffer()
    return
  endif
  call s:refresh_dynamic_label_colors()
endfunction

function! s:warn_map_conflict_once(lhs, mode, feature) abort
  let l:feature_key = substitute(a:feature, '[^0-9A-Za-z_]', '_', 'g')
  let l:key = 'lan_warned_map_conflict_' . a:mode . '_' . l:feature_key
  if get(b:, l:key, 0)
    return
  endif
  execute 'let b:' . l:key . ' = 1'
  echohl WarningMsg
  echom '[lan] Global map conflict: "' . a:lhs . '" for ' . a:feature . ' is disabled in note buffer.'
  echohl None
endfunction

function! s:maybe_define_note_map(lhs, mode, rhs, feature) abort
  let l:map = maparg(a:lhs, a:mode, 0, 1)
  if empty(l:map)
    if a:mode ==# 'i'
      execute 'inoremap <expr><silent><buffer> ' . a:lhs . ' ' . a:rhs
    else
      execute 'nnoremap <silent><buffer> ' . a:lhs . ' ' . a:rhs
    endif
    return
  endif

  if !get(l:map, 'buffer', 0)
    call s:warn_map_conflict_once(a:lhs, a:mode, a:feature)
  endif
endfunction

function! s:maybe_define_note_maps() abort
  if expand('%:p') !=# lan#core#note_file_path()
    return
  endif

  call s:maybe_define_note_map(
        \ lan#config#map('add_block'), 'n',
        \ ':call lan#note_buffer#insert_strict("block")<CR>',
        \ 'add-block')
  call s:maybe_define_note_map(
        \ lan#config#map('add_queue'), 'n',
        \ ':call lan#note_buffer#insert_strict("queue")<CR>',
        \ 'add-queue')
  call s:maybe_define_note_map(
        \ lan#config#map('add_note'), 'n',
        \ ':call lan#note_buffer#insert_strict("memo")<CR>',
        \ 'add-note')
  call s:maybe_define_note_map(
        \ lan#config#map('add_auto'), 'i',
        \ 'lan#ui#eval_add_auto_map()',
        \ 'add-auto')
  call s:maybe_define_note_map(
        \ ':', 'i',
        \ 'lan#ui#eval_date_complete_map(":")',
        \ 'date-complete')
  call s:maybe_define_note_map(
        \ '@', 'i',
        \ 'lan#ui#eval_meta_complete_map("@")',
        \ 'meta-complete-label')
  call s:maybe_define_note_map(
        \ '+', 'i',
        \ 'lan#ui#eval_meta_complete_map("+")',
        \ 'meta-complete-assignee')
  call s:maybe_define_note_map(
        \ lan#config#map('toggle_done'), 'n',
        \ ':call lan#task_toggle#done()<CR>',
        \ 'toggle-done')
  call s:maybe_define_note_map(
        \ lan#config#map('toggle_progress'), 'n',
        \ ':call lan#task_toggle#progress()<CR>',
        \ 'toggle-progress')
  call s:maybe_define_note_map(
        \ lan#config#map('toggle_waiting'), 'n',
        \ ':call lan#task_toggle#waiting()<CR>',
        \ 'toggle-waiting')
  call s:maybe_define_note_map(
        \ lan#config#map('toggle_fold'), 'n',
        \ ':call lan#fold#toggle_done_fold()<CR>',
        \ 'toggle-fold')
  call s:maybe_define_note_map(
        \ lan#config#map('edit_insert'), 'n',
        \ ':call lan#note_buffer#edit_task_text("insert")<CR>',
        \ 'edit-insert')
  call s:maybe_define_note_map(
        \ lan#config#map('edit_append'), 'n',
        \ ':call lan#note_buffer#edit_task_text("append")<CR>',
        \ 'edit-append')
  call s:maybe_define_note_map(
        \ lan#config#map('edit_change'), 'n',
        \ ':call lan#note_buffer#edit_task_text("change")<CR>',
        \ 'edit-change')
  call s:maybe_define_note_map(
        \ '<C-a>', 'n',
        \ ':call lan#ui#eval_ctrl_ax_map(1)<CR>',
        \ 'date-inc')
  call s:maybe_define_note_map(
        \ '<C-x>', 'n',
        \ ':call lan#ui#eval_ctrl_ax_map(-1)<CR>',
        \ 'date-dec')
endfunction

function! lan#ui#eval_add_auto_map() abort
  if col('.') != col('$') || !lan#note_buffer#can_insert_auto()
    return lan#note_buffer#map_add_auto_keys()
  endif
  return "\<C-o>:call lan#note_buffer#insert_auto()\<CR>"
endfunction

function! lan#ui#eval_date_complete_map(char) abort
  return lan#note_buffer#eval_date_complete_map(a:char)
endfunction

function! lan#ui#eval_meta_complete_map(char) abort
  return lan#note_buffer#eval_meta_complete_map(a:char)
endfunction

function! lan#ui#eval_ctrl_ax_map(delta) abort
  if lan#note_buffer#increment_task_date(a:delta)
    return
  endif
  if a:delta > 0
    silent! execute "normal! \<C-a>"
  else
    silent! execute "normal! \<C-x>"
  endif
endfunction

function! s:maybe_define_note_syntax() abort
  if expand('%:p') !=# lan#core#note_file_path()
    return
  endif

  call s:ensure_meta_syntax()
endfunction

function! s:ensure_meta_syntax() abort
  if get(b:, 'lan_meta_syntax_defined', 0)
    call s:maybe_refresh_dynamic_label_colors()
    return
  endif
  let b:lan_meta_syntax_defined = 1

  let l:label = lan#config#meta_color('label')
  let l:assignee = lan#config#meta_color('assignee')
  let l:priority = lan#config#meta_color('priority')
  let l:due = lan#config#meta_color('due')
  let l:deadline = lan#config#meta_color('deadline')

  highlight default lanParenEmphasis ctermfg=216 guifg=#d19a66 cterm=NONE gui=NONE
  execute 'highlight default lanLabelMeta ctermfg=' . l:label.ctermfg . ' guifg=' . l:label.guifg . ' cterm=NONE gui=NONE'
  execute 'highlight default lanAssigneeMeta ctermfg=' . l:assignee.ctermfg . ' guifg=' . l:assignee.guifg . ' cterm=NONE gui=NONE'
  execute 'highlight default lanPriorityMeta ctermfg=' . l:priority.ctermfg . ' guifg=' . l:priority.guifg . ' cterm=NONE gui=NONE'
  execute 'highlight default lanDueMeta ctermfg=' . l:due.ctermfg . ' guifg=' . l:due.guifg . ' cterm=NONE gui=NONE'
  execute 'highlight default lanDeadlineMeta ctermfg=' . l:deadline.ctermfg . ' guifg=' . l:deadline.guifg . ' cterm=NONE gui=NONE'

  let b:lan_paren_matchid = matchadd('lanParenEmphasis', '\%(^##\s.*\)\@<!\v\(\zs[^)]*\ze\)', 1000)
  let b:lan_label_matchid = matchadd('lanLabelMeta', s:label_rx, 1001)
  let b:lan_assignee_matchid = matchadd('lanAssigneeMeta', '+\%([0-9A-Za-z_]\|[^ -~[:space:]]\)\%([0-9A-Za-z_-]\|[^ -~[:space:]]\)*', 1001)
  let b:lan_priority_matchid = matchadd('lanPriorityMeta', '\<p[1-4]\>', 1001)
  let l:dt_pat = '\d\{4}-\d\{2}-\d\{2}\%(\%(T\d\{2}:\d\{2}\)\=\)\>'
  let b:lan_due_matchid = matchadd('lanDueMeta', 'due:' . l:dt_pat, 1001)
  let b:lan_deadline_matchid = matchadd('lanDeadlineMeta', 'deadline:' . l:dt_pat, 1001)

  call s:setup_dynamic_label_color_autocmd()
  call s:maybe_refresh_dynamic_label_colors()
endfunction

function! s:setup_dynamic_label_color_autocmd() abort
  if get(b:, 'lan_dynamic_label_color_autocmd_ready', 0)
    return
  endif
  let b:lan_dynamic_label_color_autocmd_ready = 1

  let l:group = 'lan_note_dynamic_label_colors_' . bufnr('%')
  execute 'augroup ' . l:group
  autocmd!
  execute 'autocmd TextChanged,TextChangedI,BufEnter <buffer=' . bufnr('%') . '> call lan#ui#refresh_dynamic_label_colors()'
  augroup END
endfunction

function! s:label_hash(label) abort
  let l:sum = 0
  let l:i = 0
  let l:len = strlen(a:label)
  while l:i < l:len
    let l:ch = char2nr(strpart(a:label, l:i, 1))
    let l:sum = (l:sum * 131 + l:ch) % 2147483647
    let l:i += 1
  endwhile
  return l:sum
endfunction

function! s:label_palette_index(label, used) abort
  let l:size = len(s:label_palette)
  let l:start = s:label_hash(a:label) % l:size
  let l:i = 0
  while l:i < l:size
    let l:idx = (l:start + l:i) % l:size
    if !has_key(a:used, l:idx)
      return l:idx
    endif
    let l:i += 1
  endwhile
  return l:start
endfunction

function! s:define_dynamic_label_groups() abort
  if get(g:, 'lan_dynamic_label_groups_defined', 0)
    return
  endif
  let g:lan_dynamic_label_groups_defined = 1

  for l:i in range(0, len(s:label_palette) - 1)
    let l:group = 'lanLabelMetaDyn_' . l:i
    let l:spec = s:label_palette[l:i]
    execute 'highlight default ' . l:group
          \ . ' ctermfg=' . l:spec.ctermfg
          \ . ' guifg=' . l:spec.guifg
          \ . ' cterm=NONE gui=NONE'
  endfor
endfunction

function! s:clear_dynamic_label_matches() abort
  for l:id in get(b:, 'lan_label_dynamic_matchids', [])
    silent! call matchdelete(l:id)
  endfor
  let b:lan_label_dynamic_matchids = []
  let b:lan_label_dynamic_groups = {}
endfunction

function! s:collect_labels_for_dynamic_color() abort
  let l:labels = []
  let l:seen = {}
  for l:line in getline(1, '$')
    let l:start = 0
    while 1
      let l:m = matchstrpos(l:line, s:label_rx, l:start)
      let l:token = l:m[0]
      if l:token ==# ''
        break
      endif
      let l:label = strpart(l:token, 1)
      if !has_key(l:seen, l:label)
        let l:seen[l:label] = 1
        call add(l:labels, l:label)
        if len(l:labels) >= s:max_dynamic_labels
          return l:labels
        endif
      endif
      let l:start = l:m[2]
    endwhile
  endfor
  return l:labels
endfunction

function! s:apply_dynamic_label_colors() abort
  call s:clear_dynamic_label_matches()

  let l:labels = s:collect_labels_for_dynamic_color()
  let l:used = {}
  for l:label in l:labels
    let l:idx = s:label_palette_index(l:label, l:used)
    let l:used[l:idx] = 1
    let l:group = 'lanLabelMetaDyn_' . l:idx
    let l:pat = '@' . escape(l:label, '\.^$~[]*')
    let l:id = matchadd(l:group, l:pat, 1002)
    call add(b:lan_label_dynamic_matchids, l:id)
    let b:lan_label_dynamic_groups[l:label] = l:group
  endfor
endfunction

function! s:refresh_dynamic_label_colors() abort
  if lan#config#is_label_color_fixed()
    let b:lan_label_dynamic_enabled = 0
    call s:clear_dynamic_label_matches()
    return
  endif

  let l:tick = b:changedtick
  if get(b:, 'lan_label_dynamic_last_tick', -1) == l:tick
    return
  endif
  let b:lan_label_dynamic_last_tick = l:tick
  let b:lan_label_dynamic_enabled = 1

  call s:define_dynamic_label_groups()
  call s:apply_dynamic_label_colors()
endfunction

function! s:maybe_refresh_dynamic_label_colors() abort
  if lan#config#is_label_color_fixed()
    let b:lan_label_dynamic_enabled = 0
    call s:clear_dynamic_label_matches()
    return
  endif
  call s:refresh_dynamic_label_colors()
endfunction
