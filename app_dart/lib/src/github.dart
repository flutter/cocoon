// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:github/server.dart';

Future<PullRequestEvent> getPullRequest(String request) async {
  if (request == null) {
    return null;
  }
  try {
    final PullRequestEvent event =
        PullRequestEvent.fromJSON(json.decode(request));

    if (event == null) {
      return null;
    }

    return event;
  } on FormatException {
    return null;
  }
}
