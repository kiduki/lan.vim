# lan.vim
タスク管理用のVimプラグインです。日次ノートのテンプレ生成、未完了タスクの引き継ぎ、クイック追加を提供します。

## 機能
- `:Lan` で今日のセクションを作成・オープン（未完了タスクを前日から引き継ぎ）。  
- `:Lanb` / `:Lanq` / `:Lann` でノートを開かずに Blocking / Queue / Notes へ追記。  
- ノートバッファ内の専用マッピングでタスク追加・階層対応の完了トグル。  

## 使い方（vimrc の記載）
```vim
" lan.vim を読み込んだ後に設定してください
let g:lan_file = expand('~/long-ass-note.md')

" ノート内マッピング（必要に応じて変更）
let g:lan_note_map_add_block = '<Leader>lanb'
let g:lan_note_map_add_queue = '<Leader>lanq'
let g:lan_note_map_add_note  = '<Leader>lann'
let g:lan_note_map_add_auto  = '<Leader>lana'
let g:lan_note_map_toggle    = '<Leader>lanx'
let g:lan_note_map_toggle_fold = '<Leader>lanz'
```

### コマンド
- `:Lan`  
  今日のノートを開く。今日のセクションがなければ先頭に作成し、前日の未完了タスクを引き継ぎます。
- `:Lanb {text}`  
  ノートを開かずに、今日の **Blocking Tasks** 末尾へ `- [ ] {text}` を追記。
- `:Lanq {text}`  
  ノートを開かずに、今日の **Queue** 末尾へ `- [ ] {text}` を追記。
- `:Lann {text}`  
  ノートを開かずに、今日の **Notes** 末尾へ `- {text}` を追記。

### ノートバッファ内マッピング
ノートファイル（`g:lan_file`）を開いているときのみ有効です。
- `g:lan_note_map_add_block`（既定: `<Leader>lanb`）  
  TODAY の **Blocking Tasks** に `- [ ] ` を追加して挿入。
- `g:lan_note_map_add_queue`（既定: `<Leader>lanq`）  
  TODAY の **Queue** に `- [ ] ` を追加して挿入。
- `g:lan_note_map_add_note`（既定: `<Leader>lann`）  
  TODAY の **Notes** に `- ` を追加して挿入。
- `g:lan_note_map_add_auto`（既定: `<Leader>lana`）  
  カーソルがあるセクション（Blocking / Queue / Notes）に応じて追加して挿入。
- `g:lan_note_map_toggle`（既定: `<Leader>lanx`）  
  カーソル位置のタスクを完了/未完了に切替（階層にも反映）。
- `g:lan_note_map_toggle_fold`（既定: `<Leader>lanz`）  
  完了済みタスク（配下の深いインデントを含む）を一括で折り畳みON/OFF。

----

以下のサイトを見て、vimプラグインを作った（ChatGPTが）
https://blog.aroka.net/entry/2026/01/11/212640

ChatGPTには直接は上記のサイトを参照させず、さらに元ネタの以下サイトの要約するところから始めた
https://allenpike.com/2023/how-leaders-manage-time-attention-tasks/

ファイル名のデフォルトは変えるようにしましょう。
