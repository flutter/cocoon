// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

const String pullRequestRecordResponse = '''
{
  "jobComplete": true,
  "rows": [
    { "f": [
        { "v": "123456789"},
        { "v": "234567890" },
        { "v": "flutter" },
        { "v": "cocoon" },
        { "v": "ricardoamador" },
        { "v": "345" },
        { "v": "ade456" },
        { "v": "merge" }
      ]
    }
  ]
}
''';

const String successResponseNoRowsAffected = '''
{
  "jobComplete": true
}
''';

const String insertDeleteUpdateSuccessResponse = '''
{
  "jobComplete": true,
  "numDmlAffectedRows": "1"
}
''';

const String insertDeleteUpdateSuccessTooManyRows = '''
{
  "jobComplete": true,
  "numDmlAffectedRows": "2"
}
''';

const String selectPullRequestTooManyRowsResponse = '''
{
  "jobComplete": true,
  "numDmlAffectedRows": "2",
  "rows": [
    { "f": [
        { "v": "123456789"},
        { "v": "234567890" },
        { "v": "flutter" },
        { "v": "cocoon" },
        { "v": "ricardoamador" },
        { "v": "345" },
        { "v": "ade456" },
        { "v": "merge" }
      ]
    },
    { "f": [
        { "v": "123456789"},
        { "v": "234567890" },
        { "v": "flutter" },
        { "v": "cocoon" },
        { "v": "ricardoamador" },
        { "v": "345" },
        { "v": "ade456" },
        { "v": "merge" }
      ]
    }
  ]
}
''';

const String errorResponse = '''
{
  "jobComplete": false
}
''';

const String selectReviewRequestRecordsResponse = '''
{
  "jobComplete": true,
  "numDmlAffectedRows": "2",
  "rows": [
    { "f": [
        { "v": "Keyonghan" },
        { "v": "2048" },
        { "v": "234567890" },
        { "v": "0" },
        { "v": "" }
      ]
    },
    { "f": [
        { "v": "caseyhillers" },
        { "v": "2049" },
        { "v": "234567890" },
        { "v": "0" },
        { "v": "" }
      ]
    }
  ]
}
''';

const String expectedProjectId = 'flutter-dashboard';
