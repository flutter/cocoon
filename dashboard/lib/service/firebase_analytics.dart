// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Service class for logging analytics events to Firebase Analytics.
///
/// Operations with the plugin are caught to prevent analytics errors from
/// crashing the application.
class FirebaseAnalyticsService {
  FirebaseAnalyticsService({FirebaseAnalytics? analytics})
    : _analytics = analytics;

  final FirebaseAnalytics? _analytics;

  Future<void> logPresubmitPageOpen({
    required String repo,
    String? pr,
    String? sha,
  }) async {
    await _logEvent(
      name: 'presubmit_page_open',
      parameters: <String, Object>{'repo': repo, 'pr': ?pr, 'sha': ?sha},
    );
  }

  Future<void> logRerunJob({
    required String repo,
    String? pr,
    required String jobName,
  }) async {
    await _logEvent(
      name: 'presubmit_rerun_job',
      parameters: <String, Object>{
        'repo': repo,
        'pr': ?pr,
        'job_name': jobName,
      },
    );
  }

  Future<void> logRerunAllFailedJobs({required String repo, String? pr}) async {
    await _logEvent(
      name: 'presubmit_rerun_failed_jobs',
      parameters: <String, Object>{'repo': repo, 'pr': ?pr},
    );
  }

  Future<void> logFilterDialogOpened({
    required String repo,
    String? pr,
    String? sha,
  }) async {
    await _logEvent(
      name: 'presubmit_filter_dialog',
      parameters: <String, Object>{'repo': repo, 'pr': ?pr, 'sha': ?sha},
    );
  }

  Future<void> logViewLuciUi({
    required String repo,
    String? pr,
    required String jobName,
    required int buildNumber,
  }) async {
    await _logEvent(
      name: 'presubmit_view_luci_ui',
      parameters: <String, Object>{
        'repo': repo,
        'pr': ?pr,
        'job_name': jobName,
        'build_number': buildNumber,
      },
    );
  }

  Future<void> logAnalyzeLogsWithGemini({
    required String repo,
    String? pr,
    required String jobName,
    String? buildId,
  }) async {
    await _logEvent(
      name: 'presubmit_analyze_logs_gemini',
      parameters: <String, Object>{
        'repo': repo,
        'pr': ?pr,
        'job_name': jobName,
        'build_id': ?buildId,
      },
    );
  }

  Future<void> _logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      final analytics =
          _analytics ??
          (Firebase.apps.isNotEmpty ? FirebaseAnalytics.instance : null);
      await analytics?.logEvent(name: name, parameters: parameters);
    } catch (error) {
      debugPrint('analytics logEvent ($name) failed: $error');
    }
  }
}
