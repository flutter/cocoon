// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

class MockPlatform extends Mock implements Platform {}

class MockProcessManager extends Mock implements ProcessManager {}

class FakeProcess extends Fake implements Process {
  FakeProcess(int exitCode,
      {List<List<int>> err = const [
        <int>[1, 2, 3]
      ],
      List<List<int>> out = const [
        <int>[1, 2, 3]
      ]})
      : _exitCode = exitCode,
        _err = err,
        _out = out;

  int _exitCode;
  List<List<int>> _err;
  List<List<int>> _out;

  @override
  Future<int> get exitCode => Future.value(_exitCode);

  @override
  Stream<List<int>> get stderr => Stream.fromIterable(_err);

  @override
  Stream<List<int>> get stdout => Stream.fromIterable(_out);
}
