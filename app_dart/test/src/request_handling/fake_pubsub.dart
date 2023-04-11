// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/request_handling/pubsub.dart';
import 'package:googleapis/pubsub/v1.dart';

class FakePubSub extends PubSub {
  List<dynamic> messages = <dynamic>[];
  bool exceptionFlag = false;
  int exceptionRepetition = 1;

  @override
  Future<List<String>> publish(String topicName, dynamic json) async {
    if (exceptionFlag && exceptionRepetition > 0) {
      exceptionRepetition--;
      throw DetailedApiRequestError(500, 'test api error');
    }
    messages.add(json);
    return <String>[];
  }
}
