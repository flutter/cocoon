// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

const String jsonGetBranchesResponse = '''
  {
    "Branches": [
      "master",
      "flutter-0.0-candidate.1"
    ]
  }
''';

const String jsonBuildStatusTrueResponse = '{"1":1}';

const String jsonBuildStatusFalseResponse = '{"1":2,"2":["failed_task_1"]}';

const String baseApiUrl = 'https://flutter-dashboard.appspot.com';
