# Copyright 2022 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This is a highly opinionated docker container aimed at getting a developer
# up and running with antigravity in a sandbox, instantly.

# Build:
#   x86: docker build -t flutter_docker .
#   Apple Silicon: podman build --platform linux/amd64 -t flutter_docker .
#   Different version of fluttr: podman build --platform linux/amd64 --build-arg FLUTTER_VERSION=3.45.0 -t flutter_docker:3.45.0 .
#
# Run:
#   Apple Silicon: podman run --platform linux/amd64 -it -v "${PWD}:/app" -v "dart_tool_cache:/app/.dart_tool"  -v "dart_build_cache:/app/build" -v "$USER/.gemini:/home/coder/.gemini" flutter_docker:latest
#   x86: docker run -it -v ".:/app" -v 'dart_tool_cache:/app/.dart_tool'  -v "dart_build_cache:/app/build"  -v "$USER/.gemini:/home/coder/.gemini" flutter_docker:latest
#
# Doing something work worktrees - work in progress?
# 1. Make sure you have relative paths setup.
#   git config --global worktree.useRelativePaths true
#   git worktree repair
# 2. Run one of the commands above, but from the worktree folder.
#
# Versions:
#   * latest: 3.44.2
#   * previous: permissions on ~/.gemini to fix tool calling
#   * previous: better handling of .dart_tool - see run commands above! flutter 3.44.1. allow my user to sudo
#   * previous: fix tmux key bindings. add less and rsync
#   * previous: `agyolo`!, -homebrew, +vim dart plugin, native yq/gh/jq, less RUN steps
#   * previous: zsh, omyzsh, homebrew.
#   * previous: multi-stage build for flutter tooling. byobu/tmux, git, jq.

# ==========================================
# STAGE 1: The Heavy Downloader - flutter and its tools are heavy
# ==========================================
FROM ubuntu:24.04 AS flutter-fetcher

# 1. Define the ARG with a fallback default version
ARG FLUTTER_VERSION="3.44.2"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl ca-certificates xz-utils git unzip && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m builder && \
    mkdir -p /opt && \
    chown builder:builder /opt
USER builder
WORKDIR /opt

# This layer caches permanently until you change the URL.
# It is completely immune to changes in your main image.
RUN curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz | tar -xJ

# 2. Lock in configuration and force the massive SDK downloads
ENV PATH="/opt/flutter/bin:${PATH}"
RUN flutter config \
        --enable-web \
        --no-enable-linux-desktop \
        --no-enable-macos-desktop \
        --no-enable-windows-desktop \
        --no-enable-android \
        --no-enable-ios \
        --no-enable-fuchsia && \
    # Precache pulls down the engine binaries, Dart SDK, and web tools
    flutter precache --web && \
    flutter --version

# ==========================================
# STAGE 2: The OS - which should mostly have an OCI layer already.
# ==========================================
FROM ubuntu:24.04

# 1. Environment Variables (Rarely change, define early)
ENV TZ="America/Los_Angeles" \
    DEBIAN_FRONTEND=noninteractive \
    FLUTTER_ROOT="/opt/flutter" \
    PATH="/opt/flutter/bin:/home/coder/.local/bin:${PATH}" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8" \
    TERM="xterm-256color" \
    COLORTERM="truecolor" \
    SHELL="/usr/bin/zsh"

# 2. OS Dependencies (Heavy layer, cache as much as possible)
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates curl dnsutils dos2unix openssh-client unzip \
        tmux byobu vim sudo xz-utils tzdata locales jq ripgrep \
        fd-find fzf bat btop zsh build-essential procps file wget \
        less rsync software-properties-common lrzsz; \
    # Install trzsz via PPA
    add-apt-repository ppa:trzsz/ppa -y; \
    add-apt-repository ppa:git-core/ppa -y; \
    apt-get update; \
    apt-get install -y trzsz git; \
    # install github
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg; \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null; \
    apt-get update && apt-get install -y gh; \
    # binary yq
    wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64; \
    chmod a+x /usr/local/bin/yq; \
    locale-gen en_US.UTF-8; \
    ln -s $(which fdfind) /usr/local/bin/fd; \
    ln -s $(which batcat) /usr/local/bin/bat; \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone; \
    rm -rf /var/lib/apt/lists/*; \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 3. User setup and directory creation
# Evict the default ubuntu user to free up UID/GID 1000
# Using -m automatically creates the home directory securely.
RUN (userdel -r ubuntu 2>/dev/null || true) && \
    groupadd -g 1000 coder && \
    useradd -u 1000 -g 1000 -m coder && \
    mkdir -p /app /opt/flutter /home/linuxbrew/.linuxbrew && \
    chown -R coder:coder /app /opt /home/linuxbrew

# 4. Import the FULLY HYDRATED Flutter SDK from Stage 1
# This takes about 1 second and skips all network traffic.
COPY --from=flutter-fetcher --chown=coder:coder /opt/flutter /opt/flutter

# Switch context to the non-root user for the remaining installations
USER coder

# or --disable-analytics if running as CICD
RUN flutter --enable-analytics && dart --enable-analytics

# 5. Install Oh My Zsh unattended so it doesn't halt the Docker build
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Set these after USER
ENV PATH="/home/coder/.pub-cache/bin:${PATH}"

# 6. User-specific CLI tools
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash

# 7. User Configuration (Highly volatile, keep at the very bottom)
RUN mkdir -p /home/coder/.config/byobu && \
    touch /home/coder/.config/byobu/.welcome-displayed && \
    { \
      echo "unbind-key -n C-a"; \
      echo "set -g prefix C-a"; \
      echo "set -g prefix2 F12"; \
      echo "bind a send-prefix"; \
      echo "# Ensure tmux handles control modifiers correctly for xterm"; \
      echo "set-window-option -g xterm-keys on"; \
      echo "# Clear any existing bindings for these keys";\
      echo "unbind-key -n C-Left";\
      echo "unbind-key -n C-Right";\
      echo "# Map Ctrl + Left/Right to switch bottom tabs (windows)";\
      echo "bind-key -n C-Left select-window -t :-";\
      echo "bind-key -n C-Right select-window -t :+";\
      echo "set -g mouse on"; \
    } > /home/coder/.config/byobu/keybindings.tmux && \
    { \
      echo "set -g default-terminal \"tmux-256color\""; \
      echo "set -ag terminal-overrides \",xterm-256color:RGB\""; \
      echo "set -g default-shell /usr/bin/zsh"; \
      echo "# Automatically fix named volume permissions on startup"; \
      echo 'run-shell "sudo mkdir -p /app/.dart_tool && sudo chown -R coder:coder /app/.dart_tool"'; \
      echo 'run-shell "sudo mkdir -p /app/build && sudo chown -R coder:coder /app/build"'; \
      echo 'run-shell "sudo mkdir -p /home/coder/.gemini && sudo chown -R coder:coder /home/coder/.gemini"'; \
    } > /home/coder/.config/byobu/profile.tmux && \
    touch /home/coder/.zsh_history && \
    { \
      echo ": 1000000000:0;dart pub global activate melos; melos pub-get"; \
      echo ": 1000000000:0;flutter pub get"; \
      echo ": 1000000000:0;flutter analyze ."; \
      echo ": 1000000000:0;dart pub get"; \
      echo ": 1000000000:0;dart format ."; \
      echo ": 1000000000:0;dart analyze ."; \
    } >> /home/coder/.zsh_history && \
    touch /home/coder/.zshrc && \
    { \
      echo 'alias agyolo="agy --dangerously-skip-permissions"'; \
    } >> /home/coder/.zshrc

RUN mkdir -p /home/coder/.vim/pack/dart-lang/start && \
    git clone https://github.com/dart-lang/dart-vim-plugin /home/coder/.vim/pack/dart-lang/start/dart-vim-plugin

RUN git config --global --add safe.directory /app && \
    git config --global core.editor vim && \
    git config --global pull.rebase true && \
    git config --global worktree.useRelativePaths true

WORKDIR /app
ENTRYPOINT [ "/usr/bin/byobu" ]
