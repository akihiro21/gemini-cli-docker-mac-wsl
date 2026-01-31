# Gemini CLI - Docker Development Environment

## 注意事項
⚠️  Geminiを使って作成したコードが含まれます。使用は自己責任でお願いします。

M1/M2/M3 Mac (Apple Silicon) に最適化された、Dockerベースの Gemini CLI 開発・実行環境です。
個人のGoogleアカウントを使用して、安全かつクリーンな隔離環境で AI Agent を利用できます。

## 📋 前提条件

この環境を動かすために、Mac側に以下のツールをインストールしてください。

- **Homebrew**: パッケージ管理ツール
- **Colima**: Docker Desktopの代わりに使用する軽量コンテナ実行環境
- **Docker CLI / Docker Compose**: コンテナ操作用ツール

```bash
# インストールコマンド例
brew install docker docker-compose colima
```

## 🚀 セットアップ手順

### 1. リポジトリのクローン
まずはこのリポジトリをクローンし、空のソースディレクトリに Gemini CLI 本体を配置します。

```bash
git clone https://github.com/akihiro21/gemini-cli-docker-mac-wsl.git gemini-docker
cd gemini-docker/project/gemini-cli-src

# Gemini CLI 本体をこの中にクローン
git clone https://github.com/google/gemini-cli.git .
```

### 2. 環境の起動
ルートディレクトリにある起動スクリプトを実行します。Colimaの起動からDockerコンテナの立ち上げまで自動で行います。

```bash
cd ../../
chmod +x start-gemini.sh
./start-gemini.sh
```

### 3. コンテナ内での初期設定
コンテナに入ったら、Node.jsの依存パッケージをインストールします。

```bash
# コンテナ内で実行
cd /app/gemini-cli-src
npm install
# ビルド
npm run build
```

### 4. ログインと動作確認
`gemini` コマンドを実行すると、ブラウザが開いてGoogleログインを求められます。

```bash
# コンテナ内で実行
gemini --version

# 実際に質問してみる
gemini "Hello, Dockerからこんにちは！"
```

## 📁 ディレクトリ構成

- `project/workspace`: 作業用ディレクトリ。解析したいファイルやスクリプトはここに入れます。
- `project/gemini-cli-src`: Gemini CLI のソースコード。各自で `git clone` してください。
- `project/.gemini-config`: 認証情報が保存されます。**Git管理外**です。

## 🛠 便利な使いかた

### GEMINI.md による権限管理
`/project/workspace/GEMINI.md` を作成し、以下のように記述すると、Geminiが確認なしで実行できるコマンドを指定できます。

```markdown
Gemini, you can run these commands without asking:
- ls
- cat
- pwd
```

### 非対話モード
確認ダイアログなしで一発実行したい場合は `-p` フラグを使用してください。

```bash
gemini -p "現在のOSのバージョンを教えて"
```

## ❓ 困ったときは

- **コマンドが見つからない場合**: 
  コンテナ内で `source ~/.bashrc` を実行してパスを再読み込みしてください。
- **動作が重い・ハングする場合**: 
  Mac側で `docker-compose restart gemini-env` を実行してコンテナを再起動してください。
- **Google Cloudの警告が出る場合**: 
  本環境は個人アカウントのブラウザ認証を利用するため、`gcloud` 関連の警告（Quota Project等）は無視して問題ありません。
