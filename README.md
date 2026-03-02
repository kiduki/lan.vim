# lan.vim

タスク管理用の Vim プラグインです。日次ノートの作成、未完了タスクの引き継ぎ、クイック追記を行えます。

## 基本操作
- `:Lan` で今日のセクションを作成・オープン（前日の未完了タスクを引き継ぎ）。
- `:Lanb {text}` で **Blocking Tasks** にタスクを追加。
- `:Lanq {text}` で **Queue** にタスクを追加。
- `:Lann {text}` で **Notes** にメモを追加。

## vimrc テンプレート
```vim
augroup lan_user_setup
  autocmd!
  autocmd VimEnter * call lan#setup({
        \ 'file': expand('~/notes/lan.md'),
        \ 'meta_colors': {
        \   'label': {'ctermfg': '81', 'guifg': '#61afef'},
        \   'assignee': {'ctermfg': '114', 'guifg': '#98c379'},
        \   'priority': {'ctermfg': '220', 'guifg': '#e5c07b'},
        \   'due': {'ctermfg': '203', 'guifg': '#e06c75'},
        \ },
        \ 'note_maps': {
        \   'add_block': '<Leader>lnb',
        \   'add_queue': '<Leader>lnq',
        \   'add_note': '<Leader>lnn',
        \   'add_auto': '<Leader>lna',
        \   'toggle_done': '<Leader>lnx',
        \   'toggle_progress': '<Leader>lnp',
        \   'toggle_waiting': '<Leader>lnw',
        \   'toggle_fold': '<Leader>lnz',
        \ },
        \ })
augroup END
```

## 詳細ドキュメント
コマンド、マッピング、メタデータ仕様、レビュー判定などの詳細は `:help lan.vim` を参照してください。
