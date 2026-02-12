// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:appengine/appengine.dart' as gae;

import 'context.dart';

class AppEngineClientContext implements ClientContext {
  final gae.ClientContext _context;
  AppEngineClientContext(this._context);

  @override
  bool get isDevelopmentEnvironment => _context.isDevelopmentEnvironment;
}
