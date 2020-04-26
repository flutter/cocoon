// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import 'package:cocoon_service/src/model/appengine/agent.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';

void main() {
  group('Agent', () {
    test('isCapableOfPerformingTask', () {
      Agent agent(List<String> capabilities) =>
          Agent(capabilities: capabilities);
      Task task(List<String> capabilities) =>
          Task(requiredCapabilities: capabilities);

      expect(agent(<String>[]).isCapableOfPerformingTask(task(<String>[])),
          isTrue);
      expect(agent(<String>['a']).isCapableOfPerformingTask(task(<String>[])),
          isTrue);
      expect(
          agent(<String>['a']).isCapableOfPerformingTask(task(<String>['a'])),
          isTrue);
      expect(
          agent(<String>['a', 'b'])
              .isCapableOfPerformingTask(task(<String>['a'])),
          isTrue);
      expect(
          agent(<String>['a', 'b'])
              .isCapableOfPerformingTask(task(<String>['b'])),
          isTrue);
      expect(agent(<String>[]).isCapableOfPerformingTask(task(<String>['a'])),
          isFalse);
      expect(
          agent(<String>['a']).isCapableOfPerformingTask(task(<String>['b'])),
          isFalse);
      expect(
          agent(<String>['a'])
              .isCapableOfPerformingTask(task(<String>['a', 'b'])),
          isFalse);
    });
  });
}
