// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/service/luci_build_service/firestore_task_document_name.dart';
import 'package:cocoon_service/src/service/luci_build_service/user_data.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  // TODO(matanlurey): Remove after validating https://github.com/flutter/flutter/issues/164568.
  List<int> encodeUserDataToBase64Bytes(Map<String, Object?> userDataMap) {
    // Copied from original UserData class/helper:
    // https: //github.com/flutter/cocoon/blob/07f315907f77d2749c476459678ba625bbe01014/app_dart/lib/src/model/luci/user_data.dart
    return base64Encode(json.encode(userDataMap).codeUnits).codeUnits;
  }
}
