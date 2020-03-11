// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/datastore.dart';
import 'package:retry/retry.dart';
import 'package:grpc/grpc.dart';

typedef RetryHandler = Function();

// Runs a db transaction with retries.
//
// It uses quadratic backoff starting with 50ms and 3 max attempts.
Future<void> runTransactionWithRetries(RetryHandler retryHandler,
    {int delayMilliseconds = 50, int maxAttempts = 3}) {
  final RetryOptions r = RetryOptions(
      delayFactor: Duration(milliseconds: delayMilliseconds),
      maxAttempts: maxAttempts);
  return r.retry(
    retryHandler,
    retryIf: (Exception e) => e is TransactionAbortedError || e is GrpcError,
  );
}
