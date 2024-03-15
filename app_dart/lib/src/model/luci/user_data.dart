// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

/// Small utility methods to create a single place where we are encoding and
/// decoding strings from buildbucket. This prevents us missing decoding in
/// certain places or decoding incorrectly.
class UserData {
  static Map<String, dynamic> decodeUserDataBytes(List<int> encodedBytes) {
    return decodeUserDataString(String.fromCharCodes(encodedBytes));
  }

  static Map<String, dynamic> decodeUserDataString(String encoded) {
    final Uint8List bytes = base64.decode(encoded);
    final String rawJson = String.fromCharCodes(bytes);
    if (rawJson.isEmpty) {
      return <String, dynamic>{};
    }
    return json.decode(rawJson) as Map<String, dynamic>;
  }

  static List<int>? encodeUserDataToBytes(Map<String, dynamic> userDataMap) {
    return base64Encode(json.encode(userDataMap).codeUnits).codeUnits;
  }

  static String? encodeUserDataToString(Map<String, dynamic> userDataMap) {
    return base64Encode(json.encode(userDataMap).codeUnits);
  }
}
