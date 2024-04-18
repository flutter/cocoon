// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/model/luci/user_data.dart';
import 'package:test/test.dart';

void main() {
  final Map<String, dynamic> userDataMap = {
    'builder_name': 'Linux_web web_build_all_packages master',
    'check_run_id': 23005733384,
    'commit_sha': '272c0683235ac8c7e93d12caf3f64b7e5a0b5c32',
    'commit_branch': 'main',
    'repo_owner': 'flutter',
    'repo_name': 'packages',
    'user_agent': 'flutter-cocoon',
  };

  late String mapStr;
  late String encodedStr;
  late List<int> encodedBytes;

  setUp(() {
    // Encoded as in our pubsub which is passed through from luci.
    mapStr = jsonEncode(userDataMap);
    encodedStr = base64Encode(mapStr.codeUnits);
    encodedBytes = encodedStr.codeUnits;
  });

  test('user data conversions from bytes', () {
    final Map<String, dynamic> decodedUserDataMap = UserData.decodeUserDataBytes(encodedBytes);
    expect(userDataMap, decodedUserDataMap);
    final List<int>? bytesAgain = UserData.encodeUserDataToBytes(userDataMap);
    expect(encodedBytes, bytesAgain);
  });

  test('user data conversions from strings', () {
    final Map<String, dynamic> decodedUserStrDataMap = UserData.decodeUserDataString(encodedStr);
    expect(userDataMap, decodedUserStrDataMap);
    final String? encodedStringAgain = UserData.encodeUserDataToString(userDataMap);
    expect(encodedStr, encodedStringAgain);
  });
}
