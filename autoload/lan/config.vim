" autoload/lan/config.vim
" Script-local runtime config store.

let s:config = {
      \ 'file': expand('~/notes/lan.md'),
      \ 'meta_colors': {
      \   'label': {'ctermfg': '81',  'guifg': '#61afef'},
      \   'assignee': {'ctermfg': '114', 'guifg': '#98c379'},
      \   'priority': {'ctermfg': '220', 'guifg': '#e5c07b'},
      \   'due': {'ctermfg': '203', 'guifg': '#e06c75'}
      \ },
      \ 'note_maps': {
      \   'add_block': '<Leader>lanb',
      \   'add_queue': '<Leader>lanq',
      \   'add_note': '<Leader>lann',
      \   'add_auto': '<Leader>lana',
      \   'toggle_done': '<Leader>lanx',
      \   'toggle_progress': '<Leader>lanp',
      \   'toggle_waiting': '<Leader>lanw',
      \   'toggle_fold': '<Leader>lanz'
      \ }
      \ }

function! lan#config#init_defaults() abort
  let s:config = {
        \ 'file': expand('~/notes/lan.md'),
        \ 'meta_colors': {
        \   'label': {'ctermfg': '81',  'guifg': '#61afef'},
        \   'assignee': {'ctermfg': '114', 'guifg': '#98c379'},
        \   'priority': {'ctermfg': '220', 'guifg': '#e5c07b'},
        \   'due': {'ctermfg': '203', 'guifg': '#e06c75'}
        \ },
        \ 'note_maps': {
        \   'add_block': '<Leader>lanb',
        \   'add_queue': '<Leader>lanq',
        \   'add_note': '<Leader>lann',
        \   'add_auto': '<Leader>lana',
        \   'toggle_done': '<Leader>lanx',
        \   'toggle_progress': '<Leader>lanp',
        \   'toggle_waiting': '<Leader>lanw',
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
    for [l:key, l:lhs] in items(a:opts.note_maps)
      if has_key(s:config.note_maps, l:key)
        let s:config.note_maps[l:key] = l:lhs
      endif
    endfor
  endif

  if has_key(a:opts, 'meta_colors')
    if type(a:opts.meta_colors) != type({})
      echoerr '[lan] meta_colors must be a Dictionary.'
      return
    endif
    for [l:key, l:spec] in items(a:opts.meta_colors)
      if !has_key(s:config.meta_colors, l:key)
        continue
      endif
      if type(l:spec) != type({})
        echoerr '[lan] meta_colors.' . l:key . ' must be a Dictionary.'
        return
      endif
      if has_key(l:spec, 'ctermfg')
        let s:config.meta_colors[l:key].ctermfg = string(l:spec.ctermfg)
      endif
      if has_key(l:spec, 'guifg')
        let s:config.meta_colors[l:key].guifg = string(l:spec.guifg)
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

function! lan#config#meta_color(key) abort
  if !has_key(s:config.meta_colors, a:key)
    return {'ctermfg': 'NONE', 'guifg': 'NONE'}
  endif
  return copy(s:config.meta_colors[a:key])
endfunction
