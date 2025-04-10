// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' if (kIsWeb) '';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'build_dashboard_page.dart';
import 'firebase_options.dart';
import 'service/cocoon.dart';
import 'service/google_authentication.dart';
import 'src/pages/v2_landing_page.dart';
import 'state/build.dart';
import 'widgets/now.dart';
import 'widgets/state_provider.dart';
import 'widgets/task_box.dart';

void usage() {
  // ignore: avoid_print
  print('''
Usage: cocoon [--use-production-service | --no-use-production-service]

  --[no-]use-production-service  Enable/disable using the production Cocoon
                                 service for source data. Defaults to the
                                 production service in a release build, and the
                                 fake service in a debug build.
''');
}

void main([List<String> args = const <String>[]]) async {
  var useProductionService = kReleaseMode;
  if (args.contains('--help')) {
    usage();
    if (!kIsWeb) {
      exit(0);
    }
  }
  if (args.contains('--use-production-service')) {
    useProductionService = true;
  }
  if (args.contains('--no-use-production-service')) {
    useProductionService = false;
  }
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kReleaseMode) {
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  final authService = GoogleSignInService();
  final cocoonService = CocoonService(
    useProductionService: useProductionService,
  );
  runApp(
    StateProvider(
      signInService: authService,
      buildState: BuildState(
        authService: authService,
        cocoonService: cocoonService,
      ),
      child: Now(child: const MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return TaskBox(
      child: MaterialApp(
        title: 'Flutter Build Dashboard — Cocoon',
        shortcuts: {
          ...WidgetsApp.defaultShortcuts,
          const SingleActivator(LogicalKeyboardKey.select):
              const ActivateIntent(),
        },
        theme: ThemeData(
          useMaterial3: false,
          primaryTextTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black87),
          ),
        ),
        darkTheme: ThemeData.dark(),

        // The default page is the build dashboard.
        initialRoute: BuildDashboardPage.routeName,
        routes: {
          BuildDashboardPage.routeName: (_) => const BuildDashboardPage(),
        },

        // dashboard.com/x/flutter/flutter/presubmit
        // jonahwilliams@ [1234] > .../1234
        // matanlurey@    [4568] > .../4567
        //
        // dashboard.com/x/flutter/flutter/presubmit/1234
        onGenerateRoute: (RouteSettings settings) {
          final uriData = Uri.parse(settings.name!);
          if (uriData.pathSegments.isEmpty) {
            return null;
          }

          switch (uriData.pathSegments.first) {
            case BuildDashboardPage.routeName:
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (BuildContext context) {
                  return BuildDashboardPage(
                    queryParameters: uriData.queryParameters,
                  );
                },
              );
            case 'v2':
              if (_findV2Route(uriData) case final builder?) {
                return MaterialPageRoute<void>(
                  builder: builder,
                  settings: settings,
                );
              }
          }
          return null;
        },
      ),
    );
  }

  WidgetBuilder? _findV2Route(Uri route) {
    if (route.pathSegments.isEmpty || route.pathSegments.first != 'v2') {
      throw ArgumentError.value(route, 'route', 'not a v2 route');
    }

    final [_, ...v2PathSegments] = route.pathSegments;
    if (v2PathSegments.isEmpty) {
      return (_) => const V2LandingPage();
    }

    final [repoOwner, ...] = v2PathSegments;
    if (v2PathSegments.length == 1) {
      return (_) => V2LandingPage(repoOwner);
    }

    final [_, repoName, ...] = v2PathSegments;
    if (v2PathSegments.length == 2) {
      return (_) => V2LandingPage(repoOwner, repoName);
    }

    return null;
  }
}
