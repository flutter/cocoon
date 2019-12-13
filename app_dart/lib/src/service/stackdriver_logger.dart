// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:googleapis/logging/v2.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';

/// Service class for interacting with the AppEngine project's stackdriver logging service.
///
/// Stackdriver is a Google Cloud service for monitoring and managing services.
/// https://cloud.google.com/stackdriver/ for more details.
///
/// A service account with permission for `logging.logEntries.write` is necessary
/// to write logs to Stackdriver.
///
/// The logs are located at:
/// See https://console.cloud.google.com/logs/viewer?project=flutter-dashboard&logName=projects%2Fflutter-dashboard%2Flogs%2F[encoded task key]_[attempt number]
class StackdriverLoggerService {
  /// Creates a new [StackdriverLoggerService].
  ///
  /// The [config] argument must not be null.
  StackdriverLoggerService({@required this.config}) : assert(config != null);

  /// The Cocoon configuration. Guaranteed to be non-null.
  final Config config;

  /// Interface to interacting with Stackdriver.
  LoggingApi _api;

  /// This is the location Stackdriver requires the logs be put at. Do not change.
  static const String logPath = 'projects/flutter-dashboard/logs';

  Future<void> create() async {
    _api = LoggingApi(await stackdriverHttpClient());
  }

  /// Stackdriver needs a HttpClient that has service account credentials
  /// with authorization to write logs.
  Future<Client> stackdriverHttpClient() async {
    return clientViaServiceAccount(
      await config.taskLogServiceAccount,
      const <String>[
        'https://www.googleapis.com/auth/logging.write',
      ],
    );
  }

  /// Write [lines] to Stackdriver under the log [logName].
  ///
  /// These logs are considered global since they should not be tied to any services
  /// in the Google Cloud project.
  ///
  // TODO(chillers): Stackdriver only supports UTF8 characters. https://github.com/flutter/flutter/issues/46899
  Future<void> writeLines(String logName, List<String> lines) async {
    if (_api == null) {
      await create();
    }

    final WriteLogEntriesRequest logRequest = WriteLogEntriesRequest()
      ..entries =
          lines.map((String line) => LogEntry()..textPayload = line).toList()
      ..logName = '$logPath/$logName'
      ..resource = (MonitoredResource()..type = 'global');

    await _api.entries.write(logRequest);
  }
}
