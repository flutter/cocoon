// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

void main() {
//   test('Parse config from yaml', () {
//     const String sampleConfig = '''
//       default_branch: main
//       issues_repository:
//         owner: flutter
//         repo: flutter
//       auto_approval_accounts:
//         - dependabot[bot]
//         - dependabot
//         - DartDevtoolWorkflowBot
//       approving_reviews: 2
//       approval_group: flutter-hackers
//       run_ci: true
//       support_no_review_revert: true
//       required_checkruns:
//         - “ci.yaml validation”
//         - “Google-testing”
// ''';

//     final RepositoryConfiguration repositoryConfiguration = RepositoryConfiguration.fromYaml(sampleConfig);
//     expect(repositoryConfiguration.defaultBranch, 'main');
//     expect(repositoryConfiguration.issuesRepository, RepositorySlug('flutter', 'flutter'));
//     expect(repositoryConfiguration.autoApprovalAccounts!.isNotEmpty, isTrue);
//     expect(repositoryConfiguration.approvingReviews, 2);
//     expect(repositoryConfiguration.runCi, isTrue);
//     expect(repositoryConfiguration.supportNoReviewRevert, isTrue);
//     expect(repositoryConfiguration.requiredCheckRuns!.isNotEmpty, isTrue);
//   });

//   test('Parse config from yaml excluding auto approval accounts', () {
//     const String sampleConfig = '''
//       default_branch: main
//       issues_repository:
//         owner: flutter
//         repo: flutter
//       approving_reviews: 2
//       approval_group: flutter-hackers
//       run_ci: true
//       support_no_review_revert: true
//       required_checkruns:
//         - “ci.yaml validation”
//         - “Google-testing”
// ''';

//     final RepositoryConfiguration repositoryConfiguration = RepositoryConfiguration.fromYaml(sampleConfig);
//     expect(repositoryConfiguration.defaultBranch, 'main');
//     expect(repositoryConfiguration.issuesRepository, RepositorySlug('flutter', 'flutter'));
//     expect(repositoryConfiguration.autoApprovalAccounts!.isEmpty, isTrue);
//     expect(repositoryConfiguration.approvingReviews, 2);
//     expect(repositoryConfiguration.runCi, isTrue);
//     expect(repositoryConfiguration.supportNoReviewRevert, isTrue);
//     expect(repositoryConfiguration.requiredCheckRuns!.isNotEmpty, isTrue);
//   });

//   test('Parse config from yaml with empty auto_approval_accounts field', () {
//     const String sampleConfig = '''
//       default_branch: main
//       issues_repository:
//         owner: flutter
//         repo: flutter
//       auto_approval_accounts:
//       approving_reviews: 2
//       approval_group: flutter-hackers
//       run_ci: true
//       support_no_review_revert: true
//       required_checkruns:
//         - “ci.yaml validation”
//         - “Google-testing”
// ''';

//     final RepositoryConfiguration repositoryConfiguration = RepositoryConfiguration.fromYaml(sampleConfig);
//     expect(repositoryConfiguration.defaultBranch, 'main');
//     expect(repositoryConfiguration.issuesRepository, RepositorySlug('flutter', 'flutter'));
//     expect(repositoryConfiguration.autoApprovalAccounts!.isEmpty, isTrue);
//     expect(repositoryConfiguration.approvingReviews, 2);
//     expect(repositoryConfiguration.runCi, isTrue);
//     expect(repositoryConfiguration.supportNoReviewRevert, isTrue);
//     expect(repositoryConfiguration.requiredCheckRuns!.isNotEmpty, isTrue);
//   });

//   test('Parse minimal configuration', () {
//     const String sampleConfig = '''
//       default_branch: main
//       issues_repository:
//         owner: flutter
//         repo: flutter
// ''';

//     final RepositoryConfiguration repositoryConfiguration = RepositoryConfiguration.fromYaml(sampleConfig);
//     expect(repositoryConfiguration.defaultBranch, 'main');
//     expect(repositoryConfiguration.issuesRepository, RepositorySlug('flutter', 'flutter'));
//     expect(repositoryConfiguration.autoApprovalAccounts!.isEmpty, isTrue);
//     expect(repositoryConfiguration.approvingReviews, 2);
//     expect(repositoryConfiguration.runCi, isTrue);
//     expect(repositoryConfiguration.supportNoReviewRevert, isTrue);
//     expect(repositoryConfiguration.requiredCheckRuns!.isEmpty, isTrue);
//   });

  // test('Verify cache storage', () async {
  //   const String sampleConfig = '''
  //     default_branch: main
  //     issues_repository:
  //       owner: flutter
  //       repo: flutter
  //     auto_approval_accounts:
  //       - dependabot[bot]
  //       - dependabot
  //       - DartDevtoolWorkflowBot
  //     approving_reviews: 2
  //     approval_group: flutter-hackers
  //     run_ci: true
  //     support_no_review_revert: true
  //     required_checkruns:
  //       - “ci.yaml validation”
  //       - “Google-testing”
  //       ''';

  //   const String cacheKey = 'flutter/flutter/autosubmit.yaml';
  //   final CacheProvider cacheProvider = Cache.inMemoryCacheProvider(10);
  //   final Cache cache = Cache<dynamic>(cacheProvider).withPrefix('config');
  //   // Cache<RepositoryConfiguration>(cacheProvider).withTTL(Duration(seconds: 500));

  //   final RepositoryConfigurationManager repositoryConfigurationManager = RepositoryConfigurationManager(cache);

  //   final RepositoryConfiguration repositoryConfiguration = repositoryConfigurationManager.fromYaml(sampleConfig);

  //   final String yml = repositoryConfigurationManager.toYaml(repositoryConfiguration);
  //   print(yml);

  //   print(repositoryConfiguration.defaultBranch);

  //   final value = await cache[cacheKey].get();
  //   expect(value, isNull);
  //   final setValue = await cache[cacheKey].set(sampleConfig.codeUnits, const Duration(minutes: 10));
  //   print(setValue);
  //   String strSetValue = String.fromCharCodes(setValue);
  //   print(strSetValue);
  // });
}
