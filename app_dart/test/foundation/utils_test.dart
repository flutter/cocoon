// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_common/cocoon_common.dart';
import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/foundation/utils.dart';
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/service/get_files_changed.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../src/bigquery/fake_tabledata_resource.dart';
import '../src/utilities/entity_generators.dart';

const String branchRegExp = '''
      master
      flutter-1.1-candidate.1
      ''';

void main() {
  useTestLoggerPerTest();

  group('Test utils', () {
    const noRetry = RetryOptions(
      maxAttempts: 1,
      delayFactor: Duration.zero,
      maxDelay: Duration.zero,
    );

    test('github merge queue branch parsing', () {
      expect(
        tryParseGitHubMergeQueueBranch(
          'gh-readonly-queue/master/pr-160481-1398dc7eecb696d302e4edb19ad79901e615ed56',
        ),
        (parsed: true, branch: 'master', pullRequestNumber: 160481),
        reason: 'parses expected magic branch',
      );
      expect(
        tryParseGitHubMergeQueueBranch('master'),
        notGitHubMergeQueueBranch,
        reason: 'does not parse regular branch',
      );
    });

    group('githubFileContent', () {
      late MockClient branchHttpClient;

      test('returns branches', () async {
        branchHttpClient = MockClient(
          (_) async => http.Response(branchRegExp, HttpStatus.ok),
        );
        final branches = await githubFileContent(
          RepositorySlug('flutter', 'cocoon'),
          'branches.txt',
          httpClientProvider: () => branchHttpClient,
          retryOptions: noRetry,
        );

        expect(branches.split('\n'), [
          equalsIgnoringWhitespace('master'),
          equalsIgnoringWhitespace('flutter-1.1-candidate.1'),
          equalsIgnoringWhitespace(''),
        ]);
      });

      test('retries branches download upon HTTP failure', () async {
        var retried = 0;
        branchHttpClient = MockClient((_) async {
          if (retried++ == 0) {
            return http.Response('', HttpStatus.serviceUnavailable);
          }
          return http.Response(branchRegExp, HttpStatus.ok);
        });
        final branches = await githubFileContent(
          RepositorySlug('flutter', 'cocoon'),
          'branches.txt',
          httpClientProvider: () => branchHttpClient,
          retryOptions: const RetryOptions(
            maxAttempts: 3,
            delayFactor: Duration.zero,
            maxDelay: Duration.zero,
          ),
        );

        expect(retried, 2);
        expect(branches.split('\n'), [
          equalsIgnoringWhitespace('master'),
          equalsIgnoringWhitespace('flutter-1.1-candidate.1'),
          equalsIgnoringWhitespace(''),
        ]);

        expect(
          log2,
          bufferedLoggerOf(
            contains(
              logThat(message: anything, severity: equals(Severity.info)),
            ),
          ),
        );
        expect(log2, hasNoWarningsOrHigher);
      });

      test('falls back to git on borg', () async {
        branchHttpClient = MockClient((http.Request request) async {
          if (request.url.toString() ==
              'https://flutter.googlesource.com/mirrors/cocoon/+/ba7fe03781762603a1cdc364f8f5de56a0fdbf5c/.ci.yaml?format=text') {
            return http.Response(
              base64Encode(branchRegExp.codeUnits),
              HttpStatus.ok,
            );
          }
          // Mock a GitHub outage
          return http.Response('', HttpStatus.serviceUnavailable);
        });
        final branches = await githubFileContent(
          RepositorySlug('flutter', 'cocoon'),
          '.ci.yaml',
          httpClientProvider: () => branchHttpClient,
          ref: 'ba7fe03781762603a1cdc364f8f5de56a0fdbf5c',
          retryOptions: const RetryOptions(
            maxAttempts: 1,
            delayFactor: Duration.zero,
            maxDelay: Duration.zero,
          ),
        );

        expect(branches.split('\n'), [
          equalsIgnoringWhitespace('master'),
          equalsIgnoringWhitespace('flutter-1.1-candidate.1'),
          equalsIgnoringWhitespace(''),
        ]);
      });

      test('falls back to git on borg when given sha', () async {
        branchHttpClient = MockClient((http.Request request) async {
          if (request.url.toString() ==
              'https://flutter.googlesource.com/mirrors/cocoon/+/refs/heads/main/.ci.yaml?format=text') {
            return http.Response(
              base64Encode(branchRegExp.codeUnits),
              HttpStatus.ok,
            );
          }
          // Mock a GitHub outage
          return http.Response('', HttpStatus.serviceUnavailable);
        });
        final branches = await githubFileContent(
          RepositorySlug('flutter', 'cocoon'),
          '.ci.yaml',
          ref: 'main',
          httpClientProvider: () => branchHttpClient,
          retryOptions: const RetryOptions(
            maxAttempts: 1,
            delayFactor: Duration.zero,
            maxDelay: Duration.zero,
          ),
        );

        expect(branches.split('\n'), [
          equalsIgnoringWhitespace('master'),
          equalsIgnoringWhitespace('flutter-1.1-candidate.1'),
          equalsIgnoringWhitespace(''),
        ]);
      });

      test('gives up after 6 tries', () async {
        var retry = 0;
        branchHttpClient = MockClient((_) async {
          retry++;
          return http.Response('', HttpStatus.serviceUnavailable);
        });
        await expectLater(
          githubFileContent(
            RepositorySlug('flutter', 'cocoon'),
            'branches.txt',
            httpClientProvider: () => branchHttpClient,
            retryOptions: const RetryOptions(
              maxAttempts: 3,
              delayFactor: Duration.zero,
              maxDelay: Duration.zero,
            ),
          ),
          throwsA(isA<HttpException>()),
        );

        // It will request from GitHub 3 times, fallback to GoB, then fail.
        expect(retry, 6);
        expect(
          log2,
          bufferedLoggerOf(
            containsAll([
              logThat(
                message: contains('HTTP 503'),
                severity: equals(Severity.warning),
              ),
              logThat(
                message: contains('HTTP 503'),
                severity: equals(Severity.warning),
              ),
              logThat(
                message: contains('HTTP 503'),
                severity: equals(Severity.warning),
              ),
              logThat(
                message: matches(RegExp('Failed to fetch.*falling back to')),
                severity: equals(Severity.warning),
              ),
              logThat(
                message: contains('HTTP 503'),
                severity: equals(Severity.warning),
              ),
              logThat(
                message: contains('HTTP 503'),
                severity: equals(Severity.warning),
              ),
              logThat(
                message: contains('HTTP 503'),
                severity: equals(Severity.warning),
              ),
            ]),
          ),
        );
      });
    });

    group('GitHubBackoffCalculator', () {
      test('twoSecondLinearBackoff', () {
        expect(twoSecondLinearBackoff(0), const Duration(seconds: 2));
        expect(twoSecondLinearBackoff(1), const Duration(seconds: 4));
        expect(twoSecondLinearBackoff(2), const Duration(seconds: 6));
        expect(twoSecondLinearBackoff(3), const Duration(seconds: 8));
      });
    });

    group('bigquery', () {
      late FakeTabledataResource tabledataResourceApi;

      setUp(() {
        tabledataResourceApi = FakeTabledataResource();
      });
      test('Insert data to bigquery', () async {
        await insertBigquery('test', <String, dynamic>{
          'test': 'test',
        }, tabledataResourceApi);
        final tableDataList = await tabledataResourceApi.list(
          'test',
          'test',
          'test',
        );
        expect(tableDataList.totalRows, '1');
      });
    });

    group('getFilteredBuilders', () {
      test(
        'does not return builders when run_if does not match any file',
        () async {
          final targets = <Target>[
            generateTarget(1, runIf: <String>['cde/']),
          ];
          final result = await getTargetsToRun(
            targets,
            SuccessfulFilesChanged(
              pullRequestNumber: 1234,
              filesChanged: const ['abc/cde.py', 'cde/fgh.dart'],
            ),
          );
          expect(result.isEmpty, isTrue);
        },
      );

      test('skips filtering when 30 or more files were updated', () async {
        final targets = <Target>[
          generateTarget(1, runIf: <String>['cde/']),
        ];
        final result = await getTargetsToRun(
          targets,
          const InconclusiveFilesChanged(
            pullRequestNumber: 1234,
            reason: 'We gave up',
          ),
        );
        expect(result, targets);
      });

      test('returns builders when run_if is null', () async {
        final targets = <Target>[generateTarget(1)];
        final result = await getTargetsToRun(
          targets,
          SuccessfulFilesChanged(
            pullRequestNumber: 12324,
            filesChanged: const ['abc/def.py', 'cde/dgh.dart'],
          ),
        );
        expect(result, targets);
      });

      test(
        'returns builders when run_if matches files using full path',
        () async {
          final targets = <Target>[
            generateTarget(1, runIf: <String>['abc/cde.py']),
          ];
          final result = await getTargetsToRun(
            targets,
            SuccessfulFilesChanged(
              pullRequestNumber: 1234,
              filesChanged: const ['abc/cde.py', 'cgh/dhj.dart'],
            ),
          );
          expect(result, targets);
        },
      );

      test('returns builders when run_if matches files with **', () async {
        final targets = <Target>[
          generateTarget(1, runIf: <String>['abc/**']),
        ];
        final result = await getTargetsToRun(
          targets,
          SuccessfulFilesChanged(
            pullRequestNumber: 1234,
            filesChanged: const ['abc/cdf/hj.dart', 'abc/dej.dart'],
          ),
        );
        expect(result, targets);
      });

      test(
        'returns builders when run_if matches files with ** that contain digits',
        () async {
          final targets = <Target>[
            generateTarget(
              1,
              runIf: <String>[
                'dev/**',
                'packages/flutter/**',
                'packages/flutter_driver/**',
                'packages/integration_test/**',
                'packages/flutter_localizations/**',
                'packages/fuchsia_remote_debug_protocol/**',
                'packages/flutter_test/**',
                'packages/flutter_goldens/**',
                'packages/flutter_tools/**',
                'bin/**',
                '.ci.yaml',
              ],
            ),
          ];
          final result = await getTargetsToRun(
            targets,
            SuccessfulFilesChanged(
              pullRequestNumber: 1234,
              filesChanged: const [
                'packages/flutter_localizations/lib/src/l10n/material_es.arb',
                'packages/flutter_localizations/lib/src/l10n/material_en_ZA.arb',
              ],
            ),
          );
          expect(result, targets);
        },
      );

      test(
        'returns builders when run_if matches files with * and ** that contains digits',
        () async {
          final targets = <Target>[
            generateTarget(
              1,
              runIf: <String>[
                'dev/**',
                'packages/flutter/**',
                'packages/flutter_driver/**',
                'packages/integration_test/**',
                'packages/flutter_localizations/**/l10n/cupertino*.arb',
                'packages/fuchsia_remote_debug_protocol/**',
                'packages/flutter_test/**',
                'packages/flutter_goldens/**',
                'packages/flutter_tools/**',
                'bin/**',
                '.ci.yaml',
              ],
            ),
          ];
          final result = await getTargetsToRun(
            targets,
            SuccessfulFilesChanged(
              pullRequestNumber: 1234,
              filesChanged: const [
                'packages/flutter_localizations/lib/src/l10n/material_es.arb',
                'packages/flutter_localizations/lib/src/l10n/material_en_ZA.arb',
                'packages/flutter_localizations/lib/src/l10n/cupertino_cy.arb',
              ],
            ),
          );
          expect(result, targets);
        },
      );

      test(
        'returns builders when run_if matches files with * trailing glob',
        () async {
          final targets = <Target>[
            generateTarget(
              1,
              runIf: <String>['packages/flutter_localizations/**/l10n/*'],
            ),
          ];
          final result = await getTargetsToRun(
            targets,
            SuccessfulFilesChanged(
              pullRequestNumber: 1234,
              filesChanged: const [
                'packages/flutter_localizations/lib/src/l10n/material_es.arb',
                'packages/flutter_localizations/lib/src/l10n/material_en_ZA.arb',
                'packages/flutter_localizations/lib/src/l10n/cupertino_cy.arb',
              ],
            ),
          );
          expect(result, targets);
        },
      );

      test(
        'returns builders when run_if matches files with * trailing glob 2',
        () async {
          final targets = <Target>[
            generateTarget(
              1,
              runIf: <String>[
                'packages/flutter_localizations/**/l10n/cupertino*',
              ],
            ),
          ];
          final result = await getTargetsToRun(
            targets,
            SuccessfulFilesChanged(
              pullRequestNumber: 1234,
              filesChanged: const [
                'packages/flutter_localizations/lib/src/l10n/material_es.arb',
                'packages/flutter_localizations/lib/src/l10n/material_en_ZA.arb',
                'packages/flutter_localizations/lib/src/l10n/cupertino_cy.arb',
              ],
            ),
          );
          expect(result, targets);
        },
      );

      test(
        'returns builders when run_if matches files with ** in the middle',
        () async {
          final targets = <Target>[
            generateTarget(1, runIf: <String>['abc/**/hj.dart']),
          ];
          final result = await getTargetsToRun(
            targets,
            SuccessfulFilesChanged(
              pullRequestNumber: 1234,
              filesChanged: const ['abc/cdf/efg/hj.dart', 'abc/dej.dart'],
            ),
          );
          expect(result, [targets[0]]);
        },
      );

      test(
        'returns builders when run_if matches files with both * and **',
        () async {
          final targets = <Target>[
            generateTarget(1, runIf: <String>['a/b*c/**']),
          ];
          final result = await getTargetsToRun(
            targets,
            SuccessfulFilesChanged(
              pullRequestNumber: 1234,
              filesChanged: const ['a/baddsc/defg.zz', 'c/d'],
            ),
          );
          expect(result, targets);
        },
      );

      test(
        'returns correct builders when file and folder share the same name',
        () async {
          final targets = <Target>[
            generateTarget(1, runIf: <String>['a/b/']),
            generateTarget(2, runIf: <String>['a']),
          ];
          final result = await getTargetsToRun(
            targets,
            SuccessfulFilesChanged(
              pullRequestNumber: 1234,
              filesChanged: const ['a'],
            ),
          );
          expect(result.length, 1);
          expect(result.single, targets[1]);
        },
      );
    });
  });

  group('Fusion Tests', () {
    const noRetry = RetryOptions(
      maxAttempts: 1,
      delayFactor: Duration.zero,
      maxDelay: Duration.zero,
    );

    final goodFlutterRef = (
      slug: RepositorySlug.full('flutter/flutter'),
      sha: '1234',
    );

    test('isFusionPR returns false non-flutter repo', () async {
      final branchHttpClient = MockClient((req) async {
        final url = '${req.url}';
        if (!url.contains(
          'https://raw.githubusercontent.com/flutter/flutter/DEPS',
        )) {
          return http.Response('', HttpStatus.notFound);
        }
        return http.Response('test', HttpStatus.ok);
      });
      final tester = FusionTester(httpClientProvider: () => branchHttpClient);

      final fusion = await tester.isFusionBasedRef(
        RepositorySlug('code', 'fu'),
        goodFlutterRef.sha,
        retryOptions: noRetry,
      );
      expect(fusion, isFalse);
    });

    test('isFusionPR returns false for missing DEPS file', () async {
      final branchHttpClient = MockClient((req) async {
        final url = '${req.url}';
        if (url.contains('flutter.googlesource.com')) {
          return http.Response('', HttpStatus.notFound);
        } else if (url.contains(
          'https://raw.githubusercontent.com/flutter/flutter/1234/DEPS',
        )) {
          return http.Response('', HttpStatus.notFound);
        }
        return http.Response('test', HttpStatus.ok);
      });
      final tester = FusionTester(httpClientProvider: () => branchHttpClient);

      final fusion = await tester.isFusionBasedRef(
        goodFlutterRef.slug,
        goodFlutterRef.sha,
        retryOptions: noRetry,
      );
      expect(fusion, isFalse);
    });

    test('isFusionPR returns false for missing engine/src/.gn file', () async {
      final branchHttpClient = MockClient((req) async {
        final url = '${req.url}';
        if (url.contains('flutter.googlesource.com')) {
          return http.Response('', HttpStatus.notFound);
        } else if (url.contains(
          'https://raw.githubusercontent.com/flutter/flutter/1234/engine/src/.gn',
        )) {
          return http.Response('', HttpStatus.notFound);
        }
        return http.Response('test', HttpStatus.ok);
      });
      final tester = FusionTester(httpClientProvider: () => branchHttpClient);

      final fusion = await tester.isFusionBasedRef(
        goodFlutterRef.slug,
        goodFlutterRef.sha,
        retryOptions: noRetry,
      );
      expect(fusion, isFalse);
    });

    test('isFusionPR returns false if required files are empty', () async {
      final branchHttpClient = MockClient((req) async {
        final url = '${req.url}';
        if (url.contains('flutter.googlesource.com')) {
          return http.Response('', HttpStatus.notFound);
        } else if (url.contains(
              'https://raw.githubusercontent.com/flutter/flutter/1234/engine/src/.gn',
            ) ||
            url.contains(
              'https://raw.githubusercontent.com/flutter/flutter/1234/DEPS',
            )) {
          return http.Response('', HttpStatus.ok);
        }
        return http.Response('test', HttpStatus.ok);
      });
      final tester = FusionTester(httpClientProvider: () => branchHttpClient);

      final fusion = await tester.isFusionBasedRef(
        goodFlutterRef.slug,
        goodFlutterRef.sha,
        retryOptions: noRetry,
      );
      expect(fusion, isFalse);
    });

    test('isFusionPR lets non-404 exceptions bubble', () async {
      final branchHttpClient = MockClient((req) async {
        final url = '${req.url}';
        if (url.contains('flutter.googlesource.com')) {
          return http.Response('', HttpStatus.badRequest);
        } else if (url.contains(
          'https://raw.githubusercontent.com/flutter/flutter/1234/engine/src/.gn',
        )) {
          return http.Response('', HttpStatus.badRequest);
        }
        return http.Response('test', HttpStatus.ok);
      });
      final tester = FusionTester(httpClientProvider: () => branchHttpClient);

      expect(
        tester.isFusionBasedRef(
          goodFlutterRef.slug,
          goodFlutterRef.sha,
          retryOptions: noRetry,
        ),
        throwsA(isA<HttpException>()),
      );
    });

    test('isFusionPR returns true whe expected files are present', () async {
      final branchHttpClient = MockClient((req) async {
        final url = '${req.url}';
        if (url.contains('flutter.googlesource.com')) {
          return http.Response('', HttpStatus.notFound);
        } else if (url.contains(
              'https://raw.githubusercontent.com/flutter/flutter/1234/engine/src/.gn',
            ) ||
            url.contains(
              'https://raw.githubusercontent.com/flutter/flutter/1234/DEPS',
            )) {
          return http.Response('FUSION', HttpStatus.ok);
        }
        return http.Response('test', HttpStatus.ok);
      });

      final tester = FusionTester(httpClientProvider: () => branchHttpClient);

      final fusion = await tester.isFusionBasedRef(
        goodFlutterRef.slug,
        goodFlutterRef.sha,
        retryOptions: noRetry,
      );
      expect(fusion, isTrue);
    });

    test('isFusionPR caches results', () async {
      final urlCalled = <String, int>{};

      final branchHttpClient = MockClient((req) async {
        final url = '${req.url}';
        urlCalled[url] = (urlCalled[url] ?? 0) + 1;
        if (url.contains('flutter.googlesource.com')) {
          return http.Response('', HttpStatus.notFound);
        } else if (url.contains(
              'https://raw.githubusercontent.com/flutter/flutter/1234/engine/src/.gn',
            ) ||
            url.contains(
              'https://raw.githubusercontent.com/flutter/flutter/1234/DEPS',
            )) {
          return http.Response('FUSION', HttpStatus.ok);
        }
        return http.Response('test', HttpStatus.ok);
      });

      final tester = FusionTester(httpClientProvider: () => branchHttpClient);
      final fusion = await tester.isFusionBasedRef(
        goodFlutterRef.slug,
        goodFlutterRef.sha,
        retryOptions: noRetry,
      );
      expect(fusion, isTrue);
      expect(
        urlCalled['https://raw.githubusercontent.com/flutter/flutter/1234/engine/src/.gn'],
        1,
      );
      expect(
        urlCalled['https://raw.githubusercontent.com/flutter/flutter/1234/DEPS'],
        1,
      );
    });
  });
}
