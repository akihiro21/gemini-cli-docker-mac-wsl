#!/bin/bash

# 1. Colimaが動いていなければ起動
if ! colima status >/dev/null 2>&1; then
    echo "Starting Colima..."
    colima start --cpu 2 --memory 4 --arch arm64
fi

# 2. プロジェクトのコンテナを立ち上げる
echo "Launching Docker containers..."
docker-compose up -d

echo "Gemini-CLI environment is ready!"

# 3. コンテナ内に入る（ログインシェル -l を指定）
echo "Entering container..."
docker exec -it gemini-cli-dev bash -l
