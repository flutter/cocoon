// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/request_handling/http_io.dart';
import 'package:cocoon_service/src/request_handling/http_utils.dart'
    as cocoon_service;
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'mapping_http_client_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  useTestLoggerPerTest();

  group('MappingHttpClient', () {
    late MockClient mockClient;
    late MappingHttpClient mappingClient;

    setUp(() {
      mockClient = MockClient();
      mappingClient = MappingHttpClient(mockClient);
    });

    test('maps io.SocketException to cocoon_service.SocketException', () async {
      when(
        mockClient.send(any),
      ).thenThrow(const io.SocketException('test message'));

      expect(
        () => mappingClient.get(Uri.parse('https://example.com')),
        throwsA(
          isA<cocoon_service.SocketException>().having(
            (e) => e.message,
            'message',
            'SocketException: test message',
          ),
        ),
      );
    });

    test('maps io.HttpException to cocoon_service.HttpException', () async {
      when(
        mockClient.send(any),
      ).thenThrow(const io.HttpException('test message'));

      expect(
        () => mappingClient.get(Uri.parse('https://example.com')),
        throwsA(
          isA<cocoon_service.HttpException>().having(
            (e) => e.message,
            'message',
            'HttpException: test message',
          ),
        ),
      );
    });

    test('passes through successful responses', () async {
      final response = http.StreamedResponse(const Stream.empty(), 200);
      when(mockClient.send(any)).thenAnswer((_) async => response);

      final result = await mappingClient.get(Uri.parse('https://example.com'));
      expect(result.statusCode, 200);
    });
  });
}
