// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_dashboard/service/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/mocks.dart';

void main() {
  late FirebaseAnalyticsService analyticsService;
  late MockFirebaseAnalytics mockAnalytics;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    mockAnalytics = MockFirebaseAnalytics();
    when(
      mockAnalytics.logEvent(
        name: anyNamed('name'),
        parameters: anyNamed('parameters'),
      ),
    ).thenAnswer((_) async {});
    when(
      mockAnalytics.setAnalyticsCollectionEnabled(any),
    ).thenAnswer((_) async {});
    when(
      mockAnalytics.setConsent(
        analyticsStorageConsentGranted: anyNamed(
          'analyticsStorageConsentGranted',
        ),
      ),
    ).thenAnswer((_) async {});
    analyticsService = FirebaseAnalyticsService(analytics: mockAnalytics);
  });

  test(
    'setDefaultConsent disables analytics SDK and sets consent to denied when no preference is stored',
    () async {
      await analyticsService.setDefaultConsent();

      expect(analyticsService.showConsentBanner, isTrue);
      expect(analyticsService.isConsentGranted, isFalse);
      verify(mockAnalytics.setAnalyticsCollectionEnabled(false)).called(1);
      verify(
        mockAnalytics.setConsent(analyticsStorageConsentGranted: false),
      ).called(1);
    },
  );

  test(
    'setDefaultConsent restores accepted consent and hides banner when previously accepted',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        FirebaseAnalyticsService.consentPreferenceKey: true,
      });

      await analyticsService.setDefaultConsent();

      expect(analyticsService.showConsentBanner, isFalse);
      expect(analyticsService.isConsentGranted, isTrue);
      verify(mockAnalytics.setAnalyticsCollectionEnabled(true)).called(1);
      verify(
        mockAnalytics.setConsent(analyticsStorageConsentGranted: true),
      ).called(1);
    },
  );

  test(
    'setDefaultConsent restores rejected consent and hides banner when previously rejected',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        FirebaseAnalyticsService.consentPreferenceKey: false,
      });

      await analyticsService.setDefaultConsent();

      expect(analyticsService.showConsentBanner, isFalse);
      expect(analyticsService.isConsentGranted, isFalse);
      verify(mockAnalytics.setAnalyticsCollectionEnabled(false)).called(1);
      verify(
        mockAnalytics.setConsent(analyticsStorageConsentGranted: false),
      ).called(1);
    },
  );

  test(
    'does not collect analytics telemetry before user clicks Accept',
    () async {
      await analyticsService.setDefaultConsent();

      await analyticsService.logPresubmitPageOpen(
        repo: 'flutter',
        pr: '123',
        sha: 'abc',
      );
      await analyticsService.logRerunJob(
        repo: 'flutter',
        pr: '123',
        jobName: 'Linux test',
      );
      await analyticsService.logRerunAllFailedJobs(repo: 'flutter', pr: '123');
      await analyticsService.logFilterDialogOpened(
        repo: 'flutter',
        pr: '123',
        sha: 'abc',
      );
      await analyticsService.logViewLuciUi(
        repo: 'flutter',
        pr: '123',
        jobName: 'Linux test',
        buildNumber: 42,
      );
      await analyticsService.logAnalyzeLogsWithGemini(
        repo: 'flutter',
        pr: '123',
        jobName: 'Linux test',
        buildId: '987654321',
      );

      verifyNever(
        mockAnalytics.logEvent(
          name: anyNamed('name'),
          parameters: anyNamed('parameters'),
        ),
      );
    },
  );

  test(
    'acceptConsent enables analytics SDK, grants consent, hides banner, and persists choice',
    () async {
      var notified = false;
      analyticsService.addListener(() => notified = true);

      await analyticsService.acceptConsent();

      expect(analyticsService.showConsentBanner, isFalse);
      expect(analyticsService.isConsentGranted, isTrue);
      expect(notified, isTrue);
      verify(mockAnalytics.setAnalyticsCollectionEnabled(true)).called(1);
      verify(
        mockAnalytics.setConsent(analyticsStorageConsentGranted: true),
      ).called(1);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool(FirebaseAnalyticsService.consentPreferenceKey),
        isTrue,
      );
    },
  );

  test(
    'rejectConsent keeps analytics SDK disabled, consent denied, hides banner, and persists choice',
    () async {
      var notified = false;
      analyticsService.addListener(() => notified = true);

      await analyticsService.rejectConsent();

      expect(analyticsService.showConsentBanner, isFalse);
      expect(analyticsService.isConsentGranted, isFalse);
      expect(notified, isTrue);
      verify(mockAnalytics.setAnalyticsCollectionEnabled(false)).called(1);
      verify(
        mockAnalytics.setConsent(analyticsStorageConsentGranted: false),
      ).called(1);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool(FirebaseAnalyticsService.consentPreferenceKey),
        isFalse,
      );

      await analyticsService.logPresubmitPageOpen(
        repo: 'flutter',
        pr: '123',
        sha: 'abc',
      );
      verifyNever(
        mockAnalytics.logEvent(
          name: anyNamed('name'),
          parameters: anyNamed('parameters'),
        ),
      );
    },
  );

  test(
    'logPresubmitPageOpen logs event with parameters after Accept',
    () async {
      await analyticsService.acceptConsent();
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
    },
  );

  test('logRerunJob logs event with parameters after Accept', () async {
    await analyticsService.acceptConsent();
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

  test(
    'logRerunAllFailedJobs logs event with parameters after Accept',
    () async {
      await analyticsService.acceptConsent();
      await analyticsService.logRerunAllFailedJobs(repo: 'flutter', pr: '123');

      verify(
        mockAnalytics.logEvent(
          name: 'presubmit_rerun_failed_jobs',
          parameters: <String, Object>{'repo': 'flutter', 'pr': '123'},
        ),
      ).called(1);
    },
  );

  test(
    'logFilterDialogOpened logs event with parameters after Accept',
    () async {
      await analyticsService.acceptConsent();
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
    },
  );

  test('logViewLuciUi logs event with parameters after Accept', () async {
    await analyticsService.acceptConsent();
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

  test(
    'logAnalyzeLogsWithGemini logs event with parameters after Accept',
    () async {
      await analyticsService.acceptConsent();
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
    },
  );

  test('catches exceptions from underlying FirebaseAnalytics', () async {
    await analyticsService.acceptConsent();
    when(
      mockAnalytics.logEvent(
        name: anyNamed('name'),
        parameters: anyNamed('parameters'),
      ),
    ).thenThrow(Exception('analytics failure'));
    when(
      mockAnalytics.setConsent(
        analyticsStorageConsentGranted: anyNamed(
          'analyticsStorageConsentGranted',
        ),
      ),
    ).thenThrow(Exception('consent failure'));

    await expectLater(
      analyticsService.logPresubmitPageOpen(repo: 'flutter'),
      completes,
    );
    await expectLater(analyticsService.setDefaultConsent(), completes);
  });
}
