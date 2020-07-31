// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' show File;

/// Validates if the input builders JSON file has valid contents.
///
/// Examples:
/// dart validate_json.dart /path/to/json/file
Future<bool> main(List<String> args) async {
  final String jsonString = await File(args[0]).readAsString();
  Map<String, dynamic> decodedJson;
  bool decodedStatus = true;
  try {
    decodedJson = json.decode(jsonString) as Map<String, dynamic>;
    final List<dynamic> builders = decodedJson['builders'] as List<dynamic>;
    if (builders == null) {
      print('Json format is violated: no "builders" exists. Please follow');
      print('''
      {
        "builders":[
          {
            "name":"xxx",
            "repo":"cocoon"
          }
        ]
      }''');
      return decodedStatus = false;
    }
  } on FormatException catch (e) {
    print('error: $e');
    return decodedStatus = false;
  }
  print('Success.');
  return decodedStatus;
}
