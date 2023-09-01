// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/github_build_status_update.dart';
import 'package:cocoon_service/src/request_handlers/publish_tree_status_to_discord.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

import '../src/bigquery/fake_tabledata_resource.dart';
import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/service/fake_build_status_provider.dart';
import '../src/service/fake_github_service.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

class MockNyxx extends Mock implements INyxx, INyxxWebsocket {}

void main() {
  group('PushStatusToDiscord', () {
    late FakeBuildStatusService buildStatusService;
    late FakeClientContext clientContext;
    late FakeConfig config;
    late FakeDatastoreDB db;
    late ApiRequestHandlerTester tester;
    late FakeAuthenticatedContext authContext;
    late FakeTabledataResource tabledataResourceApi;
    late PublishTreeStatusToDiscord handler;
    late MockGitHub github;
    late MockPullRequestsService pullRequestsService;
    //late MockRepositoriesService repositoriesService;
    late FakeGithubService githubService;

    GithubBuildStatusUpdate newStatusUpdate(PullRequest pr, BuildStatus status) {
      return GithubBuildStatusUpdate(
        key: db.emptyKey.append(GithubBuildStatusUpdate, id: pr.number),
        repository: Config.flutterSlug.fullName,
        status: status.githubStatus,
        pr: pr.number!,
        head: pr.head!.sha,
        updates: 0,
      );
    }

    setUp(() async {
      clientContext = FakeClientContext();
      authContext = FakeAuthenticatedContext(clientContext: clientContext);
      clientContext.isDevelopmentEnvironment = false;
      buildStatusService = FakeBuildStatusService();
      githubService = FakeGithubService();
      tabledataResourceApi = FakeTabledataResource();
      db = FakeDatastoreDB();
      github = MockGitHub();
      pullRequestsService = MockPullRequestsService();
      //repositoriesService = MockRepositoriesService();
      config = FakeConfig(
        tabledataResource: tabledataResourceApi,
        githubService: githubService,
        dbValue: db,
        githubClient: github,
      );
      tester = ApiRequestHandlerTester(context: authContext);
      handler = PublishTreeStatusToDiscord(
        config: config,
        authenticationProvider: FakeAuthenticationProvider(clientContext: clientContext),
        buildStatusServiceProvider: (_) => buildStatusService,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
      );
      when(github.pullRequests).thenReturn(pullRequestsService);
    });

    test('development environment does nothing', () async {
      clientContext.isDevelopmentEnvironment = true;
      config.githubClient = ThrowingGitHub();
      db.onCommit = (List<Model<dynamic>> insert, List<Key<dynamic>> deletes) => throw AssertionError();
      db.addOnQuery<GithubBuildStatusUpdate>((Iterable<GithubBuildStatusUpdate> results) {
        throw AssertionError();
      });
      final Body body = await tester.get<Body>(handler);
      expect(body, same(Body.empty));
    });

    // group('does not update anything', () {
    //   setUp(() {
    //     db.onCommit = (List<Model<dynamic>> insert, List<Key<dynamic>> deletes) => throw AssertionError();
    //     when(repositoriesService.createStatus(any, any, any)).thenThrow(AssertionError());
    //     when(NyxxFactory.createNyxxWebsocket('', 0)).thenReturn(MockNyxx() as INyxxWebsocket);
    //   });

    //   // test('if status has not changed since last update', () async {
    //   //   final PullRequest pr = generatePullRequest(id: 1, sha: '1');
    //   //   when(pullRequestsService.list(any, base: anyNamed('base'))).thenAnswer((_) => Stream<PullRequest>.value(pr));
    //   //   buildStatusService.cumulativeStatus = BuildStatus.success();
    //   //   final GithubBuildStatusUpdate status = newStatusUpdate(pr, BuildStatus.success());
    //   //   db.values[status.key] = status;
    //   //   final Body body = await tester.get<Body>(handler);
    //   //   expect(body, same(Body.empty));
    //   //   verifyNever(
    //   //     handler.sendMessageToDiscord(
    //   //       PublishTreeStatusToDiscord.kChanIdTestChannel,
    //   //       'flutter/flutter went GREEN',
    //   //     ),
    //   //   ).called(0);
    //   // });
    // });

    test('publish if status has changed since last update', () async {
      final PullRequest pr = generatePullRequest(id: 1, sha: '1');
      final bot = MockNyxx();
      when(pullRequestsService.list(any, base: anyNamed('base'))).thenAnswer((_) => Stream<PullRequest>.value(pr));
      buildStatusService.cumulativeStatus = BuildStatus.success();
      newStatusUpdate(pr, BuildStatus.failure(const <String>['failed_test_1']));
      final Body body = await tester.get<Body>(handler);
      expect(body, same(Body.empty));

      //when(bot.httpEndpoints.sendMessage(Snowflake(PublishTreeStatusToDiscord.kChanIdTestChannel), MessageBuilder()));
      //verify(handler.sendMessageToDiscord).called(1);
      verify(
        bot.httpEndpoints.sendMessage(
          Snowflake(PublishTreeStatusToDiscord.kChanIdTestChannel),
          MessageBuilder.content('flutter/flutter went GREEN'),
        ),
      ).called(1);
    });
  });
}
