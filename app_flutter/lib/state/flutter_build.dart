// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:app_flutter/service/cocoon.dart';
import 'package:flutter/widgets.dart';

import 'package:cocoon_service/protos.dart' show CommitStatus;

class FlutterBuildState extends ChangeNotifier {
  final CocoonService _cocoonService = CocoonService();

  List<CommitStatus> statuses;

  void fetchBuildStatusUpdate() async {
    _cocoonService.fetchCommitStatuses();
  }
}