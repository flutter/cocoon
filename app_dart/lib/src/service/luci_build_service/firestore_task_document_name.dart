// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:meta/meta.dart';

/// Represents the [documentName] of a Firestore document.
@immutable
final class FirestoreTaskDocumentName {
  FirestoreTaskDocumentName({
    required this.commitSha,
    required this.taskName,
    required this.currentAttempt,
  }) {
    if (currentAttempt < 1) {
      throw RangeError.value(
        currentAttempt,
        'currentAttempt',
        'Must be at least 1',
      );
    }
  }

  /// Parse the inverse of [FirestoreTaskDocumentName.documentName].
  factory FirestoreTaskDocumentName.parse(String documentName) {
    final result = tryParse(documentName);
    if (result == null) {
      throw FormatException(
        'Unexpected firestore task document name',
        documentName,
      );
    }
    return result;
  }

  /// Tries to parse the inverse of [FirestoreTaskDocumentName.documentName].
  ///
  /// If could not be parsed, returns `null`.
  static FirestoreTaskDocumentName? tryParse(String documentName) {
    if (_parseDocumentName.matchAsPrefix(documentName) case final match?) {
      final commitSha = match.group(1)!;
      final taskName = match.group(2)!;
      final currentAttempt = int.tryParse(match.group(3)!);
      if (currentAttempt != null) {
        return FirestoreTaskDocumentName(
          commitSha: commitSha,
          taskName: taskName,
          currentAttempt: currentAttempt,
        );
      }
    }
    return null;
  }

  /// Parses `{commitSha}_{taskName}_{currentAttempt}`.
  ///
  /// This is gross because the [taskName] could also include underscores.
  static final _parseDocumentName = RegExp(
    r'([^_]*)_((?:[^_]+_)*[^_]+)_([^_]*)',
  );

  /// The commit SHA of the code being built.
  final String commitSha;

  /// The task name (i.e. from `.ci.yaml`).
  final String taskName;

  /// Which run (or re-run) attempt, starting at 1, this is.
  final int currentAttempt;

  @override
  int get hashCode => Object.hash(commitSha, taskName, currentAttempt);

  @override
  bool operator ==(Object other) {
    return other is FirestoreTaskDocumentName &&
        commitSha == other.commitSha &&
        taskName == other.taskName &&
        currentAttempt == other.currentAttempt;
  }

  /// The name as stored in Firestore.
  String get documentName => '${commitSha}_${taskName}_$currentAttempt';

  @override
  String toString() {
    return 'FirestoreTaskDocumentName ${const JsonEncoder.withIndent('  ').convert({'commitSha': commitSha, 'taskName': taskName, 'currentAttempt': currentAttempt})}';
  }
}
