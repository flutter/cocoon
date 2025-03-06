// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:buildbucket/buildbucket_pb.dart';

void main() {
  // Create a BuildBucket build from a json string.
  Build build = Build();
  final String json =
      '{"builder": {"project": "flutter", "bucket": "try", "builder": "buildabc"}}';
  Map<String, dynamic> jsonObject = jsonDecode(json);
  build.mergeFromProto3Json(jsonObject);
  // Enconding the Build instance to a json object.
  print(build.toProto3Json());
}
