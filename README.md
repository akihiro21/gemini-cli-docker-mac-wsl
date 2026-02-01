# Gemini CLI - Multi-Agent Docker Environment

## 概要
このプロジェクトは、**Gemini CLI** と **tmux** を活用した、Dockerベースのマルチエージェント並列開発基盤です。
Apple Silicon (M1/M2/M3 Mac) に最適化されており、隔離された安全な環境で複数のAIエージェントを効率的に並行管理することを目的としています。

### 🛡️ 注意事項
⚠️ 本プロジェクトにはGeminiを使用して生成されたコードが含まれています。使用は自己責任でお願いします。

---

## 🏛️ クレジットとライセンス

本プロジェクトのマルチエージェントシステムの設計思想および実装は、以下の素晴らしいプロジェクトを参考に、Gemini CLI環境へ適応・改変させたものです。

* **ベースプロジェクト:** [multi-agent-shogun](https://github.com/...) (MIT License)
* **Gemini CLI適応の参考:** [alvis1113/multi-agent-shogun-geminiCLI](https://github.com/alvis1113/multi-agent-shogun-geminiCLI)
    * 特にGemini CLIにおけるRate Limit対策や、tmux `send-keys` の挙動改善において多大な知見をいただいています。

**ライセンス:** MIT License

---

## 📋 前提条件 (Host Mac)

コンテナを動かすために、以下のツールをインストールしてください。

- **Homebrew**: パッケージ管理
- **Colima**: 軽量コンテナ実行環境（Docker Desktopの代替）
- **Docker CLI / Docker Compose**: コンテナ操作

```bash
brew install docker docker-compose colima
```

---

## 🚀 セットアップ手順

### 1. リポジトリのクローンとソースの配置
```bash
git clone [https://github.com/akihiro21/gemini-cli-docker-mac-wsl.git](https://github.com/akihiro21/gemini-cli-docker-mac-wsl.git) gemini-docker
cd gemini-docker/project/gemini-cli-src

# Gemini CLI 本体をクローン（ソースディレクトリ内）
git clone [https://github.com/google/gemini-cli.git](https://github.com/google/gemini-cli.git) .
```

### 2. 環境の起動
ルートディレクトリにあるスクリプトを実行すると、Colimaの起動からコンテナ立ち上げまで自動で行われます。
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
./multi-agent-start.sh
```

### tmuxのトラブルシューティング（物理的解決策）
マルチエージェント動作中にtmuxが停止したり、バグが発生したりする場合の対処法です。

* **プロセスの強制停止**: コマンドが応答しない場合は `Ctrl+C` を押してください。
* **セッションの削除**: tmuxが正常に動作しない場合は、以下のコマンドでセッションを強制終了してください。
  ```bash
  # 実行例（セッション名を指定して削除）
  tmux kill-session -t <セッション名>
  ```
* **一括終了**: 全てのtmuxセッションを終了させる場合は以下を実行してください。
  ```bash
  tmux kill-server
  ```

---

## ❓ 困ったときは
- **コマンドが見つからない**: コンテナ内で `source ~/.bashrc` を実行してください。
- **動作が重い・ハングする**: Mac側で `docker-compose restart gemini-env` を実行し、コンテナを再起動してください。
