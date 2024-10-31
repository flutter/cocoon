#!/usr/bin/env bash
# Copyright 2020 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script provisions a salt minion on a Flutter test bed, it supports Linux and macOS.
set -e

MINION_PLIST_PATH=/Library/LaunchDaemons/com.saltstack.salt.minion.plist

# Installs salt minion.
# Pins the version to 2019.2.0 and Python 2 to be compatible with Fuchsia salt master.
function install_salt() {
  OS="$(uname)"
  if [[ "$OS" == 'Darwin' ]]; then
    curl https://packages.broadcom.com/artifactory/saltproject-generic/macos/3006.9/salt-3006.9-py3-x86_64.pkg -o /tmp/salt.pkg
    sudo installer -pkg /tmp/salt.pkg -target /
  elif [[ "$OS" == 'Linux' ]]; then
    DISTRO="$(lsb_release -is)"
    if [[ "$DISTRO" == 'Ubuntu' ]]; then
      sudo curl -fsSL -o /usr/share/keyrings/salt-archive-keyring.gpg https://repo.saltproject.io/py3/ubuntu/20.04/amd64/latest/salt-archive-keyring.gpg
      echo 'deb [signed-by=/usr/share/keyrings/salt-archive-keyring.gpg arch=amd64] https://repo.saltproject.io/py3/ubuntu/20.04/amd64/3005/ focal main' | sudo tee /etc/apt/sources.list.d/salt.list
      sudo apt update
      sudo apt install salt-minion
    else
      echo "Unsupported Linux distribution: $DISTRO" >&2
      exit 1
    fi
  else
    echo "Unsupported operating system $OS" >&2
    exit 1
  fi
}

function config_minion() {
  sudo mkdir -p /etc/salt
  echo "master: $1" | sudo tee /etc/salt/minion
  # Uses hostname as the minion id.
  echo "id: $(hostname -s)" | sudo tee -a /etc/salt/minion

  # Set fqdn for salt key autoaccept
  echo "autosign_grains:" | sudo tee -a /etc/salt/minion
  echo "  - fqdn" | sudo tee -a /etc/salt/minion

  if [[ "$(uname)" == 'Darwin' ]]; then
    sudo cp salt.minion.plist "$MINION_PLIST_PATH"
  fi
}

function set_deviceos_grains() {
  if [ -n "$1" ]; then
    sudo /opt/salt/bin/salt-call grains.set 'device_os' "$1"
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
  if sudo PATH="$PATH:/opt/salt/bin:/usr/bin" salt-minion --version; then
    echo 'Succeed!'
  else
    echo 'Failed!'
  fi
}

function Usage() {
  echo "
Usage: ./provision_salt.sh [SERVER] [DEVICE_OS]

  Arguments:
    SERVER: required. Either 'prod' or 'dev'.
    DEVICE_OS: optional. Either 'ios' or 'android'.
  "
}

function main() {
  local master_hostname=''
  # TODO(yusuf-goog): Update the hostname below when we get a dev flutter salt master.
  case "$1" in
    prod) master_hostname='salt-flutter.endpoints.fuchsia-infra.cloud.goog' ;;
    dev) master_hostname='salt-flutter.endpoints.fuchsia-infra.cloud.goog' ;;
    *)
      Usage
      exit 1
      ;;
  esac

  local device_os=''
  case "$2" in
    ios) device_os='ios' ;;
    android) device_os='android' ;;
    "") device_os='' ;;
    *)
      Usage
      exit 1
      ;;
  esac

  install_salt
  config_minion "$master_hostname"
  reboot_salt
  verify_provision
  set_deviceos_grains "$device_os"
}

main "$@"
