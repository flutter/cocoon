// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/service/firestore.dart';

import 'package:googleapis/firestore/v1.dart';
import 'package:test/test.dart';

import '../src/utilities/entity_generators.dart';

void main() {
  test('creates task documents correctly from targets', () async {
    final Commit commit = generateCommit(1);
    final List<Target> targets = <Target>[
      generateTarget(1, platform: 'Mac'),
      generateTarget(2, platform: 'Linux'),
    ];
    final List<Document> taskDocuments = targetsToTaskDocuments(commit, targets);
    expect(taskDocuments.length, 2);
    expect(taskDocuments[0].name, '$kDatabase/documents/$kTaskCollectionId/${commit.sha}_${targets[0].value.name}_1');
    expect(taskDocuments[0].fields![kTaskCreateTimestampField]!.integerValue, commit.timestamp.toString());
    expect(taskDocuments[0].fields![kTaskEndTimestampField]!.integerValue, '0');
    expect(taskDocuments[0].fields![kTaskBringupField]!.booleanValue, false);
    expect(taskDocuments[0].fields![kTaskNameField]!.stringValue, targets[0].value.name);
    expect(taskDocuments[0].fields![kTaskStartTimestampField]!.integerValue, '0');
    expect(taskDocuments[0].fields![kTaskStatusField]!.stringValue, Task.statusNew);
    expect(taskDocuments[0].fields![kTaskTestFlakyField]!.booleanValue, false);
    expect(taskDocuments[0].fields![kTaskCommitShaField]!.stringValue, commit.sha);
  });

  test('creates commit document correctly from commit data model', () async {
    final Commit commit = generateCommit(1);
    final Document commitDocument = commitToCommitDocument(commit);
    expect(commitDocument.name, '$kDatabase/documents/$kCommitCollectionId/${commit.sha}');
    expect(commitDocument.fields![kCommitAvatarField]!.stringValue, commit.authorAvatarUrl);
    expect(commitDocument.fields![kCommitBranchField]!.stringValue, commit.branch);
    expect(commitDocument.fields![kCommitCreateTimestampField]!.integerValue, commit.timestamp.toString());
    expect(commitDocument.fields![kCommitAuthorField]!.stringValue, commit.author);
    expect(commitDocument.fields![kCommitMessageField]!.stringValue, commit.message);
    expect(commitDocument.fields![kCommitRepositoryPathField]!.stringValue, commit.repository);
    expect(commitDocument.fields![kCommitShaField]!.stringValue, commit.sha);
  });

  test('creates writes correctly from documents', () async {
    final List<Document> documents = <Document>[
      Document(name: 'd1', fields: <String, Value>{'key1': Value(stringValue: 'value1')}),
      Document(name: 'd2', fields: <String, Value>{'key1': Value(stringValue: 'value2')}),
    ];
    final List<Write> writes = documentsToWrites(documents);
    expect(writes.length, documents.length);
    expect(writes[0].update, documents[0]);
    expect(writes[0].currentDocument!.exists, false);
  });
}
