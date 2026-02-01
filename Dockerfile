FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

# 日本語ロケールのインストール
RUN apt-get update && apt-get install -y locales && \
    locale-gen ja_JP.UTF-8
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja
ENV LC_ALL ja_JP.UTF-8

# 1. 必要なツールのインストール (tmuxを追加)
RUN apt-get update && apt-get install -y \
    curl git unzip sudo tmux vim \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean

# 2. ユーザー設定
ARG USERNAME=developer
RUN useradd -m -s /bin/bash $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER $USERNAME

# 3. 設定の永続化用リンク作成
RUN mkdir -p /home/$USERNAME/.config && \
    ln -s /project/.gemini-config /home/$USERNAME/.gemini-cli

# 4. エイリアス設定
RUN echo "alias gemini='node /app/gemini-cli-src/bundle/gemini.js'" >> /home/$USERNAME/.bashrc && \
    echo "alias gemini='node /app/gemini-cli-src/bundle/gemini.js'" >> /home/$USERNAME/.profile

# tmuxでマウスを有効にし、UTF-8を強制する設定
RUN echo "set -g mouse on" >> /home/$USERNAME/.tmux.conf

# 5. 初期ディレクトリ
WORKDIR /project/workspace

CMD ["tail", "-f", "/dev/null"]
