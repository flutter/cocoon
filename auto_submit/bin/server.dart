// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Future main() async {
  Future<Response> emptyHandler(Request request) async {
    return Response.ok(
      jsonEncode(<String, String>{}),
      headers: {
        'content-type': 'application/json',
      },
    );
  }

  final router = Router()..get('/', emptyHandler);

  await serveHandler(router);
}
