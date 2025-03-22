// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is based off data the Cocoon backend sends out from v1.
// It doesn't map directly to protos since the backend does
// not use protos yet.
const String luciJsonGetStatsResponse = '''{
  "Commits": [
    {
      "Commit": {
        "Branch": "master",
        "FlutterRepositoryPath": "flutter/cocoon",
        "CreateTimestamp": 123456789,
        "Sha": "ShaShankHash",
        "Author": {
          "Login": "ShaSha", 
          "avatar_url": "https://flutter.dev"
        }
      },
      "Status": "Succeeded",
      "Tasks": [
        {
          "Attempts": 1,
          "CreateTimestamp": 1569353940885,
          "EndTimestamp": 1569354700642,
          "Flaky": false,
          "StartTimestamp": 1569354594672,
          "Status": "Succeeded",
          "BuildNumberList": "123",
          "BuilderName": "Linux"
        }
      ]
    }
  ]
}''';

const String jsonGetBranchesResponse = '''[
  {
    "reference":"flutter-3.13-candidate.0",
    "channel":"stable"
  },
  {
    "reference":"flutter-3.14-candidate.0",
    "channel":"beta"
  },
  {
    "reference":"flutter-3.15-candidate.5",
    "channel":"dev"
  },
  {
    "reference":"master",
    "channel":"master"
  }
]''';

const String jsonGetReposResponse = '''
  [
    "flutter",
    "cocoon",
    "packages"
  ]
''';

const String jsonBuildStatusTrueResponse = '{"buildStatus":"success"}';

const String jsonBuildStatusFalseResponse =
    '{"buildStatus":"failure","failingTasks":["failed_task_1"]}';

const String baseApiUrl = 'https://flutter-dashboard.appspot.com';
