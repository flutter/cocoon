// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

void main() async {
  final failingTest = Platform.environment['FAILING_TEST'];
  final buildNumberStr = Platform.environment['BUILD_NUMBER'];
  final commitSha = Platform.environment['COMMIT_SHA'];
  final testEnv = Platform.environment['TEST_ENV'] ?? 'try';

  if (failingTest == null) {
    print('Error: FAILING_TEST environment variable is required.');
    exit(1);
  }

  var buildNumber = buildNumberStr;

  if (buildNumber == null || buildNumber.isEmpty) {
    print('BUILD_NUMBER not provided, looking for COMMIT_SHA');
    if (commitSha == null || commitSha.isEmpty) {
      print('Error: Either BUILD_NUMBER or COMMIT_SHA must be provided.');
      exit(1);
    }

    print('Looking up buildnumber for Commit $commitSha...');
    buildNumber = await lookupBuildNumberFromCommit(commitSha, failingTest);
  }

  if (buildNumber == null) {
    print('Error: Could not find build number or ID.');
    exit(1);
  }

  print(
    'Fetching logs for test: $failingTest, build: $buildNumber, env: $testEnv',
  );

  final logUrl = await fetchLogUrl(failingTest, buildNumber, testEnv);
  if (logUrl == null) {
    print('Error: Could not find failure log URL.');
    exit(1);
  }

  print('Found log URL: $logUrl');

  final rawLog = await downloadRawLog(logUrl);
  if (rawLog == null) {
    print('Error: Could not download raw log.');
    exit(1);
  }

  print('Downloaded raw log. Length: ${rawLog.length}');

  final outputFile = File('failure_log.txt');
  await outputFile.writeAsString(rawLog);
  print('Saved log to failure_log.txt');
}

Future<String?> lookupBuildNumberFromCommit(
  String commitSha,
  String failingTest,
) async {
  try {
    // gh api repos/flutter/flutter/commits/<SHA>/check-runs --jq '.check_runs[] | select(.name == "<FAILING_TEST>") | .details_url'
    final uri = Uri.https(
      'api.github.com',
      '/repos/flutter/flutter/commits/$commitSha/check-runs',
      {'check_name': failingTest},
    );
    print('$uri');
    final result = await Process.run('curl', [
      '-H',
      'Accept: application/vnd.github+json',
      '-H',
      'X-GitHub-Api-Version: 2022-11-28',
      '$uri',
    ]);

    if (result.exitCode != 0) {
      print('curl failed: ${result.stderr}');
      return null;
    }

    String? detailUrl;
    final jsonObject = json.decode(result.stdout as String);
    if (jsonObject case {'check_runs': final List checkRuns}) {
      print('check runs found: ${checkRuns.length}');
      for (final check in checkRuns) {
        if (check case {
          'name': final String testName,
          'details_url': final String url,
        }) {
          print('check $testName $url');
          if (testName != failingTest) continue;
          detailUrl = url;
          break;
        }
      }
    }
    if (detailUrl == null) {
      throw Exception('''
ERROR: missing detail_url

The check run for the failing test "$failingTest" was either not found in the GitHub API response or did not contain a details_url.
''');
    }

    if (detailUrl!.isNotEmpty) {
      print('Found details URL: $detailUrl');
      // Extract ID from URL
      final idRegExp = RegExp(r'/build/(\d+)');
      final idMatch = idRegExp.firstMatch(detailUrl);
      if (idMatch != null) {
        return idMatch.group(1);
      }
    }
  } catch (e) {
    print('Error running gh api: $e');
  }
  return null;
}

Future<String?> fetchLogUrl(
  String failingTest,
  String buildNumberOrId,
  String testEnv,
) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse(
        'https://cr-buildbucket.appspot.com/prpc/buildbucket.v2.Builds/GetBuild',
      ),
    );
    request.headers.set('accept', 'application/json');
    request.headers.set('content-type', 'application/json');

    Map<String, dynamic> body;
    if (buildNumberOrId.length > 10) {
      body = {
        'id': buildNumberOrId,
        'mask': {'fields': 'steps,infra'},
      };
    } else {
      body = {
        'builder': {
          'project': 'flutter',
          'bucket': testEnv,
          'builder': failingTest,
        },
        'buildNumber': int.parse(buildNumberOrId),
        'mask': {'fields': 'steps,infra'},
      };
    }

    request.add(utf8.encode(json.encode(body)));
    final response = await request.close();
    // response stream of bytes -> stream of strings -> lines.
    final lines = await response
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .toList();

    if (lines.isEmpty) {
      print('No response lines received');
      return null;
    }

    if (lines[0].trim() == ")]}'") {
      lines.removeAt(0);
    }

    final data = json.decode(lines.join());
    final steps = data['steps'] as List<dynamic>?;
    if (steps == null) return null;

    for (final step in steps) {
      if (step['status'] == 'FAILURE') {
        final logs = step['logs'] as List<dynamic>?;
        if (logs != null) {
          for (final log in logs) {
            if (log['name'] == 'stdout') {
              final viewUrl = log['viewUrl'] as String?;
              if (viewUrl != null) {
                print('Found stdout log URL: $viewUrl');
                return viewUrl;
              }
            }
          }
        }
      }
    }
  } catch (e) {
    print('Error fetching log URL: $e');
  } finally {
    client.close();
  }
  return null;
}

Future<String?> downloadRawLog(String logUrl) async {
  final client = HttpClient();
  try {
    final rawUrl = '$logUrl?format=raw';
    final request = await client.getUrl(Uri.parse(rawUrl));
    final response = await request.close();
    if (response.statusCode == 200) {
      return await response.transform(utf8.decoder).join();
    } else {
      print('Failed to download log: ${response.statusCode}');
    }
  } catch (e) {
    print('Error downloading log: $e');
  } finally {
    client.close();
  }
  return null;
}
