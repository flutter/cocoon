// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is based off data the Cocoon backend sends out from v1.
// It doesn't map directly to protos since the backend does
// not use protos yet.
const String luciJsonGetStatsResponse = '''
      {
        "Statuses": [
          {
          "Checklist": {
            "Key": "iamatestkey",
            "Checklist": {
              "Branch": "master",
              "FlutterRepositoryPath": "flutter/cocoon",
              "CreateTimestamp": 123456789,
              "Commit": {
                "Sha": "ShaShankHash",
                "Author": {
                  "Login": "ShaSha",
                  "avatar_url": "https://flutter.dev"
                  }
                }
              }
            },
            "Stages": [
              {
                "Name": "chromebot",
                "Status": "Succeeded",
                "Tasks": [
                  {
                    "Key": "taskKey1",
                    "Task": {
                      "Attempts": 1,
                      "CreateTimestamp": 1569353940885,
                      "EndTimestamp": 1569354700642,
                      "Flaky": false,
                      "Name": "linux",
                      "Reason": "",
                      "RequiredCapabilities": ["linux"],
                      "ReservedForAgentID": "",
                      "StageName": "chromebot",
                      "StartTimestamp": 1569354594672,
                      "Status": "Succeeded",
                      "TimeoutInMinutes": 0,
                      "BuildNumberList": "123",
                      "BuilderName": "Linux",
                      "LuciBucket": "luci.flutter.try"
                    }
                  }
                ]
              }
            ]
          }
        ]
  }
''';

const String jsonGetBranchesResponse = '''{
   "Branches":[
      {
         "id":"ahFmbHV0dGVyLWRhc2hib2FyZHIuCxIGQnJhbmNoIiJmbHV0dGVyL2ZsdXR0ZXIvYnJhbmNoLWNyZWF0ZWQtb2xkDKIBCVtkZWZhdWx0XQ",
         "branch":{
            "branch":"branch-framework-release",
            "repository":"flutter/flutter"
         }
      },
     {
        "id":"ahFmbHV0dGVyLWRhc2hib2FyZHIuCxIGQnJhbmNoIiJmbHV0dGVyL2ZsdXR0ZXIvYnJhbmNoLWNyZWF0ZWQtbm93DKIBCVtkZWZhdWx0XQ",
        "branch":{
           "branch":"branch-engine-release",
           "repository":"flutter/engine"
        }
     }
   ]
}''';

const String jsonGetReposResponse = '''
  [
    "flutter",
    "cocoon",
    "engine"
  ]
''';

const String jsonBuildStatusTrueResponse = '{"1":1}';

const String jsonBuildStatusFalseResponse = '{"1":2,"2":["failed_task_1"]}';

const String baseApiUrl = 'https://flutter-dashboard.appspot.com';
