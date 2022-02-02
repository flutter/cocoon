// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/request_handling/pubsub.dart';

class FakePubSub extends PubSub {
  List<dynamic> messages = <dynamic>[];

  @override
  Future<void> publish(String topicName, dynamic json) async {
    messages.add(json);
  }
}
