// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_dashboard/service/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../utils/mocks.dart';

void main() {
  late FirebaseAnalyticsService analyticsService;
  late MockFirebaseAnalytics mockAnalytics;

  setUp(() {
    mockAnalytics = MockFirebaseAnalytics();
    when(
      mockAnalytics.logEvent(
        name: anyNamed('name'),
        parameters: anyNamed('parameters'),
      ),
    ).thenAnswer((_) async {});
    analyticsService = FirebaseAnalyticsService(analytics: mockAnalytics);
  });

  test('logPresubmitPageOpen logs event with parameters', () async {
    await analyticsService.logPresubmitPageOpen(
      repo: 'flutter',
      pr: '123',
      sha: 'abc',
    );

    verify(
      mockAnalytics.logEvent(
        name: 'presubmit_page_open',
        parameters: <String, Object>{
          'repo': 'flutter',
          'pr': '123',
          'sha': 'abc',
        },
      ),
    ).called(1);
  });

  test('logRerunJob logs event with parameters', () async {
    await analyticsService.logRerunJob(
      repo: 'flutter',
      pr: '123',
      jobName: 'Linux test',
    );

    verify(
      mockAnalytics.logEvent(
        name: 'presubmit_rerun_job',
        parameters: <String, Object>{
          'repo': 'flutter',
          'pr': '123',
          'job_name': 'Linux test',
        },
      ),
    ).called(1);
  });

  test('logRerunAllFailedJobs logs event with parameters', () async {
    await analyticsService.logRerunAllFailedJobs(repo: 'flutter', pr: '123');

    verify(
      mockAnalytics.logEvent(
        name: 'presubmit_rerun_failed_jobs',
        parameters: <String, Object>{'repo': 'flutter', 'pr': '123'},
      ),
    ).called(1);
  });

  test('logFilterDialogOpened logs event with parameters', () async {
    await analyticsService.logFilterDialogOpened(
      repo: 'flutter',
      pr: '123',
      sha: 'abc',
    );

    verify(
      mockAnalytics.logEvent(
        name: 'presubmit_filter_dialog',
        parameters: <String, Object>{
          'repo': 'flutter',
          'pr': '123',
          'sha': 'abc',
        },
      ),
    ).called(1);
  });

  test('logViewLuciUi logs event with parameters', () async {
    await analyticsService.logViewLuciUi(
      repo: 'flutter',
      pr: '123',
      jobName: 'Linux test',
      buildNumber: 42,
    );

    verify(
      mockAnalytics.logEvent(
        name: 'presubmit_view_luci_ui',
        parameters: <String, Object>{
          'repo': 'flutter',
          'pr': '123',
          'job_name': 'Linux test',
          'build_number': 42,
        },
      ),
    ).called(1);
  });

  test('logAnalyzeLogsWithGemini logs event with parameters', () async {
    await analyticsService.logAnalyzeLogsWithGemini(
      repo: 'flutter',
      pr: '123',
      jobName: 'Linux test',
      buildId: '987654321',
    );

    verify(
      mockAnalytics.logEvent(
        name: 'presubmit_analyze_logs_gemini',
        parameters: <String, Object>{
          'repo': 'flutter',
          'pr': '123',
          'job_name': 'Linux test',
          'build_id': '987654321',
        },
      ),
    ).called(1);
  });

  test('catches exceptions from underlying FirebaseAnalytics', () async {
    when(
      mockAnalytics.logEvent(
        name: anyNamed('name'),
        parameters: anyNamed('parameters'),
      ),
    ).thenThrow(Exception('analytics failure'));

    await expectLater(
      analyticsService.logPresubmitPageOpen(repo: 'flutter'),
      completes,
    );
  });
}
