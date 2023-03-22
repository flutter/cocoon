// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/configuration/repository_configuration_pointer.dart';
import 'package:test/test.dart';

void main() {
  test('Parse config path yaml', () {
    const String filePointerConfig = '''
      config_path: 'autosubmit/flutter/autosubmit_main.yml'
    ''';

    final RepositoryConfigurationPointer repoPointer = RepositoryConfigurationPointer.fromYaml(filePointerConfig);
    expect(repoPointer.filePath, 'autosubmit/flutter/autosubmit_main.yml');
  });

  test('Parse config path yaml key not found', () {
    const String filePointerConfig = '''
      path: 'autosubmit/flutter/autosubmit_main.yml'
    ''';

    expect(() => RepositoryConfigurationPointer.fromYaml(filePointerConfig), throwsException);
  });
}