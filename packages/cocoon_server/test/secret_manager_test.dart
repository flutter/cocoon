// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@GenerateNiceMocks([
  MockSpec<g.AccessSecretVersionResponse>(),
  MockSpec<g.SecretPayload>(),
  MockSpec<g.SecretManagerApi>(),
  MockSpec<g.ProjectsResource>(),
  MockSpec<g.ProjectsSecretsResource>(),
  MockSpec<g.ProjectsSecretsVersionsResource>(),
])
import 'package:cocoon_server/secret_manager.dart';
import 'package:googleapis/secretmanager/v1.dart' as g;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'secret_manager_test.mocks.dart';

void main() {
  late g.ProjectsSecretsVersionsResource resource;
  late final g.SecretManagerApi api;

  setUp(() {
    resource = MockProjectsSecretsVersionsResource();
  });

  setUpAll(() {
    final mockSecrets = MockProjectsSecretsResource();
    when(mockSecrets.versions).thenAnswer((_) => resource);

    final mockProjects = MockProjectsResource();
    when(mockProjects.secrets).thenReturn(mockSecrets);

    final mockApi = MockSecretManagerApi();
    when(mockApi.projects).thenReturn(mockProjects);

    api = mockApi;
  });

  test('finds a payload', () async {
    final payload = MockSecretPayload();
    when(payload.dataAsBytes).thenReturn('World'.codeUnits);

    final response = MockAccessSecretVersionResponse();
    when(response.payload).thenReturn(payload);

    when(
      resource.access('projects/my-project/secrets/Hello/versions/latest'),
    ).thenAnswer((_) async => response);

    final manager = SecretManager.fromGoogleCloud(api, projectId: 'my-project');
    await expectLater(manager.tryGetString('Hello'), completion('World'));
  });

  test('handles a missing payload', () async {
    final response = MockAccessSecretVersionResponse();
    when(response.payload).thenReturn(null);

    when(
      resource.access('projects/my-project/secrets/Hello/versions/latest'),
    ).thenAnswer((_) async => response);

    final manager = SecretManager.fromGoogleCloud(api, projectId: 'my-project');
    await expectLater(manager.tryGetString('Hello'), completion(isNull));
  });
}
