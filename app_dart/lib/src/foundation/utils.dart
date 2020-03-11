// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/datastore.dart';
import 'package:retry/retry.dart';

typedef RetryHandler = Function();

// Runs a db transaction with retries.
//
// It uses quadratic backoff starting with 50ms and 3 max attempts.
Future<void> runTransactionWithRetries(RetryHandler retryHandler) {
  const RetryOptions r =
      RetryOptions(delayFactor: Duration(milliseconds: 50), maxAttempts: 3);
  return r.retry(retryHandler,
      retryIf: (Exception e) => e is TransactionAbortedError);
}
