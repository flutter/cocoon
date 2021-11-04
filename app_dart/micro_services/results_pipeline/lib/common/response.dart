// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

/// Helper function to send a response and perform
/// housekeeping on the Http connection.
Future<void> respond(HttpRequest request,
    {int status = HttpStatus.ok, String body = ''}) async {
  request.response.statusCode = status;
  await request.response.addStream(Stream<List<int>>.value(utf8.encode(body)));
  await request.response.flush();
  await request.response.close();
}
