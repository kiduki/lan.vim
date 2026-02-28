# lan.vim
タスク管理用のVimプラグインです。日次ノートのテンプレ生成、未完了タスクの引き継ぎ、クイック追加を提供します。

## 機能
- `:Lan` で今日のセクションを作成・オープン（未完了タスクを前日から引き継ぎ）。  
- `:Lanb` / `:Lanq` / `:Lann` でノートを開かずに Blocking / Queue / Notes へ追記。  
- `:h Lan` でヘルプを表示。
- `:LanToggleDone` / `:LanToggleProgress` / `:LanToggleWaiting` でユーザーコマンドからも状態トグル可能。  
- 完了タスク折りたたみ時に件数を表示。  
- 追加系マップ実行時はプレフィックス直後（行末）からすぐ入力できる。  
- 複数行に及ぶ状態変更は1回の `u` で戻せるよう undo 単位を調整。  

## 使い方（vimrc の記載）
```vim
" 推奨: plugin読込後に setup() を実行
augroup lan_user_setup
  autocmd!
  autocmd VimEnter * call lan#setup({
        \ 'file': expand('~/notes/lan.md'),
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

`setup()` 以外の設定方法はサポート対象外です。
`setup()` 実行時にヘルプタグを生成するため `:help Lan` を利用できます。

### コマンド
- `:Lan`  
  今日のノートを開く。今日のセクションがなければ先頭に作成し、前日の未完了タスクを引き継ぎます。
- `:Lanb {text}`  
  ノートを開かずに、今日の **Blocking Tasks** 末尾へ `- [ ] {text}` を追記。
- `:Lanq {text}`  
  ノートを開かずに、今日の **Queue** 末尾へ `- [ ] {text}` を追記。
- `:Lann {text}`  
  ノートを開かずに、今日の **Notes** 末尾へ `- {text}` を追記。
- `:h Lan`
  Vimヘルプを表示。
- `:LanToggleDone`  
  カーソル位置のタスクを完了/未完了に切替（階層にも反映）。
- `:LanToggleProgress`  
  カーソル位置のタスクの進行中フラグ `🚩` をON/OFF（完了済みは対象外）。
- `:LanToggleWaiting`  
  カーソル位置のタスクの待機中フラグ `⌛` をON/OFF（完了済みは対象外）。

### ノートバッファ内マッピング
ノートファイル（`setup()` の `file`）を開いているときのみ有効です。  
以下は `setup()` の `note_maps` キーです。
- `add_block`（既定: `<Leader>lanb`）  
  TODAY の **Blocking Tasks** に `- [ ] ` を追加して挿入。
- `add_queue`（既定: `<Leader>lanq`）  
  TODAY の **Queue** に `- [ ] ` を追加して挿入。
- `add_note`（既定: `<Leader>lann`）  
  TODAY の **Notes** に `- ` を追加して挿入。
- `add_auto`（既定: `<Leader>lana`）  
  行末（末尾文字上を含む）にいるときのみ、カーソルがあるセクション（Blocking / Queue / Notes）に応じて追加して挿入（行中の場合は通常の入力として扱う）。
- `toggle_done`（既定: `<Leader>lanx`）  
  カーソル位置のタスクを完了/未完了に切替（階層にも反映）。
- `toggle_progress`（既定: `<Leader>lanp`）  
  カーソル位置のタスクの進行中フラグ `🚩` をON/OFF（完了済みは対象外）。
- `toggle_waiting`（既定: `<Leader>lanw`）  
  カーソル位置のタスクの待機中フラグ `⌛` をON/OFF（完了済みは対象外）。
- `toggle_fold`（既定: `<Leader>lanz`）  
  完了済みタスク（配下の深いインデントを含む）を一括で折り畳みON/OFF。ON時は折りたたみ件数を表示。

----

以下のサイトを見て、vimプラグインを作った（ChatGPTが）
https://blog.aroka.net/entry/2026/01/11/212640

ChatGPTには直接は上記のサイトを参照させず、さらに元ネタの以下サイトの要約するところから始めた
https://allenpike.com/2023/how-leaders-manage-time-attention-tasks/

ファイル名のデフォルトは変えるようにしましょう。
