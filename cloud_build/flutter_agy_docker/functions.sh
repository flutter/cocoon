#!/usr/bin/env bash
# Copyright 2026 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# These are convenience functions to aid with podman
# Add these to ~/.zshrc or ~/.bashrc, then `source ~/.zshrc`

# Helper function to sanitize the environment name
_coder_env_name() {
  local name=${1:-$(basename "$PWD")}
  # Replace spaces with underscores and remove any characters not allowed in container names
  local sanitized=$(printf "%s" "$name" | tr '[:space:]' '_' | tr -cd 'a-zA-Z0-9_.-')
  echo "${sanitized:-coder-env}"
}

# Start a new container with the current working directory and your ~/.gemini
# folders mapped into it.
coder-up() {
  local env_name=$(_coder_env_name "$1")
  local compose_file="$HOME/.config/coder-env/docker-compose.yml"

  if [ ! -f "$compose_file" ]; then
    echo "Error: Compose file not found at $compose_file"
    echo "Please copy docker-compose.yml to ~/.config/coder-env/ first."
    return 1
  fi


  (
    export ENV_NAME="$env_name"
    # pulling the file shows progress to the user
    echo "Pulling image for: $env_name..."
    podman compose -p "$env_name" -f "$compose_file" pull || exit 1

    # 1. Spin up the environment cleanly in the background
    echo "Starting development environment: $env_name..."
    podman compose -p "$env_name" -f "$compose_file" up -d
  )
}

# Enter the container
coder-attach() {
  local env_name=$(_coder_env_name "$1")

  # Check if the container is running before attempting to attach
  if [ "$(podman inspect --format '{{.State.Running}}' "$env_name" 2>/dev/null)" != "true" ]; then
    echo "Error: Container '$env_name' is not running."
    echo "Have you run 'coder-up' yet?"
    return 1
  fi

  echo "Attaching to ${env_name} workspace..."
  echo "Waiting for tmux to initialize..."

  # Add a timeout to prevent an infinite loop if tmux fails to start
  local timeout=15
  while ! podman exec "$env_name" tmux ls >/dev/null 2>&1; do
    sleep 1
    timeout=$((timeout - 1))
    if [ "$timeout" -le 0 ]; then
      echo "Error: Timed out waiting for tmux to initialize in '$env_name'."
      return 1
    fi
  done

  podman exec -it "$env_name" tmux attach
}

# Tear down the running container
coder-down() {
  local env_name=$(_coder_env_name "$1")
  local compose_file="$HOME/.config/coder-env/docker-compose.yml"

  if [ ! -f "$compose_file" ]; then
    echo "Error: Compose file not found at $compose_file"
    return 1
  fi

  echo "Stopping development environment: $env_name..."
  ENV_NAME="$env_name" podman compose -p "$env_name" -f "$compose_file" down
}
