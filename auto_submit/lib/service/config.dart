// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_server/bigquery.dart';
import 'package:cocoon_server/generate_github_jws.dart';
import 'package:cocoon_server/google_auth_provider.dart';
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_server/secret_manager.dart';
import 'package:github/github.dart';
import 'package:graphql/client.dart';
import 'package:neat_cache/cache_provider.dart';
import 'package:neat_cache/neat_cache.dart';
import 'package:retry/retry.dart';

import '../configuration/repository_configuration.dart';
import '../configuration/repository_configuration_manager.dart';
import '../foundation/providers.dart';
import 'github_service.dart';

class CocoonGitHubRequestException implements Exception {
  const CocoonGitHubRequestException(
    this.message, {
    required this.code,
    required this.uri,
  });

  final String message;
  final int code;
  final Uri uri;

  @override
  String toString() {
    return 'CocoonGitHubRequestException: Request to "$uri" (response code $code):\n$message';
  }
}

/// Configuration for the autosubmit engine.
class Config {
  Config({
    required this.cacheProvider,
    this.httpProvider = Providers.freshHttpClient,
    required this.secretManager,
  }) {
    repositoryConfigurationManager = RepositoryConfigurationManager(
      this,
      cache,
    );
  }

  late RepositoryConfigurationManager repositoryConfigurationManager;

  /// Project/GCP constants
  static const String flutter = 'flutter';
  static const String flutterGcpProjectId = 'flutter-dashboard';

  // List of environment variable keys related to the Github app authentication.
  static const String kGithubKey = 'AUTO_SUBMIT_GITHUB_KEY_PEM';
  static const String kGithubAppId = 'AUTO_SUBMIT_GITHUB_APP_ID';
  static const String kWebHookKey = 'AUTO_SUBMIT_WEBHOOK_TOKEN';
  static const String kFlutterGitHubBotKey = 'AUTO_SUBMIT_FLUTTER_GITHUB_TOKEN';
  static const String kTreeStatusDiscordUrl = 'TREE_STATUS_DISCORD_WEBHOOK_URL';

  /// When present on a pull request, instructs Cocoon to submit it
  /// automatically as soon as all the required checks pass.
  ///
  /// Keep this in sync with the similar `Config` class in `app_dart`.
  static const String kAutosubmitLabel = 'autosubmit';

  /// When present on a pull request, allows it to land without passing all the
  /// checks, and jumps the merge queue.
  ///
  /// Keep this in sync with the similar `Config` class in `app_dart`.
  static const String kEmergencyLabel = 'emergency';

  /// Validates that CI tasks were successfully created from the .ci.yaml file.
  ///
  /// If this check fails, it means Cocoon failed to fully populate the list of
  /// CI checks and the PR/commit should be treated as failing.
  static const String kCiYamlCheckName = 'ci.yaml validation';

  /// A required check that stays in pending state until a sufficient subset of
  /// checks pass.
  ///
  /// This check is "required", meaning that it must pass before Github will
  /// allow a PR to land in the merge queue, or a merge group to land on the
  /// target branch (main or master).
  ///
  /// IMPORTANT: the name of this task - "Merge Queue Guard" - must strictly
  /// match the name of the required check configured in the repo settings.
  /// Changing the name here or in the settings alone will break the PR
  /// workflow.
  static const String kMergeQueueLockName = 'Merge Queue Guard';

  /// GitHub check stale threshold.
  static const int kGitHubCheckStaleThreshold = 2; // hours

  // Labels the bot looks for on revert requests.
  // TODO (ricardoamador) https://github.com/flutter/flutter/issues/134845:
  // add a link to a one page doc outlining the workflow that happens here.

  /// The `revert` label is used by developers to initiate the revert request.
  /// This signals to the service that it should revert the changes in this pull
  /// request.
  static const String kRevertLabel = 'revert';

  /// The `revert of` label is used exclusively by the bot. The user does not
  /// add this. When the bot successfully pushes the revert request to Github
  /// it adds this label to signify that it should then validate and merge this
  /// as a revert.
  static const String kRevertOfLabel = 'revert of';

  /// Repository Slug data
  /// GitHub repositories that use CI status to determine if pull requests can be submitted.
  static Set<RepositorySlug> reposWithTreeStatus = <RepositorySlug>{
    flutterSlug,
  };
  static RepositorySlug get flutterSlug => RepositorySlug('flutter', 'flutter');

  String get autosubmitBot => 'auto-submit[bot]';

  /// The names of autoroller accounts for the repositories.
  ///
  /// These accounts should not need reviews before merging. See
  /// https://github.com/flutter/flutter/blob/master/docs/infra/Autorollers.md
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

  static String get pubsubTopicsPrefix =>
      'projects/$flutterGcpProjectId/topics';
  static String get pubsubSubscriptionsPrefix =>
      'projects/$flutterGcpProjectId/subscriptions';

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
      '- Merge guidelines: A PR needs at least one approved review if the author is already '
      'part of flutter-hackers or two member reviews if the author is not a flutter-hacker '
      'before re-applying the autosubmit label. __Reviewers__: If you left a comment '
      'approving, please use the "approve" review action instead.';

  /// Config object members
  final CacheProvider cacheProvider;
  final HttpProvider httpProvider;
  final SecretManager secretManager;

  Cache get cache => Cache<dynamic>(cacheProvider).withPrefix('config');

  Future<RepositoryConfiguration> getRepositoryConfiguration(
    RepositorySlug slug,
  ) async {
    return repositoryConfigurationManager.readRepositoryConfiguration(slug);
  }

  Future<GithubService> createGithubService(RepositorySlug slug) async {
    final github = await createGithubClient(slug);
    return GithubService(github);
  }

  Future<GitHub> createGithubClient(RepositorySlug slug) async {
    final token = await generateGithubToken(slug);
    return GitHub(auth: Authentication.withToken(token));
  }

  Future<GitHub> createFlutterGitHubBotClient(RepositorySlug slug) async {
    final token = await getFlutterGitHubBotToken();
    return GitHub(auth: Authentication.withToken(token));
  }

  Future<String> generateGithubToken(RepositorySlug slug) async {
    // GitHub's secondary rate limits are run into very frequently when making auth tokens.
    final cacheValue =
        await cache['githubToken-${slug.owner}'].get(
              () => _generateGithubToken(slug),
              // Tokens have a TTL of 10 minutes. AppEngine requests have a TTL of 1 minute.
              // To ensure no expired tokens are used, set this to 10 - 1, with an extra buffer of a duplicate request.
              const Duration(minutes: 8),
            )
            as Uint8List?;
    return String.fromCharCodes(cacheValue!);
  }

  Future<String> getInstallationId(RepositorySlug slug) async {
    final jwt = generateGitHubJws(
      privateKeyPem: await secretManager.getString(kGithubKey),
      githubAppId: await secretManager.getString(kGithubAppId),
    );
    final headers = <String, String>{
      'Authorization': 'Bearer $jwt',
      'Accept': 'application/vnd.github.machine-man-preview+json',
    };
    // TODO(KristinBi): Upstream the github package.https://github.com/flutter/flutter/issues/100920
    final githubInstallationUri = Uri.https(
      'api.github.com',
      'users/${slug.owner}/installation',
    );
    final client = httpProvider();
    // TODO(KristinBi): Track the installation id by repo. https://github.com/flutter/flutter/issues/100808
    final response = await client.get(githubInstallationUri, headers: headers);
    final installData = json.decode(response.body) as Map<String, dynamic>;
    final installationId = installData['id']?.toString();
    if (installationId == null) {
      log.warn(
        'Failed to get ID from Github '
        '(response code ${response.statusCode}):\n${response.body}',
      );
      throw CocoonGitHubRequestException(
        'getInstallationId failed to get ID from Github',
        code: response.statusCode,
        uri: githubInstallationUri,
      );
    }
    return installationId;
  }

  Future<GraphQLClient> createGitHubGraphQLClient(RepositorySlug slug) async {
    final httpLink = HttpLink(
      'https://api.github.com/graphql',
      defaultHeaders: <String, String>{
        'Accept': 'application/vnd.github.antiope-preview+json',
      },
    );

    final token = await generateGithubToken(slug);

    final authLink = AuthLink(getToken: () async => 'Bearer $token');

    return GraphQLClient(
      cache: GraphQLCache(),
      link: authLink.concat(httpLink),
    );
  }

  Future<BigqueryService> createBigQueryService() async {
    return BigqueryService.from(const GoogleAuthProvider());
  }

  Future<Uint8List> _generateGithubToken(RepositorySlug slug) async {
    log.info('Generating new GitHub token');
    final jwt = generateGitHubJws(
      privateKeyPem: await secretManager.getString(kGithubKey),
      githubAppId: await secretManager.getString(kGithubAppId),
    );
    final headers = <String, String>{
      'Authorization': 'Bearer $jwt',
      'Accept': 'application/vnd.github.machine-man-preview+json',
    };
    final installationId = await getInstallationId(slug);
    final githubAccessTokensUri = Uri.https(
      'api.github.com',
      'app/installations/$installationId/access_tokens',
    );
    final client = httpProvider();
    final response = await client.post(githubAccessTokensUri, headers: headers);
    final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    final token = jsonBody['token'] as String?;
    if (token == null) {
      log.warn(
        'Failed to get token from Github '
        '(response code ${response.statusCode}):\n${response.body}',
      );
      throw CocoonGitHubRequestException(
        'generateGithubToken failed to get token from Github',
        code: response.statusCode,
        uri: githubAccessTokensUri,
      );
    }
    log.info('Successfully generated new GitHub token');
    return Uint8List.fromList(token.codeUnits);
  }

  /// Get the webhook key
  Future<String> getWebhookKey() async {
    final cacheValue =
        await cache[kWebHookKey].get(
              () => _getValueFromSecretManager(kWebHookKey),
            )
            as Uint8List?;
    return String.fromCharCodes(cacheValue!);
  }

  Future<String> getFlutterGitHubBotToken() async {
    final cacheValue =
        await cache[kFlutterGitHubBotKey].get(
              () => _getValueFromSecretManager(kFlutterGitHubBotKey),
            )
            as Uint8List?;
    return String.fromCharCodes(cacheValue!);
  }

  Future<String> getTreeStatusDiscordUrl() async {
    final cacheValue =
        await cache[kTreeStatusDiscordUrl].get(
              () => _getValueFromSecretManager(kTreeStatusDiscordUrl),
            )
            as Uint8List?;
    return String.fromCharCodes(cacheValue!);
  }

  Future<Uint8List> _getValueFromSecretManager(String key) async {
    final value = await secretManager.getString(key);
    return Uint8List.fromList(value.codeUnits);
  }
}
