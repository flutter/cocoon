// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import '../bin/generate_jspb.dart' as gen_jspb show main, debugHttpClientFactory;

const String fakeCiYaml = '''
enabled_branches:
  - main
''';
void main() {
  late MockClient mockClient;

  setUp(() {
    gen_jspb.debugHttpClientFactory = () => mockClient;
  });

  test('generate with two args', () async {
    mockClient = MockClient((request) async {
      expect(request.url, Uri.parse('https://raw.githubusercontent.com/flutter/flutter/flutter/abcde/.ci.yaml'));
      return http.Response(fakeCiYaml, 200);
    });
    await gen_jspb.main(['flutter/flutter', 'abcde']);
  });

  test('generate with three args', () async {
    mockClient = MockClient((request) async {
      expect(request.url,
          Uri.parse('https://raw.githubusercontent.com/flutter/flutter/flutter/abcde/engine/src/.ci.yaml'));
      return http.Response(fakeCiYaml, 200);
    });
    await gen_jspb.main(['flutter/flutter', 'abcde', 'engine/src/.ci.yaml']);
  });
}
