// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../service/firebase_analytics.dart';

/// Banner displayed at the bottom of the dashboard to request cookie consent
/// for Firebase Analytics.
class CookieConsentBanner extends StatelessWidget {
  const CookieConsentBanner({super.key, this.analyticsService});

  final FirebaseAnalyticsService? analyticsService;

  @override
  Widget build(BuildContext context) {
    final service =
        analyticsService ?? Provider.of<FirebaseAnalyticsService?>(context);
    if (service == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        if (!service.showConsentBanner) {
          return const SizedBox.shrink();
        }
        return Material(
          color: Colors.blueGrey.shade900,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'This site uses cookies from Google to deliver its services and to analyze traffic.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: service.rejectConsent,
                      child: const Text(
                        'Reject',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: service.acceptConsent,
                      child: const Text('Accept'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
