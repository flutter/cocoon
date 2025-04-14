// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/content_aware_hash_service.dart';

/// Fake for [Scheduler] to use for tests that rely on it.
class FakeContentAwareHashService implements ContentAwareHashService {
  final Config config;
  FakeContentAwareHashService({required this.config});

  final triggered = <String>[];

  ContentHashWorkflowStatus? nextReturn;

  @override
  Future<ContentHashWorkflowStatus> triggerWorkflow(String gitRef) async {
    triggered.add(gitRef);

    final status = nextReturn ?? ContentHashWorkflowStatus.ok;
    nextReturn = null;
    return status;
  }
}
