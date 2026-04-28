#!/bin/bash
# Copyright 2026 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

if [ -n "$PR_NUMBER" ]; then
  echo "Creating worktree for PR $PR_NUMBER..."
  cd "$FLUTTER_ROOT"
  
  # Ensure safe directory
  git config --global --add safe.directory "$FLUTTER_ROOT"

  # Cleanup
  git worktree remove -f pr_review 2>/dev/null || true
  git worktree prune || true
  
  # Add worktree in detached state to avoid creating a branch
  git worktree add pr_review
  
  cd pr_review
  
  echo "Checking out PR $PR_NUMBER in worktree..."
  git fetch origin pull/$PR_NUMBER/head:pr-$PR_NUMBER
  git checkout pr-$PR_NUMBER
  
  echo "Running testanalyzer..."
  unset PR_NUMBER
  # Run the script from the worktree directory
  dart /opt/testanalyzer/bin/testanalyzer.dart
  
  if [ -f "failure_log.txt" ]; then
    echo "Analyzing log with Gemini..."
    
    echo "Constructing prompt..."
    echo "Analyze the following log failures based on the provided skill." > prompt.txt
    echo "" >> prompt.txt
    echo "### Skill Definition" >> prompt.txt
    cat /opt/testanalyzer/TEST_PROMPT.md >> prompt.txt
    echo "" >> prompt.txt
    echo "## Log Content" >> prompt.txt
    cat failure_log.txt >> prompt.txt
    
    gemini --skip-trust --yolo -p "Please read the following instructions and execute them: @prompt.txt"
  else
    echo "Failure log not found. Analysis skipped."
  fi
fi
