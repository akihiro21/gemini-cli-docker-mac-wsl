FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

# 1. 必要なツールのインストール
RUN apt-get update && apt-get install -y \
    curl git unzip sudo \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean

# 2. ユーザー設定
ARG USERNAME=developer
RUN useradd -m -s /bin/bash $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER $USERNAME

# 3. 設定の永続化用リンク作成
# ローカルの project/.gemini-config をコンテナ内の設定パスに繋ぎます
RUN mkdir -p /home/$USERNAME/.config && \
    ln -s /project/.gemini-config /home/$USERNAME/.gemini-cli

# 4. エイリアスの設定（ログイン時に自動読み込み）
RUN echo "alias gemini='node /app/gemini-cli-src/bundle/gemini.js'" >> /home/$USERNAME/.bashrc && \
    echo "alias gemini='node /app/gemini-cli-src/bundle/gemini.js'" >> /home/$USERNAME/.profile

# 5. 初期ディレクトリを workspace に設定
WORKDIR /project/workspace

CMD ["tail", "-f", "/dev/null"]
