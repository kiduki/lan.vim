" autoload/lan/fold.vim
" Fold done tasks in today section.

function! s:is_section_break_lnum(lnum) abort
  let l:line = getline(a:lnum)
  return l:line ==# '' || l:line =~# '^###\s' || l:line =~# '^##\s' || l:line =~# lan#core#rx_dash()
endfunction

function! s:clear_manual_folds() abort
  silent! normal! zE
endfunction

function! s:fold_done_tasks() abort
  let l:today_lnum = lan#note_buffer#find_line_exact(lan#core#today_header())
  if l:today_lnum == 0
    return 0
  endif
  let l:lnum = l:today_lnum + 1
  let l:last = lan#note_buffer#section_end(l:today_lnum)
  let l:folded_groups = 0
  while l:lnum <= l:last
    if getline(l:lnum) =~# '^\s*-\s\[x\]\s*'
      let l:group_start = l:lnum
      let l:group_end = l:lnum

      while l:lnum <= l:last && getline(l:lnum) =~# '^\s*-\s\[x\]\s*'
        let l:folded_groups += 1
        let l:root_indent = indent(l:lnum)
        let l:end = l:lnum
        for l:i in range(l:lnum + 1, l:last)
          if s:is_section_break_lnum(l:i)
            break
          endif
          let l:ind = indent(l:i)
          if l:ind <= l:root_indent
            break
          endif
          let l:end = l:i
        endfor

        let l:group_end = l:end
        let l:lnum = l:end + 1
      endwhile

      execute l:group_start . ',' . l:group_end . 'fold'
      continue
    endif
    let l:lnum += 1
  endwhile
  return l:folded_groups
endfunction

function! s:enable_done_folds() abort
  if !exists('b:lan_prev_foldmethod')
    let b:lan_prev_foldmethod = &l:foldmethod
  endif
  if !exists('b:lan_prev_foldenable')
    let b:lan_prev_foldenable = &l:foldenable
  endif

  setlocal foldmethod=manual
  setlocal foldenable
  call s:clear_manual_folds()
  let l:folded = s:fold_done_tasks()
  let b:lan_done_fold_enabled = 1
  echo '[lan] Folded ' . l:folded . ' completed task(s).'
endfunction

function! s:disable_done_folds() abort
  call s:clear_manual_folds()
  if exists('b:lan_prev_foldmethod')
    let &l:foldmethod = b:lan_prev_foldmethod
  endif
  if exists('b:lan_prev_foldenable')
    let &l:foldenable = b:lan_prev_foldenable
  endif
  let b:lan_done_fold_enabled = 0
  echo '[lan] Done-task folding disabled.'
endfunction

function! lan#fold#toggle_done_fold() abort
  if get(b:, 'lan_done_fold_enabled', 0)
    call s:disable_done_folds()
  else
    call s:enable_done_folds()
  endif
endfunction
