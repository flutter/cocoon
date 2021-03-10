// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is based off data the Cocoon backend sends out from v1.
// It doesn't map directly to models since the backend does
// not use models yet.
const String jsonGetStatsResponse = '''
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
                "Name": "devicelab",
                "Status": "Succeeded",
                "Tasks": [
                  {
                    "Key": "taskKey1",
                    "Task": {
                      "Attempts": 1,
                      "CreateTimestamp": 1569353940885,
                      "EndTimestamp": 1569354700642,
                      "Flaky": false,
                      "Name": "complex_layout_semantics_perf",
                      "Reason": "",
                      "RequiredCapabilities": ["linux/android"],
                      "ReservedForAgentID": "linux2",
                      "StageName": "devicelab",
                      "StartTimestamp": 1569354594672,
                      "Status": "Succeeded",
                      "TimeoutInMinutes": 0
                    }
                  }
                ]
              }
            ]
          }
        ],
        "AgentStatuses":[
          {
            "AgentID":"flutter-devicelab-linux-1",
            "HealthCheckTimestamp":1576876008093,
            "IsHealthy":true,
            "Capabilities":[
              "linux/android",
              "linux"
            ],
            "HealthDetails":"ssh-connectivity: succeeded\\n    Last known IP address: 192.168.1.29\\n\\nandroid-device-ZY223D6B7B: succeeded\\nhas-healthy-devices: succeeded\\n    Found 1 healthy devices\\n\\ncocoon-authentication: succeeded\\ncocoon-connection: succeeded\\nable-to-perform-health-check: succeeded\\n"
          },
          {
            "AgentID":"flutter-devicelab-mac-1",
            "HealthCheckTimestamp":1576530583142,
            "IsHealthy":true,
            "Capabilities":[
              "mac/ios",
              "mac"
            ],
            "HealthDetails":"ssh-connectivity: succeeded\\n    Last known IP address: 192.168.1.233\\n\\nios-device-43ad2fda7991b34fe1acbda82f9e2fd3d6ddc9f7: succeeded\\nhas-healthy-devices: succeeded\\n    Found 1 healthy devices\\n\\ncocoon-authentication: succeeded\\ncocoon-connection: succeeded\\nable-to-build-and-sign: succeeded\\nios: succeeded\\nable-to-perform-health-check: succeeded\\n"
          }
        ]
  }
''';

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
        ],
        "AgentStatuses":[
        ]
  }
''';

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
