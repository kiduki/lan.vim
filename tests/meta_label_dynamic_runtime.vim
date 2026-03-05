set nocompatible

let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')
execute 'set runtimepath^=' . fnameescape(s:root)
execute 'runtime plugin/lan.vim'

function! s:fail(msg) abort
  echoerr a:msg
  cquit 1
endfunction

let s:tmp = tempname() . '.md'
call writefile([
      \ '## ' . strftime('%Y-%m-%d') . ' (' . strftime('%a') . ')',
      \ '',
      \ '### 🔥 Blocking Tasks',
      \ '',
      \ '- [ ] sample_task @aaa @bbb',
      \ '',
      \ '### 📥 Queue',
      \ '',
      \ '### 🧠 Notes',
      \ '',
      \ '---',
      \ ''
      \ ], s:tmp)

call lan#setup({'file': s:tmp})
execute 'edit ' . fnameescape(s:tmp)

if get(b:, 'lan_label_dynamic_enabled', 0) != 1
  call s:fail('meta label dynamic runtime: dynamic label color is not enabled')
endif

let s:groups = get(b:, 'lan_label_dynamic_groups', {})
if !has_key(s:groups, 'aaa') || !has_key(s:groups, 'bbb')
  call s:fail('meta label dynamic runtime: expected dynamic groups for aaa/bbb')
endif
if s:groups['aaa'] ==# s:groups['bbb']
  call s:fail('meta label dynamic runtime: aaa and bbb should have different dynamic groups')
endif

call setline(5, getline(5) . ' @ccc')
doautocmd <nomodeline> TextChanged <buffer>
let s:groups2 = get(b:, 'lan_label_dynamic_groups', {})
if !has_key(s:groups2, 'ccc')
  call s:fail('meta label dynamic runtime: ccc was not picked by dynamic refresh')
endif

if empty(get(b:, 'lan_label_dynamic_matchids', []))
  call s:fail('meta label dynamic runtime: dynamic match ids are missing')
endif

call delete(s:tmp)
cquit 0
