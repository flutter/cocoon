// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/configuration/repository_configuration_manager.dart';
import 'package:corsac_jwt/corsac_jwt.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:neat_cache/cache_provider.dart';
import 'package:neat_cache/neat_cache.dart';
import 'package:retry/retry.dart';

import '../foundation/providers.dart';
import '../service/secrets.dart';
import 'access_client_provider.dart';
import 'bigquery.dart';
import 'github_service.dart';
import 'log.dart';

/// Configuration for the autosubmit engine.
class Config {
  Config({
    required this.cacheProvider,
    this.httpProvider = Providers.freshHttpClient,
    required this.secretManager,
  }) {
    repositoryConfigurationManager = RepositoryConfigurationManager(this, cache);
  }

  late RepositoryConfigurationManager repositoryConfigurationManager;

  /// Project/GCP constants
  static const String flutter = 'flutter';
  static const String flutterGcpProjectId = 'flutter-dashboard';

  // List of environment variable keys related to the Github app authentication.
  static const String kGithubKey = 'AUTO_SUBMIT_GITHUB_KEY';
  static const String kGithubAppId = 'AUTO_SUBMIT_GITHUB_APP_ID';
  static const String kWebHookKey = 'AUTO_SUBMIT_WEBHOOK_TOKEN';
  static const String kFlutterGitHubBotKey = 'AUTO_SUBMIT_FLUTTER_GITHUB_TOKEN';

  /// Labels autosubmit looks for on pull requests
  static const String kAutosubmitLabel = 'autosubmit';
  static const String kRevertLabel = 'revert';

  /// The label which shows the overrideTree    Status.
  String get overrideTreeStatusLabel => 'warning: land on red to fix tree breakage';

  /// Repository Slug data
  /// GitHub repositories that use CI status to determine if pull requests can be submitted.
  static Set<RepositorySlug> reposWithTreeStatus = <RepositorySlug>{
    engineSlug,
    flutterSlug,
  };
  static RepositorySlug get engineSlug => RepositorySlug('flutter', 'engine');
  static RepositorySlug get flutterSlug => RepositorySlug('flutter', 'flutter');

  /// The names of autoroller accounts for the repositories.
  ///
  /// These accounts should not need reviews before merging. See
  /// https://github.com/flutter/flutter/wiki/Autorollers
  Set<String> get rollerAccounts => const <String>{
        'skia-flutter-autoroll',
        'engine-flutter-autoroll',
        // REST API returns dependabot[bot] as author while GraphQL returns dependabot. We need
        // both as we use graphQL to merge the PR and REST API to approve the PR.
        'dependabot[bot]',
        'dependabot',
        'DartDevtoolWorkflowBot',
      };

  /// Repository configuration variables
  Duration get repositoryConfigurationTtl => const Duration(minutes: 10);

  /// PubSub configs
  int get kPullMesssageBatchSize => 100;

  /// Number of Pub/Sub pull calls in each cron job run.
  ///
  /// TODO(keyonghan): monitor and optimize this number based on response time
  /// https://github.com/flutter/cocoon/pull/2035/files#r938143840.
  int get kPubsubPullNumber => 5;

  static String get pubsubTopicsPrefix => 'projects/flutter-dashboard/topics';
  static String get pubsubSubscriptionsPrefix => 'projects/flutter-dashboard/subscriptions';

  String get pubsubPullRequestTopic => 'auto-submit-queue';
  String get pubsubPullRequestSubscription => 'auto-submit-queue-sub';

  String get pubsubRevertRequestTopic => 'auto-submit-revert-queue';
  String get pubsubRevertRequestSubscription => 'auto-submit-revert-queue-sub';

  /// Retry options for timing related retryable code.
  static const RetryOptions mergeRetryOptions = RetryOptions(
    delayFactor: Duration(milliseconds: 200),
    maxDelay: Duration(seconds: 1),
    maxAttempts: 5,
  );

  static const RetryOptions requiredChecksRetryOptions = RetryOptions(
    delayFactor: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 5),
    maxAttempts: 5,
  );

  /// Pull request approval message
  static const String pullRequestApprovalRequirementsMessage =
      '- Merge guidelines: You need at least one approved review if you are already '
      'part of flutter-hackers or two member reviews if you are not a flutter-hacker '
      'before re-applying the autosubmit label. __Reviewers__: If you left a comment '
      'approving, please use the "approve" review action instead.';

  /// Config object members
  final CacheProvider cacheProvider;
  final HttpProvider httpProvider;
  final SecretManager secretManager;

  Cache get cache => Cache<dynamic>(cacheProvider).withPrefix('config');

  Future<RepositoryConfiguration> getRepositoryConfiguration(RepositorySlug slug) async {
    return repositoryConfigurationManager.readRepositoryConfiguration(slug);
  }

  Future<GithubService> createGithubService(RepositorySlug slug) async {
    final GitHub github = await createGithubClient(slug);
    return GithubService(github);
  }

  Future<GitHub> createGithubClient(RepositorySlug slug) async {
    final String token = await generateGithubToken(slug);
    return GitHub(auth: Authentication.withToken(token));
  }

  Future<GitHub> createFlutterGitHubBotClient(RepositorySlug slug) async {
    final String token = await getFlutterGitHubBotToken();
    return GitHub(auth: Authentication.withToken(token));
  }

  Future<String> generateGithubToken(RepositorySlug slug) async {
    // GitHub's secondary rate limits are run into very frequently when making auth tokens.
    final Uint8List? cacheValue = await cache['githubToken-${slug.owner}'].get(
      () => _generateGithubToken(slug),
      // Tokens have a TTL of 10 minutes. AppEngine requests have a TTL of 1 minute.
      // To ensure no expired tokens are used, set this to 10 - 1, with an extra buffer of a duplicate request.
      const Duration(minutes: 8),
    ) as Uint8List?;
    return String.fromCharCodes(cacheValue!);
  }

  Future<String> getInstallationId(RepositorySlug slug) async {
    final String jwt = await _generateGithubJwt();
    final Map<String, String> headers = <String, String>{
      'Authorization': 'Bearer $jwt',
      'Accept': 'application/vnd.github.machine-man-preview+json',
    };
    // TODO(KristinBi): Upstream the github package.https://github.com/flutter/flutter/issues/100920
    final Uri githubInstallationUri = Uri.https('api.github.com', 'app/installations');
    final http.Client client = httpProvider();
    // TODO(KristinBi): Track the installation id by repo. https://github.com/flutter/flutter/issues/100808
    final http.Response response = await client.get(
      githubInstallationUri,
      headers: headers,
    );
    final List<Map<String, dynamic>> list = (json.decode(response.body) as List<dynamic>).cast<Map<String, dynamic>>();
    late String installationId;
    for (Map<String, dynamic> installData in list) {
      if (installData['account']!['login']!.toString() == slug.owner) {
        installationId = installData['id']!.toString();
      }
    }
    return installationId;
  }

  Future<GraphQLClient> createGitHubGraphQLClient(RepositorySlug slug) async {
    final HttpLink httpLink = HttpLink(
      'https://api.github.com/graphql',
      defaultHeaders: <String, String>{
        'Accept': 'application/vnd.github.antiope-preview+json',
      },
    );

    final String token = await generateGithubToken(slug);

    final AuthLink authLink = AuthLink(
      getToken: () async => 'Bearer $token',
    );

    return GraphQLClient(
      cache: GraphQLCache(),
      link: authLink.concat(httpLink),
    );
  }

  Future<BigqueryService> createBigQueryService() async {
    final AccessClientProvider accessClientProvider = AccessClientProvider();
    return BigqueryService(accessClientProvider);
  }

  Future<TabledataResource> createTabledataResourceApi() async {
    return (await createBigQueryService()).defaultTabledata();
  }

  Future<Uint8List> _generateGithubToken(RepositorySlug slug) async {
    final String jwt = await _generateGithubJwt();
    final Map<String, String> headers = <String, String>{
      'Authorization': 'Bearer $jwt',
      'Accept': 'application/vnd.github.machine-man-preview+json',
    };
    final String installationId = await getInstallationId(slug);
    final Uri githubAccessTokensUri = Uri.https('api.github.com', 'app/installations/$installationId/access_tokens');
    final http.Client client = httpProvider();
    final http.Response response = await client.post(
      githubAccessTokensUri,
      headers: headers,
    );
    final Map<String, dynamic> jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    if (jsonBody.containsKey('token') == false) {
      log.warning(response.body);
      throw Exception('generateGithubToken failed to get token from Github');
    }
    final String token = jsonBody['token'] as String;
    return Uint8List.fromList(token.codeUnits);
  }

  Future<String> _generateGithubJwt() async {
    final String rawKey = await secretManager.get(kGithubKey);
    final StringBuffer sb = StringBuffer();
    sb.writeln(rawKey.substring(0, 32));
    sb.writeln(rawKey.substring(32, rawKey.length - 30).replaceAll(' ', '  \n'));
    sb.writeln(rawKey.substring(rawKey.length - 30, rawKey.length));
    final String privateKey = sb.toString();
    final JWTBuilder builder = JWTBuilder();
    final DateTime now = DateTime.now();
    builder
      ..issuer = await secretManager.get(kGithubAppId)
      ..issuedAt = now
      ..expiresAt = now.add(const Duration(minutes: 10));
    final JWTRsaSha256Signer signer = JWTRsaSha256Signer(privateKey: privateKey);
    final JWT signedToken = builder.getSignedToken(signer);
    return signedToken.toString();
  }

  /// Get the webhook key
  Future<String> getWebhookKey() async {
    final Uint8List? cacheValue = await cache[kWebHookKey].get(
      () => _getValueFromSecretManager(kWebHookKey),
    ) as Uint8List?;
    return String.fromCharCodes(cacheValue!);
  }

  Future<String> getFlutterGitHubBotToken() async {
    final Uint8List? cacheValue = await cache[kFlutterGitHubBotKey].get(
      () => _getValueFromSecretManager(kFlutterGitHubBotKey),
    ) as Uint8List?;
    return String.fromCharCodes(cacheValue!);
  }

  Future<Uint8List> _getValueFromSecretManager(String key) async {
    final String value = await secretManager.get(key);
    return Uint8List.fromList(value.codeUnits);
  }
}
