// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/config.dart';
import '../service/logging.dart';

@immutable
class ReadinessCheck extends RequestHandler<Body> {
  const ReadinessCheck({required Config config}) : super(config: config);

  @override
  Future<Body> get() async {
    Timer(const Duration(minutes: 1), () async => log.info('Hello minute 1'));
    Timer(const Duration(minutes: 1), () async => log.info('Hello minute 2'));
    Timer(const Duration(minutes: 1), () async => log.info('Hello minute 3'));
    Timer(const Duration(minutes: 1), () async => log.info('Hello minute 4'));
    Timer(const Duration(minutes: 1), () async => log.info('Hello minute 5'));
    log.info('task is complete');
    return Body.empty;
  }
}
