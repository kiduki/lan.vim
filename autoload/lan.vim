" autoload/lan.vim
" Long-Ass Note
"
" Public facade. Implementation lives in autoload/lan/*.vim modules.

function! lan#open() abort
  call lan#note_buffer#open()
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
