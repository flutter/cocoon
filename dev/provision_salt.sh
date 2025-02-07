#!/usr/bin/env bash
# Copyright 2020 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script provisions a salt minion on a Flutter test bed, it supports Linux and macOS.
set -e

MINION_PLIST_PATH=/Library/LaunchDaemons/com.saltstack.salt.minion.plist
LINUX_SALT_CLIENT_PATH="$HOME/salt-client"
# NOTE: https://github.com/flutter/flutter/issues/142627#issuecomment-1919922724
# before increasing this
SALT_VERSION='3006.3'

# Installs salt minion.
# Pins the version to 2019.2.0 and Python 2 to be compatible with Fuchsia salt master.
function install_salt() {
  OS="$(uname)"
  if [[ "$OS" == 'Darwin' ]]; then
    curl -L "https://packages.broadcom.com/artifactory/saltproject-generic/macos/$SALT_VERSION/salt-$SALT_VERSION-py3-x86_64.pkg" -o /tmp/salt.pkg
    sudo installer -pkg /tmp/salt.pkg -target /
  elif [[ "$OS" == 'Linux' ]]; then
    DISTRO="$(lsb_release -is)"
    if [[ "$DISTRO" == 'Ubuntu' ]]; then
      # Uninstall previous SaltStack packages, if any.
      sudo dpkg --remove salt-minion salt-api salt-common
      
      # Install SaltStack's dependencies.
      sudo apt install -y dctrl-tools
      
      # Install SaltStack.
      declare -a SALT_PACKAGES=(
        "salt-common_3006.9_amd64.deb"
        "salt-minion_3006.9_amd64.deb"
      )
      for PACKAGE in "${SALT_PACKAGES[@]}"
      do
        echo "Installing salt package $PACKAGE..."
      
        curl -L -o "/tmp/$PACKAGE" "https://packages.broadcom.com/artifactory/saltproject-deb/pool/$PACKAGE"
        sudo dpkg --install "/tmp/$PACKAGE"
      done

      # Install m2crypto in SaltStack's python environment (for the x509 module).
      sudo /opt/saltstack/salt/bin/pip install m2crypto==0.39
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
    sudo PATH="/opt/salt/bin:/usr/local/sbin:$PATH" /opt/salt/bin/salt-call grains.set 'device_os' "$1"
  fi
}

function reboot_salt() {
  if [[ "$(uname)" == 'Linux' ]]; then
    # TODO hmm....
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
