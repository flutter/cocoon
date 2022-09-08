// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:graphql/client.dart';

class RetryableMergeException implements Exception {
  RetryableMergeException(this.cause, this.graphQLErrors);

  final String cause;

  final List<GraphQLError> graphQLErrors;

  @override
  String toString() => cause;
}
