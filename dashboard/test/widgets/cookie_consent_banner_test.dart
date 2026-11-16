// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_dashboard/service/firebase_analytics.dart';
import 'package:flutter_dashboard/widgets/cookie_consent_banner.dart';
import 'package:flutter_dashboard/widgets/state_provider.dart';
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

  testWidgets('CookieConsentBanner grants consent and hides on Accept', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      StateProvider(
        analyticsService: analyticsService,
        child: const MaterialApp(home: Scaffold(body: CookieConsentBanner())),
      ),
    );

    expect(
      find.text(
        'This site uses cookies from Google to deliver its services and to analyze traffic.',
      ),
      findsOneWidget,
    );
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(analyticsService.isConsentGranted, isTrue);
    verify(mockAnalytics.setAnalyticsCollectionEnabled(true)).called(1);
    verify(
      mockAnalytics.setConsent(analyticsStorageConsentGranted: true),
    ).called(1);
    expect(find.text('Accept'), findsNothing);
    expect(find.text('Reject'), findsNothing);
  });

  testWidgets('CookieConsentBanner denies consent and hides on Reject', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      StateProvider(
        analyticsService: analyticsService,
        child: const MaterialApp(home: Scaffold(body: CookieConsentBanner())),
      ),
    );

    expect(find.text('Reject'), findsOneWidget);

    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();

    expect(analyticsService.isConsentGranted, isFalse);
    verify(mockAnalytics.setAnalyticsCollectionEnabled(false)).called(1);
    verify(
      mockAnalytics.setConsent(analyticsStorageConsentGranted: false),
    ).called(1);
    expect(find.text('Accept'), findsNothing);
    expect(find.text('Reject'), findsNothing);
  });
}
