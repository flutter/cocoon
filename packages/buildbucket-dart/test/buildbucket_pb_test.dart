// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart';
import 'package:test/test.dart';

Map<String, dynamic> buildJson = {
  'builder': {'project': 'flutter', 'bucket': 'try', 'builder': 'buildabc'},
};

void main() {
  group('Build proto', () {
    test('From json and to json', () {
      Build build = Build();
      build.mergeFromProto3Json(buildJson);
      expect(build.toProto3Json(), buildJson);
    });
  });
}
