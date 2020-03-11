// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:gcloud/datastore.dart';
import 'package:grpc/grpc.dart';

import 'package:cocoon_service/src/foundation/utils.dart';

class Counter {
  int count = 0;
  void increase() {
    count = count + 1;
  }

  int value() {
    return count;
  }
}

void main() {
  group('RunTransactionWithRetry', () {
    test('retriesOnGrpcError', () async {
      final Counter counter = Counter();
      try {
        await runTransactionWithRetries(() async {
          counter.increase();
          throw GrpcError.aborted();
        });
      } catch (e) {
        expect(e, isA<GrpcError>());
      }
      expect(counter.value(), greaterThan(1));
    });
    test('retriesTransactionAbortedError', () async {
      final Counter counter = Counter();
      try {
        await runTransactionWithRetries(() async {
          counter.increase();
          throw TransactionAbortedError();
        });
      } catch (e) {
        expect(e, isA<TransactionAbortedError>());
      }
      expect(counter.value(), greaterThan(1));
    });
    test('DoesNotRetryOnSuccess', () async {
      final Counter counter = Counter();
      await runTransactionWithRetries(() async {
        counter.increase();
      });
      expect(counter.value(), equals(1));
    });
  });
}
