" autoload/lan/config.vim
" Script-local runtime config store.

let s:config = {
      \ 'file': expand('~/long-ass-note.md'),
      \ 'note_maps': {
      \   'add_block': '<Leader>lanb',
      \   'add_queue': '<Leader>lanq',
      \   'add_note': '<Leader>lann',
      \   'add_auto': '<Leader>lana',
      \   'toggle': '<Leader>lanx',
      \   'progress': '<Leader>lanp',
      \   'waiting': '<Leader>lanw',
      \   'toggle_fold': '<Leader>lanz'
      \ }
      \ }

function! lan#config#init_defaults() abort
  let s:config = {
        \ 'file': expand('~/long-ass-note.md'),
        \ 'note_maps': {
        \   'add_block': '<Leader>lanb',
        \   'add_queue': '<Leader>lanq',
        \   'add_note': '<Leader>lann',
        \   'add_auto': '<Leader>lana',
        \   'toggle': '<Leader>lanx',
        \   'progress': '<Leader>lanp',
        \   'waiting': '<Leader>lanw',
        \   'toggle_fold': '<Leader>lanz'
        \ }
        \ }
endfunction

function! lan#config#setup(opts) abort
  if type(a:opts) != type({})
    echoerr '[lan] setup() expects a Dictionary.'
    return
  endif

  if has_key(a:opts, 'file')
    let s:config.file = a:opts.file
  endif

  if has_key(a:opts, 'note_maps')
    if type(a:opts.note_maps) != type({})
      echoerr '[lan] note_maps must be a Dictionary.'
      return
    endif
    for l:key in keys(s:config.note_maps)
      if has_key(a:opts.note_maps, l:key)
        let s:config.note_maps[l:key] = a:opts.note_maps[l:key]
      endif
    endfor
  endif
endfunction

function! lan#config#file() abort
  return s:config.file
endfunction

function! lan#config#map(key) abort
  if !has_key(s:config.note_maps, a:key)
    return ''
  endif
  return s:config.note_maps[a:key]
endfunction
