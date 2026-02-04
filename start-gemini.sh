#!/bin/bash

# OSを判定 (Darwin = macOS)
OS_TYPE="$(uname)"

# 1. macOSの場合のみColimaの状態を確認・起動
if [ "$OS_TYPE" == "Darwin" ]; then
    if ! colima status >/dev/null 2>&1; then
        echo "Starting Colima (macOS detected)..."
        colima start --cpu 2 --memory 4 --arch arm64
    fi
else
    echo "Skipping Colima start (Running on $OS_TYPE)..."
fi

# 2. プロジェクトのコンテナを立ち上げる
echo "Launching Docker containers..."
docker compose up -d

echo "Gemini-CLI environment is ready!"

# 3. コンテナ内に入る（ログインシェル -l を指定）
echo "Entering container..."
docker exec -it gemini-cli-dev bash -l
