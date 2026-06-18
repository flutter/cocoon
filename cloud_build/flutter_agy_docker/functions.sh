# Copyright 2022 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# These are convenience functions to aid with podman
# Add these to ~/.zshrc or ~/.bashrc, then `source ~/.zshrc`

# Start a new container with the current working directory and your ~/.gemini
# folders mapped into it.
coder-up() {
  # Defaults to the current directory name if no argument is provided
  local env_name=${1:-$(basename "$PWD")}

  echo "Starting development environment: $env_name..."
  # 1. Spin up the environment cleanly in the background
  ENV_NAME="$env_name" podman-compose -p "$env_name" -f ~/.config/coder-env/docker-compose.yml up -d
}


# Enter the container
coder-attach() {
  local env_name=${1:-$(basename "$PWD")}
  echo "Attaching to $env_name} workspace..."
  echo "Waiting for tmux to initialize..."
  while ! podman exec "$env_name" tmux ls >/dev/null 2>&1; do
    sleep 1
  done
  podman exec -it "$env_name" tmux attach
}

# Tear down the running container
coder-down() {
  local env_name=${1:-$(basename "$PWD")}

  echo "Stopping development environment: $env_name..."
  ENV_NAME="$env_name" podman-compose -p "$env_name" -f ~/.config/coder-env/docker-compose.yml down
}
