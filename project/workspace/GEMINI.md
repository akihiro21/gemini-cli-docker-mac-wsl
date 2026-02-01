# multi-agent-manager-gemini システム構成 i

> **Version**: 1.0.0
> **Last Updated**: 2026-01-27

## 概要

multi-agent-manager-gemini は、Gemini CLI + tmux を使ったマルチエージェント並列開発基盤です。階層構造により、複数のプロジェクトを並行管理できます。

## セッション開始時の必須手順（全エージェント共通）

新たなセッションを開始した際（初回起動時）は、作業前に必ず以下を実行してください。
※ これはコンパクション復帰とは異なります。セッション開始 = Gemini CLI を新規に立ち上げた時の手順です。

1. **save_memory を確認してください**: まずメモリツールである`save_memory` を確認し、save_memory に保存されたルール・コンテキスト・禁止事項を確認してください。エージェントの行動を律するルールが保存されています。これを読まずに作業を開始することは避けてください。
2. **自分の役割に対応する指示書を読んでください**:
   - Manager → instructions/manager.md
   - Leader → instructions/leader.md
   - Worker → instructions/worker.md
3. **指示書に従い、必要なコンテキストファイルを読み込んでから作業を開始してください**

save_memory には、コンパクションを超えて永続化すべきルール・判断基準・ユーザーの好みが保存されています。
セッション開始時にこれを読むことで、過去の学びを引き継いだ状態で作業に臨むことができます。

> **セッション開始とコンパクション復帰の違い**:
>
> - **セッション開始**: Gemini CLI の新規起動。白紙の状態から save_memory でコンテキストを復元する
> - **コンパクション復帰**: 同一セッション内でコンテキストが圧縮された後の復帰。summary が残っているが、正確なデータから再確認が必要

## コンパクション復帰時（全エージェント共通）

コンパクション後は作業前に必ず以下を実行してください：

1. **自分の位置を確認してください**: `tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}'`
   - `manager:0.0` → Manager
   - `multiagent:0.0` → Leader
   - `multiagent:0.1` ～ `multiagent:0.3` → Worker1 ～ 3
2. **対応する指示書を読んでください**:
   - Manager → instructions/manager.md
   - Leader → instructions/leader.md
   - Worker → instructions/worker.md
3. **指示書内の「コンパクション復帰手順」に従い、正確なデータから状況を再把握してください**
4. **禁止事項を確認してから作業を開始してください**

summary の「次のステップ」を見てすぐに作業を開始しないでください。まず自分の役割を確認してください。

> **重要**: dashboard.md は二次情報（Leader が整形した要約）であり、正確なデータではありません。
> 正確なデータは各 YAML ファイル（queue/manager_to_leader.yaml, queue/tasks/, queue/reports/）です。
> コンパクション復帰時は必ず正確なデータを参照してください。

## 階層構造

```
ユーザー（人間 / The User）
  │
  ▼ 指示
┌──────────────┐
│   MANAGER    │ ← Manager（プロジェクト統括）
│   (Manager)  │
└──────┬───────┘
       │ YAMLファイル経由
       ▼
┌──────────────┐
│    LEADER    │ ← Leader（タスク管理・分配）
│   (Leader)   │
└──────┬───────┘
       │ YAMLファイル経由
       ▼
 ┌───┬───┬───┐
 │W1 │W2 │W3 │ ← Worker（実働部隊）
 └───┴───┴───┘
```

## 通信プロトコル

### イベント駆動通信（YAML + send-keys）

- ポーリング禁止（API 代金節約のため）
- 指示・報告内容は YAML ファイルに書く
- 通知は tmux send-keys で相手を起こす（必ず C-m を使用、Enter 禁止）。これは Gemini CLI と tmux 間のコマンド伝達の信頼性を向上させるためです。
- **send-keys は必ず 2 回の Bash 呼び出しに分けてください**（1 回で書くと C-m が正しく解釈されない）：
  ```bash
  # 【1回目】メッセージを送る
  tmux send-keys -t multiagent:0.0 'メッセージ内容'
  # 【2回目】C-mを送る
  tmux send-keys -t multiagent:0.0 C-m
  ```

### 報告の流れ（割り込み防止設計）

- **下 → 上への報告**: dashboard.md 更新のみ（send-keys 禁止）
- **上 → 下への指示**: YAML + send-keys で起こす
- 理由: ユーザー（人間）の入力中に割り込みが発生するのを防ぐ

### ファイル構成

```
config/projects.yaml                 # プロジェクト一覧
status/master_status.yaml            # 全体進捗
queue/manager_to_leader.yaml         # Manager → Leader 指示
queue/tasks/worker{N}.yaml           # Leader → Worker 割当（各Worker専用）
queue/reports/worker{N}_report.yaml  # Worker → Leader 報告
dashboard.md                         # 人間用ダッシュボード
```

**注意**: 各 Worker には専用のタスクファイル（queue/tasks/worker1.yaml 等）があります。
これにより、Worker が他の Worker のタスクを誤って実行することを防ぎます。

### プロジェクト管理

このマルチエージェントシステムは、自身の改善だけでなく、**全てのホワイトカラー業務**を管理・実行します。
プロジェクトの管理フォルダは外部にあってもよい（multi-agent-manager-gemini リポジトリ配下でなくても OK）。

```
config/projects.yaml       # どのプロジェクトがあるか（一覧・サマリー）
projects/<id>.yaml          # 各プロジェクトの詳細（クライアント情報、タスク、Notion連携等）
```

- `config/projects.yaml`: プロジェクト ID・名前・パス・ステータスの一覧のみ
- `projects/<id>.yaml`: そのプロジェクトの全詳細（クライアント、契約、タスク、関連ファイル等）
- プロジェクトの実ファイル（ソースコード、設計書等）は `path` で指定した外部フォルダに置く
- `projects/` フォルダは Git 追跡対象外（機密情報を含むため）

## tmux セッション構成

### manager セッション（1 ペイン）

- Pane 0: MANAGER（Manager）

### multiagent セッション（4 ペイン）

- Pane 0: LEADER（Leader）
- Pane 1-3: WORKER1-3（Worker）

## 言語設定

config/settings.yaml の `language` で言語を設定する。

```yaml
language: ja # ja, en, es, zh, ko, fr, de 等
```

## 指示書

- instructions/manager.md - Manager の指示書
- instructions/leader.md - Leader の指示書
- instructions/worker.md - Worker の指示書

## Summary 生成時の必須事項

コンパクション用の summary を生成する際は、以下を必ず含めてください：

1. **エージェントの役割**: Manager/Leader/Worker のいずれか
2. **主要な禁止事項**: そのエージェントの禁止事項リスト
3. **現在のタスク ID**: 作業中の cmd_xxx

これにより、コンパクション後も役割と制約を即座に把握できます。

## 利用可能なツール

本システムでは以下のツールが利用可能です。

- `read_file`: ファイルの内容を読み込みます。
- `write_file`: ファイルに内容を書き込みます。
- `search_file_content`: ファイルの内容を検索します。
- `glob`: ファイルパスのパターンマッチングを行います。
- `replace`: ファイル内のテキストを置換します。
- `run_shell_command`: シェルコマンドを実行します。
- `web_fetch`: URL からコンテンツを取得します。
- `save_memory`: 長期記憶に情報を保存します。
- `google_web_search`: Google 検索を実行します。
- `ask_user`: ユーザーに質問します。
- `write_todos`: TODO リストを作成・管理します。
- `codebase_investigator`: コードベースの分析を行います。
- `cli_help`: Gemini CLI の機能に関する情報を取得します。
- `activate_skill`: 特定のスキルをアクティベートします。

## Manager の必須行動（コンパクション後も継続して実施してください！）

以下は**絶対に守るべきルール**です。コンテキストがコンパクションされても必ず実行してください。

> **ルール永続化**: 重要なルールは Memory MCP にも保存されています。
> コンパクション後に不明な点があれば `mcp__memory__read_graph` で確認してください。

### 1. ダッシュボード更新

- **dashboard.md の更新は Leader の責任です**
- Manager は Leader に指示を出し、Leader が更新します
- Manager は dashboard.md を読んで状況を把握してください

### 2. 指揮系統の遵守

- Manager → Leader → Worker の順で指示
- Manager が直接 Worker に指示してはいけません
- Leader を経由してください

### 3. 報告ファイルの確認

- Worker の報告は queue/reports/worker{N}\_report.yaml
- Leader からの報告待ちの際はこれを確認してください

### 4. Leader の状態確認

- 指示を出す前に Leader が処理中か確認してください: `tmux capture-pane -t multiagent:0.0 -p | tail -20`
- "thinking", "Effecting…" 等が表示中なら待機

### 5. スクリーンショットの場所

- ユーザーのスクリーンショット: config/settings.yaml の `screenshot.path` を参照
- 最新のスクリーンショットを見るよう指示されたらここを確認してください

### 6. スキル化候補の確認

- Worker の報告には `skill_candidate:` が必須です
- Leader は Worker からの報告でスキル化候補を確認し、dashboard.md に記載
- Manager はスキル化候補を承認し、スキル設計書を作成してください

### 7. 🚨 ユーザー確認ルール【最重要】

```
██████████████████████████████████████████████████████████████
█  ユーザーへの確認事項は全て「要対応」に集約してください！  █
██████████████████████████████████████████████████████████████
```

- ユーザーの判断が必要なものは **全て** dashboard.md の「🚨 要対応」セクションに記載してください。
- 詳細セクションに記載しても、**必ず要対応にもサマリーを記載してください。**
- 対象: スキル化候補、著作権問題、技術選択、ブロック事項、質問事項
- **これを忘れるとユーザーとの連携に問題が生じます。必ず実施してください。**
