import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/configuration/repository_configuration_manager.dart';
import 'package:github/github.dart';
import 'package:neat_cache/cache_provider.dart';
import 'package:neat_cache/neat_cache.dart';
import 'package:test/test.dart';

import '../src/service/fake_github_service.dart';

void main() {
  late RepositoryConfigurationManager repositoryConfigurationManager;
  late CacheProvider cacheProvider;
  late Cache cache;

  late FakeGithubService githubService;

  setUp(() {
    cacheProvider = Cache.inMemoryCacheProvider(5);
    cache = Cache<dynamic>(cacheProvider).withPrefix('config');
    repositoryConfigurationManager = RepositoryConfigurationManager(cache);
    githubService = FakeGithubService();
  });

  test('Verify cache storage', () async {
    const String sampleConfig = '''
      default_branch: main
      issues_repository:
        owner: flutter
        repo: flutter
      auto_approval_accounts:
        - dependabot[bot]
        - dependabot
        - DartDevtoolWorkflowBot
      approving_reviews: 2
      approval_group: flutter-hackers
      run_ci: true
      support_no_review_revert: true
      required_checkruns:
        - “ci.yaml validation”
        - “Google-testing”
        ''';

    githubService.fileContentsMock = sampleConfig;
    final RepositoryConfiguration repositoryConfiguration =
        await repositoryConfigurationManager.readRepositoryConfiguration(
      githubService,
      RepositorySlug(
        'flutter',
        'flutter',
      ),
    );

    expect(repositoryConfiguration.defaultBranch, 'main');
    expect(repositoryConfiguration.issuesRepository.fullName, 'flutter/flutter');
    expect(repositoryConfiguration.autoApprovalAccounts.isNotEmpty, isTrue);
    expect(repositoryConfiguration.autoApprovalAccounts.length, 3);
    expect(repositoryConfiguration.approvingReviews, 2);
    expect(repositoryConfiguration.approvalGroup, 'flutter-hackers');
    expect(repositoryConfiguration.runCi, isTrue);
    expect(repositoryConfiguration.supportNoReviewReverts, isTrue);
    expect(repositoryConfiguration.requiredCheckRuns.isNotEmpty, isTrue);
    expect(repositoryConfiguration.requiredCheckRuns.length, 2);
  });
}
