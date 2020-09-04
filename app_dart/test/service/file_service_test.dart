// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/model/devicelab/manifest.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/file_service.dart';
import 'package:test/test.dart';

import '../src/request_handling/fake_http.dart';
import '../src/request_handling/fake_logging.dart';

const String singleTaskManifestYaml = '''
tasks:
  linux_test:
    stage: devicelab
    required_agent_capabilities: ["linux/android"]
''';

void main() {
  group('FileService', () {
    FakeHttpClient httpClient;
    FakeLogging log;
    FileService fileService;

    setUp(() {
      httpClient = FakeHttpClient();
      log = FakeLogging();
      fileService = FileService(
        httpClientProvider: () => httpClient,
        gitHubBackoffCalculator: (int attempt) => Duration.zero,
        loggingProvider: () => log,
      );
    });

    test('loads a manifest', () async {
      httpClient.onIssueRequest = (FakeHttpClientRequest request) {
        request.response.statusCode = HttpStatus.ok;
      };
      httpClient.request.response.body = singleTaskManifestYaml;

      final Manifest manifest = await fileService.loadDevicelabManifest('sha123');
      expect(manifest.tasks, <String, ManifestTask>{
        'linux_test': const ManifestTask(
          stage: 'devicelab',
          requiredAgentCapabilities: <String>['linux/android'],
          isFlaky: false,
          timeoutInMinutes: 0,
        )
      });
    });

    test('retries manifest download upon HTTP failure', () async {
      int retry = 0;
      httpClient.onIssueRequest = (FakeHttpClientRequest request) {
        request.response.statusCode = retry == 0 ? HttpStatus.serviceUnavailable : HttpStatus.ok;
        retry++;
      };
      httpClient.request.response.body = singleTaskManifestYaml;

      await fileService.loadDevicelabManifest('sha123');

      expect(retry, 2);
      expect(log.records.where(hasLevel(LogLevel.WARNING)), isNotEmpty);
      expect(log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
    });

    test('gives up manifest download after 3 tries', () async {
      int retry = 0;
      httpClient.onIssueRequest = (FakeHttpClientRequest request) => retry++;
      httpClient.request.response.statusCode = HttpStatus.serviceUnavailable;

      await expectLater(fileService.loadDevicelabManifest('sha123'), throwsA(isA<HttpStatusException>()));

      expect(retry, 3);
      expect(log.records.where(hasLevel(LogLevel.WARNING)), isNotEmpty);
      expect(log.records.where(hasLevel(LogLevel.ERROR)), isNotEmpty);
    });
  });
}
