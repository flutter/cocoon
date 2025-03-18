// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/cocoon_common.dart';
import 'package:file/file.dart';
import 'package:glob/glob.dart';

import '../checks.dart';

/// Enforces that `useTestLoggerPerTest()` is used on matching files.
final class UseTestLogging extends Check {
  const UseTestLogging();

  static const _import = 'package:cocoon_server_test/test_logging.dart';
  static final _hasImport = RegExp("import '$_import'");

  static const _method = 'useTestLoggerPerTest()';
  static final _hasMethodCall = RegExp('$_method;');

  static final _voidMain = 'void main() {';

  @override
  Glob get shouldCheck => Glob('test/**/*_test.dart');

  @override
  Iterable<Glob> get allowListed => [
    Glob('app_dart/test/foundation/**'),
    Glob('app_dart/test/model/**'),
    Glob('app_dart/test/request_handlers/**'),
    Glob('app_dart/test/request_handling/**'),
    Glob('app_dart/test/service/**'),
  ];

  @override
  Future<CheckResult> check(LogSink logger, File file) async {
    final contents = file.readAsStringSync();
    if (!_hasImport.hasMatch(contents)) {
      logger.error('Missing import $_import');
      return CheckResult.failed;
    }
    if (!_hasMethodCall.hasMatch(contents)) {
      logger.error('Missing $_method');
      return CheckResult.failed;
    }
    if (!contents.contains(_voidMain)) {
      logger.error('Missing void main()');
      return CheckResult.failed;
    }
    return CheckResult.passed;
  }
}
