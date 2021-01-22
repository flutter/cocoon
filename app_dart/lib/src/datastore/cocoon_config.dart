// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/service/luci.dart';
import 'package:corsac_jwt/corsac_jwt.dart';
import 'package:gcloud/db.dart';
import 'package:gcloud/service_scope.dart' as ss;
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart' as bigquery;
import 'package:googleapis_auth/auth.dart';
import 'package:graphql/client.dart' hide Cache;
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:metrics_center/metrics_center.dart';

import '../../cocoon_service.dart';
import '../foundation/providers.dart';
import '../foundation/utils.dart';
import '../model/appengine/key_helper.dart';
import '../model/appengine/service_account_info.dart';
import '../service/access_client_provider.dart';
import '../service/bigquery.dart';
import '../service/github_service.dart';

/// Name of the default git branch.
const String kDefaultBranchName = 'master';

class Config {
  Config(this._db, this._cache) : assert(_db != null);

  final DatastoreDB _db;

  final CacheService _cache;

  /// List of Github presubmit supported repos.
  static const Set<String> supportedRepos = <String>{
    'engine',
    'flutter',
    'cocoon',
    'packages',
    'plugins',
  };

  /// List of Github presubmit supported repos.
  static const Set<String> checksSupportedRepos = <String>{
    'flutter/cocoon',
    'flutter/engine',
    'flutter/flutter',
    'flutter/packages',
    'flutter/plugins',
  };

  /// Memorystore subcache name to store [CocoonConfig] values in.
  static const String configCacheName = 'config';

  @visibleForTesting
  static const Duration configCacheTtl = Duration(hours: 12);

  Logging get loggingService => ss.lookup(#appengine.logging) as Logging;

  Future<List<String>> _getFlutterBranches() async {
    final Uint8List cacheValue = await _cache.getOrCreate(
      configCacheName,
      'flutterBranches',
      createFn: () => getBranches(Providers.freshHttpClient, loggingService, twoSecondLinearBackoff),
      ttl: configCacheTtl,
    );

    return String.fromCharCodes(cacheValue).split(',');
  }

  // Returns LUCI builders.
  Future<List<LuciBuilder>> luciBuilders(String bucket, String repo,
      {String commitSha = 'master', int prNumber}) async {
    final GithubService githubService = await createGithubService('flutter', repo);
    return await getLuciBuilders(githubService, Providers.freshHttpClient, twoSecondLinearBackoff, loggingService,
        RepositorySlug('flutter', repo), bucket,
        prNumber: prNumber, commitSha: commitSha);
  }

  Future<String> _getSingleValue(String id) async {
    final Uint8List cacheValue = await _cache.getOrCreate(
      configCacheName,
      id,
      createFn: () => _getValueFromDatastore(id),
      ttl: configCacheTtl,
    );

    return String.fromCharCodes(cacheValue);
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
  Future<String> get githubPublicKey => _getSingleValue('githubapp_public_pem');
  Future<String> get githubAppId => _getSingleValue('githubapp_id');
  Future<Map<String, dynamic>> get githubAppInstallations async {
    final String installations = await _getSingleValue('githubapp_installations');
    return jsonDecode(installations) as Map<String, dynamic>;
  }

  DatastoreDB get db => _db;

  Future<List<String>> get flutterBranches => _getFlutterBranches();

  Future<String> get oauthClientId => _getSingleValue('OAuthClientId');

  Future<String> get githubOAuthToken => _getSingleValue('GitHubPRToken');

  String get wrongBaseBranchPullRequestMessage => 'This pull request was opened against a branch other than '
      '_${kDefaultBranchName}_. Since Flutter pull requests should not '
      'normally be opened against branches other than $kDefaultBranchName, I '
      'have changed the base to $kDefaultBranchName. If this was intended, you '
      'may modify the base back to {{branch}}. See the [Release Process]'
      '(https://github.com/flutter/flutter/wiki/Release-process) for information '
      'about how other branches get updated.\n\n'
      '__Reviewers__: Use caution before merging pull requests to branches other '
      'than $kDefaultBranchName, unless this is an intentional hotfix/cherrypick.';

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
      'If you need an exemption to this rule, contact Hixie on the #hackers '
      'channel in [Chat](https://github.com/flutter/flutter/wiki/Chat).'
      '\n\n'
      'If you are not sure if you need tests, consider this rule of thumb: '
      'the purpose of a test is to make sure someone doesn\'t accidentally '
      'revert the fix. Ask yourself, is there anything in your PR that you '
      'feel it is important we not accidentally revert back to how it was '
      'before your fix?'
      '\n\n'
      '__Reviewers__: Read the [Tree Hygiene page]'
      '(https://github.com/flutter/flutter/wiki/Tree-hygiene#how-to-review-code) '
      'and make sure this patch meets those guidelines before LGTMing.';

  String get flutterGoldPending => 'Pending.';

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

  String get flutterGoldAlertConstant => '\n\nFor more guidance, visit '
      '[Writing a golden file test for `package:flutter`](https://github.com/flutter/flutter/wiki/Writing-a-golden-file-test-for-package:flutter).\n\n'
      '__Reviewers__: Read the [Tree Hygiene page](https://github.com/flutter/flutter/wiki/Tree-hygiene#how-to-review-code) '
      'and make sure this patch meets those guidelines before LGTMing.\n\n';

  String flutterGoldCommentID(PullRequest pr) =>
      '_Changes reported for pull request #${pr.number} at sha ${pr.head.sha}_\n\n';

  /// Post submit service account email used by LUCI swarming tasks.
  String get luciProdAccount => 'flutter-prod-builder@chops-service-accounts.iam.gserviceaccount.com';

  int get maxTaskRetries => 2;

  /// Max retries for Luci builder with infra failure.
  int get maxLuciTaskRetries => 1;

  /// The number of times to retry a LUCI job on infra failures.
  int get luciTryInfraFailureRetries => 2;

  /// The default number of commit shown in flutter build dashboard.
  int get commitNumber => 30;

  // TODO(keyonghan): update all existing APIs to use this reference, https://github.com/flutter/flutter/issues/48987.
  KeyHelper get keyHelper => KeyHelper(applicationContext: context.applicationContext);

  String get defaultBranch => kDefaultBranchName;

  // Default number of commits to return for benchmark dashboard.
  int get maxRecords => 50;

  // Repository status context for github status.
  String get flutterBuild => 'flutter-build';

  // Repository status description for github status.
  String get flutterBuildDescription => 'Flutter build is currently broken. Please do not merge this '
      'PR unless it contains a fix to the broken build.';

  RepositorySlug get flutterSlug => RepositorySlug('flutter', 'flutter');

  String get waitingForTreeToGoGreenLabelName => 'waiting for tree to go green';

  Future<ServiceAccountInfo> get deviceLabServiceAccount async {
    final String rawValue = await _getSingleValue('DevicelabServiceAccount');
    return ServiceAccountInfo.fromJson(json.decode(rawValue) as Map<String, dynamic>);
  }

  Future<ServiceAccountCredentials> get taskLogServiceAccount async {
    final String rawValue = await _getSingleValue('TaskLogServiceAccount');
    return ServiceAccountCredentials.fromJson(json.decode(rawValue));
  }

  /// The names of autoroller accounts for the repositories.
  ///
  /// These accounts should not need reviews before merging. See
  /// https://github.com/flutter/flutter/wiki/Autorollers
  Set<String> get rollerAccounts => const <String>{
        'skia-flutter-autoroll',
        'engine-flutter-autoroll',
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

  Future<String> generateGithubToken(String owner, String repository) async {
    final Map<String, dynamic> appInstallations = await githubAppInstallations;
    final String appInstallation = appInstallations['$owner/$repository']['installation_id'] as String;
    final String jsonWebToken = await generateJsonWebToken();
    final Map<String, String> headers = <String, String>{
      'Authorization': 'Bearer $jsonWebToken',
      'Accept': 'application/vnd.github.machine-man-preview+json'
    };
    final http.Response response =
        await http.post('https://api.github.com/app/installations/$appInstallation/access_tokens', headers: headers);
    final Map<String, dynamic> jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    return jsonBody['token'] as String;
  }

  Future<GitHub> createGitHubClient(String owner, String repository) async {
    String githubToken;
    githubToken = await generateGithubToken(owner, repository);
    return GitHub(auth: Authentication.withToken(githubToken));
  }

  Future<GraphQLClient> createGitHubGraphQLClient() async {
    final HttpLink httpLink = HttpLink(
      uri: 'https://api.github.com/graphql',
      headers: <String, String>{
        'Accept': 'application/vnd.github.antiope-preview+json',
      },
    );

    final String token = await githubOAuthToken;
    final AuthLink _authLink = AuthLink(
      getToken: () async => 'Bearer $token',
    );

    final Link link = _authLink.concat(httpLink);

    return GraphQLClient(
      cache: InMemoryCache(),
      link: link,
    );
  }

  Future<GraphQLClient> createCirrusGraphQLClient() async {
    final HttpLink httpLink = HttpLink(
      uri: 'https://api.cirrus-ci.com/graphql',
    );

    return GraphQLClient(
      cache: InMemoryCache(),
      link: httpLink,
    );
  }

  Future<bigquery.TabledataResourceApi> createTabledataResourceApi() async {
    final AccessClientProvider accessClientProvider = AccessClientProvider(await deviceLabServiceAccount);
    return await BigqueryService(accessClientProvider).defaultTabledata();
  }

  Future<GithubService> createGithubService(String owner, String repository) async {
    final GitHub github = await createGitHubClient(owner, repository);
    return GithubService(github);
  }

  Future<FlutterDestination> createMetricsDestination() async {
    return await FlutterDestination.makeFromCredentialsJson(
      (await deviceLabServiceAccount).toJson(),
    );
  }

  bool githubPresubmitSupportedRepo(String repositoryName) {
    return supportedRepos.contains(repositoryName);
  }

  bool isChecksSupportedRepo(RepositorySlug slug) {
    return checksSupportedRepos.contains('${slug.owner}/${slug.name}');
  }
}

@Kind(name: 'CocoonConfig', idType: IdType.String)
class CocoonConfig extends Model<String> {
  @StringProperty(propertyName: 'ParameterValue')
  String value;
}

class InvalidConfigurationException implements Exception {
  const InvalidConfigurationException(this.id);

  final String id;

  @override
  String toString() => 'Invalid configuration value for $id';
}
