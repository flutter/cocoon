// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

String constructCommit({required DateTime date}) {
  return '''
  {
    "sha": "abcd",
    "node_id": "C_id",
    "commit": {
      "author": {
        "name": "Test Author",
        "email": "test@gmail.com",
        "date": "${date.toIso8601String()}"
      }
    },
    "url": "https://api.github.com/repos/flutter/flutter/commits/abcd",
    "html_url": "https://github.com/flutter/flutter/commit/abcd",
    "comments_url": "https://api.github.com/repos/flutter/flutter/commits/abcd/comments",
    "files": []
  }
''';
}

String constructEmptyCommit() {
  return '''
  {
    "sha": "abcd",
    "node_id": "C_id",
    "url": "https://api.github.com/repos/flutter/flutter/commits/abcd",
    "html_url": "https://github.com/flutter/flutter/commit/abcd",
    "comments_url": "https://api.github.com/repos/flutter/flutter/commits/abcd/comments",
    "files": []
  }
''';
}
