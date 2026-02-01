# Gemini CLI - Multi-Agent Docker Environment

## 概要

このプロジェクトは、**Gemini CLI** と **tmux** を活用した、Docker ベースのマルチエージェント並列開発基盤です。
Apple Silicon (M1/M2/M3 Mac) or Windows wsl2 (Ubuntu)向けに開発しており、隔離された安全な環境で複数の AI エージェントを効率的に並行管理することを目的としています。

### 🛡️ 注意事項

⚠️ 本プロジェクトには Gemini を使用して生成されたコードが含まれています。使用は自己責任でお願いします。

---

## 🏛️ クレジットとライセンス

本プロジェクトのマルチエージェントシステムの設計思想および実装は、以下の素晴らしいプロジェクトを参考に、Gemini CLI 環境へ適応・改変させたものです。

- **ベースプロジェクト:** [yohey-w/multi-agent-shogun](https://github.com/yohey-w/multi-agent-shogun)
- **Gemini CLI 適応の参考:** [alvis1113/multi-agent-shogun-geminiCLI](https://github.com/alvis1113/multi-agent-shogun-geminiCLI)
  - 特に Gemini CLI における Rate Limit 対策や、tmux `send-keys` の挙動改善において多大な知見をいただいています。

**ライセンス:** MIT License

---

## 📋 前提条件 (Host Mac)

コンテナを動かすために、以下のツールをインストールしてください。

- **Docker CLI / Docker Compose**: コンテナ操作

Mac では以下を利用する前提です。

- **Homebrew**: パッケージ管理
- **Colima**: 軽量コンテナ実行環境（Docker Desktop の代替）

```bash
# Macの場合
brew install docker docker-compose colima
```

Windows wsl2 環境では docker がインストールされている前提になります。

---

## 🚀 セットアップ手順

### 1. リポジトリのクローンとソースの配置

```bash
git clone https://github.com/akihiro21/gemini-cli-docker-mac-wsl.git gemini-docker
cd gemini-docker/project/gemini-cli-src

# Gemini CLI 本体をクローン（ソースディレクトリ内）
git clone https://github.com/google/gemini-cli.git
```

### 2. 環境の起動

ルートディレクトリにあるスクリプトを実行すると、Colima の起動からコンテナ立ち上げまで自動で行われます。

```bash
cd ../../
chmod +x start-gemini.sh
./start-gemini.sh
```

### 3. コンテナ内での初期設定

```bash
# コンテナへ入る（自動で入らない場合）
docker-compose exec gemini-env bash

# 依存パッケージのインストールとビルド
cd /app/gemini-cli-src
npm install
npm run build
```

---

## 🛠 使い方

### マルチエージェントシステムの起動

コンテナ内のプロジェクトディレクトリにて、以下のスクリプトを実行することでシステムが起動します。

```bash
chmod +x multi-agent-start.sh
./multi-agent-start.sh
```

### tmux のトラブルシューティング（物理的解決策）

マルチエージェント動作中に tmux が停止したり、バグが発生したりする場合の対処法です。

- **プロセスの強制停止**: コマンドが応答しない場合は `Ctrl+C` を押してください。
- **セッションの削除**: tmux が正常に動作しない場合は、以下のコマンドでセッションを強制終了してください。
  ```bash
  # 実行例（セッション名を指定して削除）
  tmux kill-session -t <セッション名>
  ```
- **一括終了**: 全ての tmux セッションを終了させる場合は以下を実行してください。
  ```bash
  tmux kill-server
  ```

---

## ❓ 困ったときは

- **コマンドが見つからない**: コンテナ内で `source ~/.bashrc` を実行してください。
- **動作が重い・ハングする**: Mac 側で `docker-compose restart gemini-env` を実行し、コンテナを再起動してください。
