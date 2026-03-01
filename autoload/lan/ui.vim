" autoload/lan/ui.vim
" Note buffer local UI setup.

function! lan#ui#maybe_define_note_maps() abort
  call s:maybe_define_note_maps()
endfunction

function! lan#ui#maybe_define_note_syntax() abort
  call s:maybe_define_note_syntax()
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
endfunction

function! lan#ui#eval_add_auto_map() abort
  if col('.') != col('$') || !lan#note_buffer#can_insert_auto()
    return lan#note_buffer#map_add_auto_keys()
  endif
  return "\<C-o>:call lan#note_buffer#insert_auto()\<CR>"
endfunction

function! s:maybe_define_note_syntax() abort
  if expand('%:p') !=# lan#core#note_file_path()
    return
  endif

  if get(b:, 'lan_paren_syntax_defined', 0)
    return
  endif
  let b:lan_paren_syntax_defined = 1

  let l:label = lan#config#meta_color('label')
  let l:assignee = lan#config#meta_color('assignee')
  let l:priority = lan#config#meta_color('priority')
  let l:due = lan#config#meta_color('due')

  highlight default lanParenEmphasis ctermfg=216 guifg=#d19a66 cterm=NONE gui=NONE
  execute 'highlight default lanLabelMeta ctermfg=' . l:label.ctermfg . ' guifg=' . l:label.guifg . ' cterm=NONE gui=NONE'
  execute 'highlight default lanAssigneeMeta ctermfg=' . l:assignee.ctermfg . ' guifg=' . l:assignee.guifg . ' cterm=NONE gui=NONE'
  execute 'highlight default lanPriorityMeta ctermfg=' . l:priority.ctermfg . ' guifg=' . l:priority.guifg . ' cterm=NONE gui=NONE'
  execute 'highlight default lanDueMeta ctermfg=' . l:due.ctermfg . ' guifg=' . l:due.guifg . ' cterm=NONE gui=NONE'

  let b:lan_paren_matchid = matchadd('lanParenEmphasis', '\%(^##\s.*\)\@<!\v\(\zs[^)]*\ze\)', 1000)
  let b:lan_label_matchid = matchadd('lanLabelMeta', '@\%([0-9A-Za-z_]\|[^ -~[:space:]]\)\%([0-9A-Za-z_-]\|[^ -~[:space:]]\)*', 1001)
  let b:lan_assignee_matchid = matchadd('lanAssigneeMeta', '+\%([0-9A-Za-z_]\|[^ -~[:space:]]\)\%([0-9A-Za-z_-]\|[^ -~[:space:]]\)*', 1001)
  let b:lan_priority_matchid = matchadd('lanPriorityMeta', 'p[1-4]\>', 1001)
  let b:lan_due_matchid = matchadd('lanDueMeta', 'due:\d\{4}-\d\{2}-\d\{2}\>', 1001)
endfunction
