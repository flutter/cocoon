# Copyright 2022 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Start from the custom flutter_base image.
ARG FLUTTER_VERSION="3.44.2"
FROM us-docker.pkg.dev/flutter-infra/flutter-infra/flutter_base:${FLUTTER_VERSION}

USER root

# 1. The Cache Buster: Changing this value forces Docker to fetch fresh OS updates
ARG CACHE_BUSTER=1

# 2. OS Dependencies & Upgrades
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates curl dnsutils dos2unix openssh-client unzip \
        tmux byobu vim sudo xz-utils tzdata locales jq ripgrep \
        fd-find fzf bat btop zsh build-essential procps file wget \
        less rsync software-properties-common lrzsz; \
    # trzsz: Modern SSH File Transfer and Remote Terminal Tools
    add-apt-repository ppa:trzsz/ppa -y; \
    # latest git version needed for relative worktrees
    add-apt-repository ppa:git-core/ppa -y; \
    apt-get update; \
    apt-get install -y trzsz git; \
    # install the github `gh` tool
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg; \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null; \
    apt-get update && apt-get install -y gh; \
    # install yq, a YAML/XML/TOML processor like jq
    wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64; \
    chmod a+x /usr/local/bin/yq; \
    locale-gen en_US.UTF-8; \
    ln -s $(which fdfind) /usr/local/bin/fd; \
    # cat, but better
    ln -s $(which batcat) /usr/local/bin/bat; \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone; \
    rm -rf /var/lib/apt/lists/*; \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER coder

# 3. Development Tools
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
ENV PATH="/home/coder/.pub-cache/bin:${PATH}"
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash

# 4. User Configurations
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
