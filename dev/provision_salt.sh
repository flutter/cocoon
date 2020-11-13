#!/bin/bash
# Copyright 2020 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script provisions a salt minion on a Flutter test bed, it supports Linux and macOS.
set -e

MINION_PLIST_PATH=/Library/LaunchDaemons/com.saltstack.salt.minion.plist

# Installs salt minion.
# Pins the version to 2019.2.0 and Python 2 to be compatible with Fuchsia salt master.
function install_salt() {
  if [[ "$(uname)" == 'Linux' ]]; then
    wget -O - https://repo.saltstack.com/py3/debian/10/amd64/3002/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
    echo 'deb http://repo.saltstack.com/py3/debian/10/amd64/3002 buster main' | sudo tee /etc/apt/sources.list.d/saltstack.list
    sudo apt update
    sudo apt install salt-minion
  elif [[ "$(uname)" == 'Darwin' ]]; then
    curl https://repo.saltstack.com/osx/salt-3002.1-py3-x86_64.pkg -o /tmp/salt.pkg
    sudo installer -pkg /tmp/salt.pkg -target /
  fi
}

function config_minion() {
  sudo mkdir -p /etc/salt
  echo "master: $1" | sudo tee /etc/salt/minion
  # Uses hostname as the minion id.
  echo "id: $(hostname -s)" | sudo tee -a /etc/salt/minion

  if [[ "$(uname)" == 'Darwin' ]]; then
    sudo cp salt.minion.plist "$MINION_PLIST_PATH"
  fi
}

function reboot_salt() {
  if [[ "$(uname)" == 'Linux' ]]; then
    sudo systemctl restart salt-minion
  elif [[ "$(uname)" == 'Darwin' ]]; then
    sudo launchctl unload "$MINION_PLIST_PATH"
    sudo launchctl load -w "$MINION_PLIST_PATH"
  fi
}

function verify_provision() {
  if sudo salt-minion --version; then
    echo 'Succeed!'
  else
    echo 'Failed!'
  fi
}

function main() {
  local master_hostname=''
  case "$1" in
    prod) master_hostname='salt.endpoints.fuchsia-infra.cloud.goog' ;;
    dev) master_hostname='salt.endpoints.fuchsia-infra-dev.cloud.goog' ;;
    *)
      echo 'Usage: ./provision_salt.sh (prod|dev)'
      exit 1
      ;;
  esac

  install_salt
  config_minion "$master_hostname"
  reboot_salt
  verify_provision
}

main "$@"
