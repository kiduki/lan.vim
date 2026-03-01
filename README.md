# lan.vim
タスク管理用のVimプラグインです。日次ノートのテンプレ生成、未完了タスクの引き継ぎ、クイック追加を提供します。

## 機能
- `:Lan` で今日のセクションを作成・オープン（未完了タスクを前日から引き継ぎ）。  
- `:Lanb` / `:Lanq` / `:Lann` でノートを開かずに Blocking / Queue / Notes へ追記。  
- タスク内メタデータ記法 `@label` / `+assignee` / `p1..p4` / `due:YYYY-MM-DD` をサポート。
- `:LanReview[!] [stale_days]` で週次レビュー（期限切れ/今週期限/滞留）を表示。
- `:help lan.vim` でヘルプを表示（`lan.vim` 指定でのみ開く）。
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

`setup()` 以外の設定方法はサポート対象外です。
`setup()` 実行時にヘルプタグを生成します。ヘルプは `:help lan.vim` を使ってください（`lan` / `Lan` はVim標準ヘルプに解決される場合があります）。

### コマンド
- `:Lan`  
  今日のノートを開く。今日のセクションがなければ先頭に作成し、前日の未完了タスクを引き継ぎます。
- `:Lanb {text}`  
  ノートを開かずに、今日の **Blocking Tasks** 末尾へ `- [ ] {text}` を追記。
- `:Lanq {text}`  
  ノートを開かずに、今日の **Queue** 末尾へ `- [ ] {text}` を追記。
- `:Lann {text}`  
  ノートを開かずに、今日の **Notes** 末尾へ `- {text}` を追記。
- `:help lan.vim`
  Vimヘルプを表示（`lan.vim` 指定でのみ開く）。
- `:LanReview[!] [stale_days]`
  週次レビューを scratch バッファに表示。`stale_days` の既定は `7`。`!` 指定時は詳細行（行番号）を表示。
  可能ならノートバッファの未保存変更も反映して集計。
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

### メタデータ記法
- 形式:
  `- [ ] タスク本文 @label +assignee p1 due:2026-03-03`
- ルール:
  - `@label` は複数指定可（重複は内部で除外）。
  - `+assignee` は複数指定可（重複は内部で除外、日本語など非ASCIIも可）。
  - `p1`〜`p4` は優先度（最後に書かれた値を採用）。
  - `due:YYYY-MM-DD` は期限日（最後に書かれた値を採用）。
  - 上記以外のトークンは本文として扱う。

### メタデータ色設定（setup）
- `meta_colors.label` / `meta_colors.assignee` / `meta_colors.priority` / `meta_colors.due`
- 各キーに `ctermfg` と `guifg` を指定可能
- 既定色:
  - `label`: `ctermfg=81`, `guifg=#61afef`
  - `assignee`: `ctermfg=114`, `guifg=#98c379`
  - `priority`: `ctermfg=220`, `guifg=#e5c07b`
  - `due`: `ctermfg=203`, `guifg=#e06c75`

### LanReview の判定
- `Overdue`: 期限日が今日より前の未完了タスク。
- `DueThisWeek`: 今日から6日後までに期限がある未完了タスク。
- `HighPriorityStale`: 同一タスク継続日数が `stale_days` 以上で、`p1/p2` かつ `🚩` なしの未完了タスク。
- `WaitingStale`: 同一タスク継続日数が `stale_days` 以上で、`⌛` の未完了タスク。

----

以下のサイトを見て、vimプラグインを作った（ChatGPTが）
https://blog.aroka.net/entry/2026/01/11/212640

ChatGPTには直接は上記のサイトを参照させず、さらに元ネタの以下サイトの要約するところから始めた
https://allenpike.com/2023/how-leaders-manage-time-attention-tasks/

ファイル名のデフォルトは変えるようにしましょう。
