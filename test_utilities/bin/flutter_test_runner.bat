:: Copyright 2019 The Chromium Authors. All rights reserved.
:: Use of this source code is governed by a BSD-style license that can be
:: found in the LICENSE file.
:: This file is used by
:: https://github.com/flutter/tests/tree/master/registry/flutter_cocoon.test
:: to run the tests of certain packages in this repository as a presubmit
:: for the flutter/flutter repository.
:: Changes to this file (and any tests in this repository) are only honored
:: after the commit hash in the "flutter_cocoon.test" mentioned above has
:: been updated.
:: Remember to also update the Posix version (flutter_test_runner.sh) when
:: changing this file.

ECHO Running flutter tests from %1
PUSHD %1

flutter packages get
flutter analyze
flutter format --line-length=120 --set-exit-if-changed lib/ test/
flutter config --enable-web
flutter build web
flutter test --test-randomize-ordering-seed=random

POPD
