# Copyright (c) 2016, the Flutter project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# The Boxstarter scirpt for setting up Windows machine in Flutter device lab.
#
# Instructions:
# 1. Install Chocolatey (see https://chocolatey.org/install).
# 2. Install Boxstarter with command `choco install -y boxstarter`.
# 3. Run `boxstarter` which opens a Boxstarter shell
# 4. Run `Install-BoxstarterPackage -PackageName setup_windows.ps1` to execute
# this script

# Show hidden files and file extensions
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowFileExtensions

# Prevent UAC from interupting Cocoon agnet
Disable-UAC

# Run Windows Update
Install-WindowsUpdate -acceptEula

# Git and Powershell integration
choco install -y git.install
choco install -y poshgit

# Dependencies of Cocoon agent
choco install -y dart-sdk --version $(cat dart_version)
choco install -y android-sdk
choco install -y sysinternals

# Useful tools
choco install -y vscode
choco install -y GoogleChrome
choco install -y tightvnc

# Final words
echo "Next you need to clone https://github.com/flutter/cocoon and run an agent"
