import 'package:auto_submit/validations/approval.dart';
import 'package:test/test.dart';

import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_graphql_client.dart';
import '../utilities/mocks.mocks.dart';

void main() {

  late Approval approval;
  late FakeConfig config;
  FakeGithubService githubService = FakeGithubService();
  late FakeGraphQLClient githubGraphQLClient;
  final MockGitHub gitHub = MockGitHub();

  setUp(() {
    githubGraphQLClient = FakeGraphQLClient();
    config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient, githubClient: gitHub);
    approval = Approval(config: config);
  });

  group('Approval group tests', () {
    
  });
}