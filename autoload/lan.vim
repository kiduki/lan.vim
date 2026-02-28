" autoload/lan.vim
" Long-Ass Note
"
" Public facade. Implementation lives in autoload/lan/*.vim modules.

function! lan#open() abort
  call lan#note_buffer#open()
endfunction

function! lan#setup(opts) abort
  if type(a:opts) != type({})
    echoerr '[lan] setup() expects a Dictionary.'
    return
  endif

  if has_key(a:opts, 'file')
    let g:lan_file = a:opts.file
  endif

  if has_key(a:opts, 'note_maps')
    call s:apply_note_maps(a:opts.note_maps)
  endif
endfunction

function! s:apply_note_maps(note_maps) abort
  if type(a:note_maps) != type({})
    echoerr '[lan] note_maps must be a Dictionary.'
    return
  endif

  let l:keymap = {
        \ 'add_block': 'g:lan_note_map_add_block',
        \ 'add_queue': 'g:lan_note_map_add_queue',
        \ 'add_note': 'g:lan_note_map_add_note',
        \ 'add_auto': 'g:lan_note_map_add_auto',
        \ 'toggle': 'g:lan_note_map_toggle',
        \ 'progress': 'g:lan_note_map_progress',
        \ 'waiting': 'g:lan_note_map_waiting',
        \ 'toggle_fold': 'g:lan_note_map_toggle_fold'
        \ }

  for l:key in keys(l:keymap)
    if has_key(a:note_maps, l:key)
      execute 'let ' . l:keymap[l:key] . ' = a:note_maps[l:key]'
    endif
  endfor
endfunction

function! lan#add_file(kind, text) abort
  call lan#file_ops#add(a:kind, a:text)
endfunction

function! lan#help() abort
  call lan#core#help()
endfunction

function! lan#toggle_done() abort
  call lan#task_toggle#done()
endfunction

function! lan#toggle_progress() abort
  call lan#task_toggle#progress()
endfunction

function! lan#toggle_waiting() abort
  call lan#task_toggle#waiting()
endfunction

function! lan#maybe_define_note_maps() abort
  call lan#ui#maybe_define_note_maps()
endfunction

function! lan#maybe_define_note_syntax() abort
  call lan#ui#maybe_define_note_syntax()
endfunction
