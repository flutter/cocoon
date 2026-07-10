// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/request_handling/pubsub.dart';
import 'package:googleapis/pubsub/v1.dart';

class FakePubSub extends PubSub {
  List<dynamic> messages = <dynamic>[];
  List<String> topics = <String>[];
  List<String?> orderingKeys = <String?>[];
  bool exceptionFlag = false;
  int exceptionRepetition = 1;

  @override
  Future<List<String>> publish(
    String topic,
    dynamic json, {
    String? orderingKey,
  }) async {
    if (exceptionFlag && exceptionRepetition > 0) {
      exceptionRepetition--;
      throw DetailedApiRequestError(500, 'test api error');
    }
    topics.add(topic);
    messages.add(json);
    orderingKeys.add(orderingKey);
    return <String>[];
  }
}
