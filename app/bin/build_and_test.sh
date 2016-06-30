# Copyright (c) 2016 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

if [ ! -f "pubspec.yaml" -a ! -f "app.yaml" ]; then
  echo '[ERROR]: cwd must be the root of the cocoon app containing pubspec.yaml and app.yaml'
  exit 1
fi

pub run test
pub build
cp web/*.dart build/web/
cp -RL packages build/web/

echo
echo "Build succeeded! To deploy to App Engine run the following command after replacing {VERSION}:"
echo "appcfg.py update -A flutter-dashboard -V {VERSION} ./"
