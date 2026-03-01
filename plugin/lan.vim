" plugin/lan.vim
" Long-Ass Note
"
" Thin entrypoint: user config, command registration, and autocommands.

if exists('g:loaded_lan_plugin')
  finish
endif
let g:loaded_lan_plugin = 1

" ---------------- user config ----------------
call lan#config#init_defaults()

" ---------------- commands ----------------
command! Lan  call lan#open()
command! -nargs=+ Lanb call lan#add_file('block', <q-args>)
command! -nargs=+ Lanq call lan#add_file('queue', <q-args>)
command! -nargs=+ Lann call lan#add_file('memo',  <q-args>)
command! -nargs=? -bang LanReview call lan#review(<q-args>, <bang>0)
command! LanToggleDone call lan#toggle_done()
command! LanToggleProgress call lan#toggle_progress()
command! LanToggleWaiting call lan#toggle_waiting()

" ---------------- mappings (note buffer only) ----------------
augroup lan_note_maps
  autocmd!
  autocmd BufEnter * call lan#maybe_define_note_maps()
  autocmd BufEnter * call lan#maybe_define_note_syntax()
augroup END
