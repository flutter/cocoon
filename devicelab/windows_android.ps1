# Copyright (c) 2019, the Flutter project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# This script provisions a machine for Windows/Android testing in Flutter
# devicelab.
#
# Instructions:
# 1. Install Chocolatey (see https://chocolatey.org/install).
# 2. Install Boxstarter with command `choco install -y boxstarter`.
# 3. Run `boxstarter` which opens a Boxstarter shell.
# 4. In the shell, run `Install-BoxstarterPackage -PackageName windows_android.ps1`.

# Shows hidden files and file extensions
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowFileExtensions

# Prevents UAC from interrupting a Cocoon agent
Disable-UAC

# Gets Windows update
Install-WindowsUpdate -acceptEula

# Installs Git and the Powershell integration
choco install -y git.install
choco install -y poshgit

# Installs the dependencies of a Cocoon agent
choco install -y dart-sdk
choco install -y android-sdk
choco install -y sysinternals

# Installs a VNC server and a SSH server for remote management
choco install -y tigervnc
choco install -y openssh

# Installs convenient tools
choco install -y vscode
choco install -y vim
choco install -y GoogleChrome

# Clones the Cocoon repository
cd C:\Users\flutter\
git clone https://github.com/flutter/cocoon.git
