// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

/// Service class for logging analytics events to Firebase Analytics.
///
/// Operations with the plugin are caught to prevent analytics errors from
/// crashing the application.
class FirebaseAnalyticsService extends ChangeNotifier {
  FirebaseAnalyticsService({
    FirebaseAnalytics? analytics,
    SharedPreferences? preferences,
  }) : _analytics = analytics,
       _preferences = preferences;

  static const String consentPreferenceKey = 'analytics_consent_granted';

  final FirebaseAnalytics? _analytics;
  SharedPreferences? _preferences;

  bool _showConsentBanner = true;
  bool _consentGranted = false;

  /// Whether the cookie consent banner should be displayed to the user.
  bool get showConsentBanner => _showConsentBanner;

  /// Whether the user has explicitly granted analytics consent.
  bool get isConsentGranted => _consentGranted;

  Future<SharedPreferences> _getPreferences() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  /// Loads any persisted consent decision, or sets the default consent state
  /// to 'denied' and disables the analytics SDK when the app first loads.
  ///
  /// This ensures no analytics telemetry or cookies are collected before the
  /// user explicitly clicks "Accept".
  Future<void> setDefaultConsent() async {
    bool? storedConsent;
    try {
      final prefs = await _getPreferences();
      storedConsent = prefs.getBool(consentPreferenceKey);
    } catch (error) {
      debugPrint('analytics failed to read consent preference: $error');
    }

    if (storedConsent != null) {
      _showConsentBanner = false;
      notifyListeners();
      await setConsent(analyticsStorageConsentGranted: storedConsent);
    } else {
      await setConsent(analyticsStorageConsentGranted: false);
    }
  }

  /// Enables the analytics SDK and data collection after the user explicitly
  /// clicks "Accept", and persists the choice.
  Future<void> acceptConsent() async {
    _showConsentBanner = false;
    notifyListeners();
    await _saveConsentPreference(true);
    await setConsent(analyticsStorageConsentGranted: true);
  }

  /// Keeps the analytics SDK disabled and consent denied after the user clicks
  /// "Reject", and persists the choice.
  Future<void> rejectConsent() async {
    _showConsentBanner = false;
    notifyListeners();
    await _saveConsentPreference(false);
    await setConsent(analyticsStorageConsentGranted: false);
  }

  Future<void> _saveConsentPreference(bool granted) async {
    try {
      final prefs = await _getPreferences();
      await prefs.setBool(consentPreferenceKey, granted);
    } catch (error) {
      debugPrint('analytics failed to save consent preference: $error');
    }
  }

  /// Updates the Firebase Analytics consent state and enables or disables the
  /// analytics SDK accordingly.
  Future<void> setConsent({
    required bool analyticsStorageConsentGranted,
  }) async {
    _consentGranted = analyticsStorageConsentGranted;
    try {
      final analytics =
          _analytics ??
          (Firebase.apps.isNotEmpty ? FirebaseAnalytics.instance : null);
      await analytics?.setAnalyticsCollectionEnabled(
        analyticsStorageConsentGranted,
      );
      await analytics?.setConsent(
        analyticsStorageConsentGranted: analyticsStorageConsentGranted,
      );
    } catch (error) {
      debugPrint('analytics setConsent failed: $error');
    }
  }

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
    if (!_consentGranted) {
      return;
    }
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
