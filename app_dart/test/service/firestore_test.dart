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
    expect(taskDocuments[0].name, '$kDatabase/documents/tasks/${commit.sha}_${targets[0].value.name}_1');
    expect(taskDocuments[0].fields!['builderNumber']!.integerValue, null);
    expect(taskDocuments[0].fields!['createTimestamp']!.integerValue, commit.timestamp.toString());
    expect(taskDocuments[0].fields!['endTimestamp']!.integerValue, '0');
    expect(taskDocuments[0].fields!['bringup']!.booleanValue, false);
    expect(taskDocuments[0].fields!['name']!.stringValue, targets[0].value.name);
    expect(taskDocuments[0].fields!['startTimestamp']!.integerValue, '0');
    expect(taskDocuments[0].fields!['status']!.stringValue, Task.statusNew);
    expect(taskDocuments[0].fields!['testFlaky']!.booleanValue, false);
    expect(taskDocuments[0].fields!['commitSha']!.stringValue, commit.sha);
  });

  test('creates commit document correctly from commit data model', () async {
    final Commit commit = generateCommit(1);
    final Document commitDocument = commitToCommitDocument(commit);
    expect(commitDocument.name, '$kDatabase/documents/commits/${commit.sha}');
    expect(commitDocument.fields!['avatar']!.stringValue, commit.authorAvatarUrl);
    expect(commitDocument.fields!['branch']!.stringValue, commit.branch);
    expect(commitDocument.fields!['createTimestamp']!.integerValue, commit.timestamp.toString());
    expect(commitDocument.fields!['author']!.stringValue, commit.author);
    expect(commitDocument.fields!['message']!.stringValue, commit.message);
    expect(commitDocument.fields!['repositoryPath']!.stringValue, commit.repository);
    expect(commitDocument.fields!['sha']!.stringValue, commit.sha);
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
