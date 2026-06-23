#!/usr/bin/env bash
# Copyright 2026 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

# Fail immediately if asking for authorization
GIT_TERMINAL_PROMPT=0

# Configuration
# Allow appending custom repositories via AGY_SKILL_REPOS env var
# Example: export AGY_SKILL_REPOS="myorg/skills another/skills"
USER_REPOS=(${AGY_SKILL_REPOS:-})
REPOS=(
  "flutter/skills"
  "dart-lang/skills"
  "kevmoo/dash_skills"
  "${USER_REPOS[@]}"
)

# Parse arguments
TARGET_DIR="$HOME/.gemini/config/skills"
if [[ "$1" == "--local" ]]; then
  TARGET_DIR=".agents/skills"
fi

mkdir -p "$TARGET_DIR/.versions"
TMP_DIR=$(mktemp -d)

# Cleanup trap
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Updating skills in $TARGET_DIR..."
echo "----------------------------------------"

UPDATED_REPOS=0
CHECKED_REPOS=0
UPDATED_SKILLS=0

for REPO in "${REPOS[@]}"; do
  CHECKED_REPOS=$((CHECKED_REPOS + 1))
  
  # Fetch latest SHA using git ls-remote (very fast, no full clone needed)
  LATEST_SHA=$(git ls-remote "https://github.com/$REPO" HEAD | awk '{print $1}')
  
  if [ -z "$LATEST_SHA" ]; then
    echo "[-] Failed to fetch latest SHA for $REPO"
    continue
  fi

  # Check existing version
  REPO_SAFE_NAME=$(echo "$REPO" | tr '/' '_')
  VERSION_FILE="$TARGET_DIR/.versions/$REPO_SAFE_NAME.sha"
  CURRENT_SHA=""
  if [ -f "$VERSION_FILE" ]; then
    CURRENT_SHA=$(cat "$VERSION_FILE")
  fi

  if [ "$LATEST_SHA" == "$CURRENT_SHA" ]; then
    echo "[=] $REPO is up to date."
    continue
  fi

  echo "[+] Checking $REPO..."

  # Download via git clone --depth=1
  REPO_TMP="$TMP_DIR/$REPO"
  git clone --depth=1 --quiet "https://github.com/$REPO" "$REPO_TMP"

  # Now check if there is a skills folder in the repo
  if [ -d "$REPO_TMP/skills" ]; then
    REPO_UPDATED=0
    
    # Use git ls-tree to get hashes of all folders in skills/
    # Output format: 040000 tree <hash>    skills/<name>
    while read -r _ _ SKILL_HASH SKILL_PATH; do
      SKILL_NAME=$(basename "$SKILL_PATH")
      SKILL_TMP="$REPO_TMP/$SKILL_PATH"
      
      # Make sure it's actually a directory
      [ -d "$SKILL_TMP" ] || continue
      
      SKILL_VERSION_FILE="$TARGET_DIR/.versions/${REPO_SAFE_NAME}_${SKILL_NAME}.sha"
      
      CURRENT_SKILL_HASH=""
      if [ -f "$SKILL_VERSION_FILE" ]; then
        CURRENT_SKILL_HASH=$(cat "$SKILL_VERSION_FILE")
      fi
      
      if [ "$SKILL_HASH" != "$CURRENT_SKILL_HASH" ]; then
        # Action required
        rm -rf "$TARGET_DIR/$SKILL_NAME"
        cp -R "$SKILL_TMP" "$TARGET_DIR/"
        echo "$SKILL_HASH" > "$SKILL_VERSION_FILE"
        
        if [ -z "$CURRENT_SKILL_HASH" ]; then
          echo "    - @[$TARGET_DIR/$SKILL_NAME] was added"
        else
          echo "    - @[$TARGET_DIR/$SKILL_NAME] was updated"
        fi
        
        UPDATED_SKILLS=$((UPDATED_SKILLS + 1))
        REPO_UPDATED=1
      fi
    done < <(cd "$REPO_TMP" && git ls-tree HEAD skills/)
    
    # Save the repo SHA so we don't redownload next time unless it changes
    echo "$LATEST_SHA" > "$VERSION_FILE"
    if [ "$REPO_UPDATED" -eq 1 ]; then
      UPDATED_REPOS=$((UPDATED_REPOS + 1))
    fi
  else
    echo "[-] No 'skills' directory found in $REPO"
  fi
done

echo "----------------------------------------"
echo "Summary:"
echo "Checked $CHECKED_REPOS repositories."
if [ "$UPDATED_SKILLS" -eq 0 ]; then
  echo "All skills are up to date."
else
  echo "Updated/Added $UPDATED_SKILLS skills across $UPDATED_REPOS repositories."
fi
echo "Skills available in: $TARGET_DIR"
