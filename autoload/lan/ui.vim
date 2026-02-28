" autoload/lan/ui.vim
" Note buffer local UI setup.

function! lan#ui#maybe_define_note_maps() abort
  call s:maybe_define_note_maps()
endfunction

function! lan#ui#maybe_define_note_syntax() abort
  call s:maybe_define_note_syntax()
endfunction

function! s:maybe_define_note_maps() abort
  if expand('%:p') !=# lan#core#note_file_path()
    return
  endif

  if empty(maparg(g:lan_note_map_add_block, 'n'))
    execute 'nnoremap <silent><buffer> ' . g:lan_note_map_add_block .
          \ ' :call lan#note_buffer#insert_strict("block")<CR>'
  endif
  if empty(maparg(g:lan_note_map_add_queue, 'n'))
    execute 'nnoremap <silent><buffer> ' . g:lan_note_map_add_queue .
          \ ' :call lan#note_buffer#insert_strict("queue")<CR>'
  endif
  if empty(maparg(g:lan_note_map_add_note, 'n'))
    execute 'nnoremap <silent><buffer> ' . g:lan_note_map_add_note .
          \ ' :call lan#note_buffer#insert_strict("memo")<CR>'
  endif
  if empty(maparg(g:lan_note_map_add_auto, 'i'))
    execute 'inoremap <expr><silent><buffer> ' . g:lan_note_map_add_auto .
          \ ' lan#ui#eval_add_auto_map()'
  endif
  if empty(maparg(g:lan_note_map_toggle, 'n'))
    execute 'nnoremap <silent><buffer> ' . g:lan_note_map_toggle .
          \ ' :call lan#task_toggle#done()<CR>'
  endif
  if empty(maparg(g:lan_note_map_progress, 'n'))
    execute 'nnoremap <silent><buffer> ' . g:lan_note_map_progress .
          \ ' :call lan#task_toggle#progress()<CR>'
  endif
  if empty(maparg(g:lan_note_map_waiting, 'n'))
    execute 'nnoremap <silent><buffer> ' . g:lan_note_map_waiting .
          \ ' :call lan#task_toggle#waiting()<CR>'
  endif
  if empty(maparg(g:lan_note_map_toggle_fold, 'n'))
    execute 'nnoremap <silent><buffer> ' . g:lan_note_map_toggle_fold .
          \ ' :call lan#fold#toggle_done_fold()<CR>'
  endif
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

  highlight default lanParenEmphasis ctermfg=216 guifg=#d19a66 cterm=NONE gui=NONE
  let b:lan_paren_matchid = matchadd('lanParenEmphasis', '\%(^##\s.*\)\@<!\v\(\zs[^)]*\ze\)', 1000)
endfunction
