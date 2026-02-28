" plugin/lan.vim
" Long-Ass Note
"
" Thin entrypoint: user config, command registration, and autocommands.

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
if !exists('g:lan_note_map_progress')
  let g:lan_note_map_progress = '<Leader>lanp'
endif
if !exists('g:lan_note_map_waiting')
  let g:lan_note_map_waiting = '<Leader>lanw'
endif
if !exists('g:lan_note_map_toggle_fold')
  let g:lan_note_map_toggle_fold = '<Leader>lanz'
endif

" ---------------- commands ----------------
command! Lan  call lan#open()
command! -nargs=+ Lanb call lan#add_file('block', <q-args>)
command! -nargs=+ Lanq call lan#add_file('queue', <q-args>)
command! -nargs=+ Lann call lan#add_file('memo',  <q-args>)
command! LanHelp call lan#help()
command! LanToggleDone call lan#toggle_done()
command! LanToggleProgress call lan#toggle_progress()
command! LanToggleWaiting call lan#toggle_waiting()

" ---------------- mappings (note buffer only) ----------------
augroup lan_note_maps
  autocmd!
  autocmd BufEnter * call lan#maybe_define_note_maps()
  autocmd BufEnter * call lan#maybe_define_note_syntax()
augroup END
