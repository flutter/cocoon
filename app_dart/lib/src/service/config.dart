// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:corsac_jwt/corsac_jwt.dart';
import 'package:gcloud/db.dart';
import 'package:gcloud/service_scope.dart' as ss;
import 'package:github/github.dart' as gh;
import 'package:googleapis/bigquery/v2.dart';
import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:retry/retry.dart';

import '../../cocoon_service.dart';
import '../model/appengine/branch.dart';
import '../model/appengine/cocoon_config.dart';
import '../model/appengine/key_helper.dart';
import 'access_client_provider.dart';
import 'bigquery.dart';
import 'github_service.dart';
import 'logging.dart';

/// Name of the default git branch.
const String kDefaultBranchName = 'master';

class Config {
  Config(this._db, this._cache);

  final DatastoreDB _db;

  final CacheService _cache;

  /// List of Github presubmit supported repos.
  ///
  /// This adds support for the `waiting for tree to go green label` to the repo.
  ///
  /// Relies on the GitHub Checks API being enabled for this repo.
  Set<gh.RepositorySlug> get supportedRepos => <gh.RepositorySlug>{
        cocoonSlug,
        engineSlug,
        flutterSlug,
        packagesSlug,
      };

  /// List of guaranteed scheduling Github repos.
  static Set<gh.RepositorySlug> get guaranteedSchedulingRepos => <gh.RepositorySlug>{
        engineSlug,
        packagesSlug,
      };

  /// List of Github postsubmit supported repos.
  ///
  /// This adds support for check runs to the repo.
  Set<gh.RepositorySlug> get postsubmitSupportedRepos => <gh.RepositorySlug>{
        packagesSlug,
      };

  /// List of Cirrus supported repos.
  static Set<String> cirrusSupportedRepos = <String>{'packages', 'flutter'};

  /// GitHub repositories that use CI status to determine if pull requests can be submitted.
  static Set<gh.RepositorySlug> reposWithTreeStatus = <gh.RepositorySlug>{
    engineSlug,
    flutterSlug,
  };

  /// The tip of tree branch for [slug].
  static String defaultBranch(gh.RepositorySlug slug) {
    final Map<gh.RepositorySlug, String> defaultBranches = <gh.RepositorySlug, String>{
      cocoonSlug: 'main',
      flutterSlug: 'master',
      engineSlug: 'main',
      packagesSlug: 'main',
      recipesSlug: 'main',
    };

    return defaultBranches[slug] ?? kDefaultBranchName;
  }

  /// Memorystore subcache name to store [CocoonConfig] values in.
  static const String configCacheName = 'config';

  /// Default properties when rerunning a prod build.
  static const Map<String, Object> defaultProperties = <String, Object>{'force_upload': true};

  @visibleForTesting
  static const Duration configCacheTtl = Duration(hours: 12);

  Logging get loggingService => ss.lookup(#appengine.logging) as Logging;

  Future<Iterable<Branch>> getBranches(gh.RepositorySlug slug) async {
    final DatastoreService datastore = DatastoreService(db, defaultMaxEntityGroups);
    final List<Branch> branches = await (datastore.queryBranches().toList());

    return branches.where((Branch branch) => branch.slug == slug);
  }

  Future<List<String>> _getReleaseAccounts() async {
    final String releaseAccountsConcat = await _getSingleValue('ReleaseAccounts');
    return releaseAccountsConcat.split(',');
  }

  Future<String> _getSingleValue(String id) async {
    final Uint8List? cacheValue = await _cache.getOrCreate(
      configCacheName,
      id,
      createFn: () => _getValueFromDatastore(id),
      ttl: configCacheTtl,
    );

    return String.fromCharCodes(cacheValue!);
  }

  Future<Uint8List> _getValueFromDatastore(String id) async {
    final CocoonConfig cocoonConfig = CocoonConfig()
      ..id = id
      ..parentKey = _db.emptyKey;
    final CocoonConfig result = await _db.lookupValue<CocoonConfig>(cocoonConfig.key);

    return Uint8List.fromList(result.value.codeUnits);
  }

  // GitHub App properties.
  Future<String> get githubPrivateKey => _getSingleValue('githubapp_private_pem');
  Future<String> get overrideTreeStatusLabel => _getSingleValue('override_tree_status_label');
  Future<String> get githubPublicKey => _getSingleValue('githubapp_public_pem');
  Future<String> get githubAppId => _getSingleValue('githubapp_id');
  Future<Map<String, dynamic>> get githubAppInstallations async {
    final String installations = await _getSingleValue('githubapp_installations');
    return jsonDecode(installations) as Map<String, dynamic>;
  }

  // Default recipe bundle used when the PR's base branch name does not exist in
  // the recipes GoB project.
  String get defaultRecipeBundleRef => 'refs/heads/main';

  DatastoreDB get db => _db;

  /// Size of the shards to send to buildBucket when scheduling builds.
  int get schedulingShardSize => 5;

  /// Batch size of builds to schedule in each swarming request.
  int get batchSize => 5;

  /// Upper limit of targets to be backfilled in API call.
  ///
  /// For example, if we have 200 available targets found to be backfilled,
  /// only `backfillerTargetLimit` will be scheduled whereas others wait for
  /// the next API call.
  int get backfillerTargetLimit => 50;

  /// Upper limit of commit rows to be backfilled in API call.
  ///
  /// This limits the number of commits to be checked to backfill. When bots
  /// are idle, we hope to scan as many commit rows as possible.
  int get backfillerCommitLimit => 50;

  /// Upper limit of issue/PRs allowed each API call.
  ///
  /// GitHub enforces a secondary rate limit on frequency API calls. This causes
  /// our API failure when many issues/PRs are created in a short time.
  int get issueAndPRLimit => 2;

  /// Max retries when scheduling builds.
  static const RetryOptions schedulerRetry = RetryOptions(maxAttempts: 3);

  /// List of GitHub accounts related to releases.
  Future<List<String>> get releaseAccounts => _getReleaseAccounts();

  Future<String> get oauthClientId => _getSingleValue('OAuthClientId');

  Future<String> get githubOAuthToken => _getSingleValue('GitHubPRToken');

  String get wrongBaseBranchPullRequestMessage => 'This pull request was opened against a branch other than '
      '_{{default_branch}}_. Since Flutter pull requests should not '
      'normally be opened against branches other than {{default_branch}}, I '
      'have changed the base to {{default_branch}}. If this was intended, you '
      'may modify the base back to {{target_branch}}. See the [Release Process]'
      '(https://github.com/flutter/flutter/wiki/Release-process) for information '
      'about how other branches get updated.\n\n'
      '__Reviewers__: Use caution before merging pull requests to branches other '
      'than {{default_branch}}, unless this is an intentional hotfix/cherrypick.';

  String wrongHeadBranchPullRequestMessage(String branch) =>
      'This pull request is trying merge the branch $branch, which is the name '
      'of a release branch. This is usually a mistake. See '
      '[Tree Hygiene](https://github.com/flutter/flutter/wiki/Tree-hygiene) '
      'for detailed instructions on how to contribute to the Flutter project. '
      'In particular, ensure that before you start coding, you create your '
      'feature branch off of _${kDefaultBranchName}_.\n\n'
      'This PR has been closed. If you are sure you want to merge $branch, you '
      'may re-open this issue.';

  String get releaseBranchPullRequestMessage => 'This pull request was opened '
      'from and to a release candidate branch. This should only be done as part '
      'of the official [Flutter release process]'
      '(https://github.com/flutter/flutter/wiki/Release-process). If you are '
      'attempting to make a regular contribution to the Flutter project, please '
      'close this PR and follow the instructions at [Tree Hygiene]'
      '(https://github.com/flutter/flutter/wiki/Tree-hygiene) for detailed '
      'instructions on contributing to Flutter.\n\n'
      '__Reviewers__: Use caution before merging pull requests to release '
      'branches. Ensure the proper procedure has been followed.';

  Future<String> get webhookKey => _getSingleValue('WebhookKey');

  String get mergeConflictPullRequestMessage => 'This pull request is not '
      'mergeable in its current state, likely because of a merge conflict. '
      'Pre-submit CI jobs were not triggered. Pushing a new commit to this '
      'branch that resolves the issue will result in pre-submit jobs being '
      'scheduled.';

  String get missingTestsPullRequestMessage => 'It looks like this pull '
      'request may not have tests. Please make sure to add tests before merging. '
      'If you need '
      '[an exemption](https://github.com/flutter/flutter/wiki/Tree-hygiene#tests) '
      'to this rule, contact Hixie on the #hackers '
      'channel in [Chat](https://github.com/flutter/flutter/wiki/Chat) '
      '(don\'t just cc him here, he won\'t see it! *He\'s on Discord!*).'
      '\n\n'
      'If you are not sure if you need tests, consider this rule of thumb: '
      'the purpose of a test is to make sure someone doesn\'t accidentally '
      'revert the fix. Ask yourself, **is there anything in your PR that you '
      'feel it is important we not accidentally revert back to how it was '
      'before your fix?**'
      '\n\n'
      '__Reviewers__: Read the [Tree Hygiene page]'
      '(https://github.com/flutter/flutter/wiki/Tree-hygiene#how-to-review-code) '
      'and make sure this patch meets those guidelines before LGTMing.';

  String get flutterGoldPending => 'Waiting for all other checks to be successful before querying Gold.';

  String get flutterGoldSuccess => 'All golden file tests have passed.';

  String get flutterGoldChanges => 'Image changes have been found for '
      'this pull request.';

  String get flutterGoldStalePR => 'This pull request executed golden file '
      'tests, but it has not been updated in a while (20+ days). Test results from '
      'Gold expire after as many days, so this pull request will need to be '
      'updated with a fresh commit in order to get results from Gold.';

  String get flutterGoldDraftChange => 'This pull request has been changed to a '
      'draft. The currently pending flutter-gold status will not be able '
      'to resolve until a new commit is pushed or the change is marked ready for '
      'review again.';

  String flutterGoldInitialAlert(String url) => 'Golden file changes have been found for this pull '
      'request. Click [here to view and triage]($url) '
      '(e.g. because this is an intentional change).\n\n'
      'If you are still iterating on this change and are not ready to '
      'resolve the images on the Flutter Gold dashboard, consider marking this PR '
      'as a draft pull request above. You will still be able to view image results '
      'on the dashboard, commenting will be silenced, and the check will not try to resolve itself until '
      'marked ready for review.\n\n';

  String flutterGoldFollowUpAlert(String url) => 'Golden file changes are available for triage from new commit, '
      'Click [here to view]($url).\n\n';

  String flutterGoldAlertConstant(gh.RepositorySlug slug) {
    if (slug == Config.flutterSlug) {
      return '\n\nFor more guidance, visit '
          '[Writing a golden file test for `package:flutter`](https://github.com/flutter/flutter/wiki/Writing-a-golden-file-test-for-package:flutter).\n\n'
          '__Reviewers__: Read the [Tree Hygiene page](https://github.com/flutter/flutter/wiki/Tree-hygiene#how-to-review-code) '
          'and make sure this patch meets those guidelines before LGTMing.\n\n';
    }
    return '';
  }

  String flutterGoldCommentID(gh.PullRequest pr) =>
      '_Changes reported for pull request #${pr.number} at sha ${pr.head!.sha}_\n\n';

  /// Post submit service account email used by LUCI swarming tasks.
  static const String luciProdAccount = 'flutter-prod-builder@chops-service-accounts.iam.gserviceaccount.com';

  /// Internal Google service account used to surface FRoB results.
  static const String frobAccount = 'flutter-roll-on-borg@flutter-roll-on-borg.google.com.iam.gserviceaccount.com';

  /// Service accounts used for PubSub messages.
  static const Set<String> allowedPubsubServiceAccounts = <String>{
    'flutter-devicelab@flutter-dashboard.iam.gserviceaccount.com',
    'flutter-dashboard@appspot.gserviceaccount.com',
  };

  int get maxTaskRetries => 2;

  /// Max retries for Luci builder with infra failure.
  int get maxLuciTaskRetries => 2;

  /// The default number of commit shown in flutter build dashboard.
  int get commitNumber => 30;

  KeyHelper get keyHelper => KeyHelper(applicationContext: context.applicationContext);

  // Default number of commits to return for benchmark dashboard.
  int /*!*/ get maxRecords => 50;

  // Delay between consecutive GitHub deflake request calls.
  Duration get githubRequestDelay => const Duration(seconds: 1);

  // Repository status context for github status.
  String get flutterBuild => 'flutter-build';

  // Repository status description for github status.
  String get flutterBuildDescription => 'Tree is currently broken. Please do not merge this '
      'PR unless it contains a fix for the tree.';

  static gh.RepositorySlug get cocoonSlug => gh.RepositorySlug('flutter', 'cocoon');
  static gh.RepositorySlug get engineSlug => gh.RepositorySlug('flutter', 'engine');
  static gh.RepositorySlug get flutterSlug => gh.RepositorySlug('flutter', 'flutter');
  static gh.RepositorySlug get packagesSlug => gh.RepositorySlug('flutter', 'packages');

  /// Flutter recipes is hosted on Gerrit instead of GitHub.
  static gh.RepositorySlug get recipesSlug => gh.RepositorySlug('flutter', 'recipes');

  String get waitingForTreeToGoGreenLabelName => 'waiting for tree to go green';

  /// The names of autoroller accounts for the repositories.
  ///
  /// These accounts should not need reviews before merging. See
  /// https://github.com/flutter/flutter/wiki/Autorollers
  Set<String> get rollerAccounts => const <String>{
        'skia-flutter-autoroll',
        'engine-flutter-autoroll',
        'dependabot',
        'dependabot[bot]',
      };

  Future<String> generateJsonWebToken() async {
    final String privateKey = await githubPrivateKey;
    final String publicKey = await githubPublicKey;
    final JWTBuilder builder = JWTBuilder();
    final DateTime now = DateTime.now();
    builder
      ..issuer = await githubAppId
      ..issuedAt = now
      ..expiresAt = now.add(const Duration(minutes: 10));
    final JWTRsaSha256Signer signer = JWTRsaSha256Signer(privateKey: privateKey, publicKey: publicKey);
    final JWT signedToken = builder.getSignedToken(signer);
    return signedToken.toString();
  }

  Future<String> generateGithubToken(gh.RepositorySlug slug) async {
    // GitHub's secondary rate limits are run into very frequently when making auth tokens.
    final Uint8List? cacheValue = await _cache.getOrCreateWithLocking(
      configCacheName,
      'githubToken-${slug.fullName}',
      createFn: () => _generateGithubToken(slug),
      // Tokens are minted for 10 minutes
      ttl: const Duration(minutes: 8),
    );

    return String.fromCharCodes(cacheValue!);
  }

  Future<Uint8List> _generateGithubToken(gh.RepositorySlug slug) async {
    final Map<String, dynamic> appInstallations = await githubAppInstallations;
    final String? appInstallation = appInstallations[slug.fullName]['installation_id'] as String?;
    final String jsonWebToken = await generateJsonWebToken();
    final Map<String, String> headers = <String, String>{
      'Authorization': 'Bearer $jsonWebToken',
      'Accept': 'application/vnd.github.machine-man-preview+json',
    };
    final Uri githubAccessTokensUri = Uri.https('api.github.com', 'app/installations/$appInstallation/access_tokens');
    final http.Response response = await http.post(githubAccessTokensUri, headers: headers);
    final Map<String, dynamic> jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    if (jsonBody.containsKey('token') == false) {
      log.warning(response.body);
      throw Exception('generateGitHubToken failed to get token from Github for repo=${slug.fullName}');
    }
    final String token = jsonBody['token'] as String;
    log.fine('Generated a new GitHub token for ${slug.fullName}');
    return Uint8List.fromList(token.codeUnits);
  }

  Future<gh.GitHub> createGitHubClient({gh.PullRequest? pullRequest, gh.RepositorySlug? slug}) async {
    slug ??= pullRequest!.base!.repo!.slug();
    final String githubToken = await generateGithubToken(slug);
    return createGitHubClientWithToken(githubToken);
  }

  gh.GitHub createGitHubClientWithToken(String token) {
    return gh.GitHub(auth: gh.Authentication.withToken(token));
  }

  Future<GraphQLClient> createGitHubGraphQLClient() async {
    final HttpLink httpLink = HttpLink(
      'https://api.github.com/graphql',
      defaultHeaders: <String, String>{
        'Accept': 'application/vnd.github.antiope-preview+json',
      },
    );

    final String token = await githubOAuthToken;
    final AuthLink authLink = AuthLink(
      getToken: () async => 'Bearer $token',
    );

    return GraphQLClient(
      cache: GraphQLCache(),
      link: authLink.concat(httpLink),
    );
  }

  Future<GraphQLClient> createCirrusGraphQLClient() async {
    final HttpLink httpLink = HttpLink(
      'https://api.cirrus-ci.com/graphql',
    );

    return GraphQLClient(
      cache: GraphQLCache(),
      link: httpLink,
    );
  }

  Future<BigqueryService> createBigQueryService() async {
    final AccessClientProvider accessClientProvider = AccessClientProvider();
    return BigqueryService(accessClientProvider);
  }

  Future<TabledataResource> createTabledataResourceApi() async {
    return (await createBigQueryService()).defaultTabledata();
  }

  /// Default GitHub service when the repository does not matter.
  ///
  /// Internally uses the framework repo for OAuth.
  Future<GithubService> createDefaultGitHubService() async {
    return createGithubService(flutterSlug);
  }

  Future<GithubService> createGithubService(gh.RepositorySlug slug) async {
    final gh.GitHub github = await createGitHubClient(slug: slug);
    return GithubService(github);
  }

  GithubService createGithubServiceWithToken(String token) {
    final gh.GitHub github = createGitHubClientWithToken(token);
    return GithubService(github);
  }
}
