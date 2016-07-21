// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'framework.dart';
import 'utils.dart';

Task createBasicMaterialAppSizeTest() => new BasicMaterialAppSizeTest();

class BasicMaterialAppSizeTest extends Task {
  BasicMaterialAppSizeTest() : super('basic_material_app__size');

  @override
  Future<TaskResultData> run() async {
    const sampleAppName = 'sample_flutter_app';
    Directory sampleDir = dir('${Directory.systemTemp.path}/$sampleAppName');

    if (await sampleDir.exists())
      rrm(sampleDir);

    int apkSizeInBytes;

    await inDirectory(Directory.systemTemp, () async {
      await flutter('create', onCancel, options: [sampleAppName]);

      if (!(await sampleDir.exists()))
        throw 'Failed to create sample Flutter app in ${sampleDir.path}';

      await inDirectory(sampleDir, () async {
        await pub('get', onCancel);
        await flutter('build', onCancel, options: ['clean']);
        await flutter('build', onCancel, options: ['apk', '--release']);
        apkSizeInBytes = await file('${sampleDir.path}/build/app.apk').length();
      });
    });

    return new TaskResultData({
      'release_size_in_bytes': apkSizeInBytes
    }, benchmarkScoreKeys: [
      'release_size_in_bytes'
    ]);
  }
}
