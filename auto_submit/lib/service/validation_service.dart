import 'package:auto_submit/exception/bigquery_exception.dart';
import 'package:auto_submit/exception/retryable_exception.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/model/big_query_pull_request_record.dart';
import 'package:auto_submit/model/pull_request_data_types.dart';
import 'package:auto_submit/requests/graphql_queries.dart';
import 'package:auto_submit/service/bigquery.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/graphql_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:github/github.dart' as github;
import 'package:graphql/client.dart' as graphql;
import 'package:retry/retry.dart';

/// Class containing common methods to each of the pull request type validation
/// services.
class ValidationService {
  ValidationService(this.config, {RetryOptions? retryOptions})
      : retryOptions = retryOptions ?? Config.mergeRetryOptions;

  final Config config;
  final RetryOptions retryOptions;

  /// Fetch the most up to date info for the current pull request from github.
  Future<QueryResult> getNewestPullRequestInfo(Config config, github.PullRequest pullRequest) async {
    final github.RepositorySlug slug = pullRequest.base!.repo!.slug();
    final graphql.GraphQLClient graphQLClient = await config.createGitHubGraphQLClient(slug);
    final int? prNumber = pullRequest.number;
    final GraphQlService graphQlService = GraphQlService();

    final FindPullRequestsWithReviewsQuery findPullRequestsWithReviewsQuery = FindPullRequestsWithReviewsQuery(
      repositoryOwner: slug.owner,
      repositoryName: slug.name,
      pullRequestNumber: prNumber!,
    );

    final Map<String, dynamic> data = await graphQlService.queryGraphQL(
      documentNode: findPullRequestsWithReviewsQuery.documentNode,
      variables: findPullRequestsWithReviewsQuery.variables,
      client: graphQLClient,
    );

    return QueryResult.fromJson(data);
  }

  /// Merges the commit if the PullRequest passes all the validations.
  Future<MergeResult> processMerge({
    required Config config,
    required github.PullRequest messagePullRequest,
  }) async {
    final github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final int number = messagePullRequest.number!;

    // Pass an explicit commit message from the PR title otherwise the GitHub API will use the first commit message.
    const String revertPattern = 'Revert "Revert';
    String messagePrefix = '';

    if (messagePullRequest.title!.contains(revertPattern)) {
      // Cleanup auto-generated revert messages.
      messagePrefix = '''
${messagePullRequest.title!.replaceFirst('Revert "Revert', 'Reland')}

''';
    }

    final String prBody = _sanitizePrBody(messagePullRequest.body ?? '');
    final String commitMessage = '$messagePrefix$prBody';

    try {
      github.PullRequestMerge? result;

      await retryOptions.retry(
        () async {
          result = await _processMergeInternal(
            config: config,
            commitMessage: commitMessage,
            slug: slug,
            number: number,
            // TODO(ricardoamador): make this configurable per repository, https://github.com/flutter/flutter/issues/114557
            mergeMethod: github.MergeMethod.squash,
          );
        },
        retryIf: (Exception e) => e is RetryableException,
      );

      final bool merged = result?.merged ?? false;
      if (result != null && !merged) {
        final String message = 'Failed to merge ${slug.fullName}/$number with ${result?.message}';
        log.severe(message);
        return (result: false, message: message);
      }
    } catch (e) {
      // Catch graphql client init exceptions.
      final String message = 'Failed to merge ${slug.fullName}/$number with ${e.toString()}';
      log.severe(message);
      return (result: false, message: message);
    }

    return (result: true, message: commitMessage);
  }

  /// Insert a merged pull request record into the database.
  Future<void> insertPullRequestRecord({
    required Config config,
    required github.PullRequest pullRequest,
    required PullRequestChangeType pullRequestType,
  }) async {
    final github.RepositorySlug slug = pullRequest.base!.repo!.slug();
    final GithubService gitHubService = await config.createGithubService(slug);
    // We need the updated time fields for the merged request from github.
    final github.PullRequest currentPullRequest = await gitHubService.getPullRequest(slug, pullRequest.number!);

    log.info('Updated pull request info: ${currentPullRequest.toString()}');

    // add a record for the pull request into our metrics tracking
    final PullRequestRecord pullRequestRecord = PullRequestRecord(
      organization: currentPullRequest.base!.repo!.slug().owner,
      repository: currentPullRequest.base!.repo!.slug().name,
      author: currentPullRequest.user!.login,
      prNumber: pullRequest.number!,
      prCommit: currentPullRequest.head!.sha,
      prRequestType: pullRequestType.name,
      prCreatedTimestamp: currentPullRequest.createdAt!,
      prLandedTimestamp: currentPullRequest.closedAt!,
    );

    log.info('Created pull request record: ${pullRequestRecord.toString()}');

    try {
      final BigqueryService bigqueryService = await config.createBigQueryService();
      await bigqueryService.insertPullRequestRecord(
        projectId: Config.flutterGcpProjectId,
        pullRequestRecord: pullRequestRecord,
      );
      log.info('Record inserted for pull request ${slug.fullName}/${pullRequest.number} successfully.');
    } on BigQueryException catch (exception) {
      log.severe('Unable to insert pull request record due to: ${exception.toString()}');
    }
  }
}

/// Small wrapper class to allow us to capture and create a comment in the PR with
/// the issue that caused the merge failure.
typedef MergeResult = ({bool result, String message});

/// Function signature that will be executed with retries.
typedef RetryHandler = Function();

/// Internal wrapper for the logic of merging a pull request into github.
Future<github.PullRequestMerge> _processMergeInternal({
  required Config config,
  required github.RepositorySlug slug,
  required int number,
  required github.MergeMethod mergeMethod,
  String? commitMessage,
  String? requestSha,
}) async {
  // This is retryable so to guard against token expiration we get a fresh
  // client each time.
  final GithubService gitHubService = await config.createGithubService(slug);
  final github.PullRequestMerge pullRequestMerge = await gitHubService.mergePullRequest(
    slug,
    number,
    commitMessage: commitMessage,
    mergeMethod: mergeMethod,
    requestSha: requestSha,
  );

  if (pullRequestMerge.merged != true) {
    throw RetryableException("Pull request could not be merged: ${pullRequestMerge.message}");
  }

  return pullRequestMerge;
}

final RegExp _kCheckboxPattern = RegExp(r'^\s*-[ ]?\[( |x|X)\]');
final RegExp _kCommentPattern = RegExp(r'<!--.*-->');
final RegExp _kMarkdownLinkRefDef = RegExp(r'^\[[\w\/ -]+\]:');
final RegExp _kPreLaunchHeader = RegExp(r'## Pre-launch Checklist');
final RegExp _kDiscordPattern = RegExp(r'#hackers-new');

String _sanitizePrBody(String rawPrBody) {
  final buffer = StringBuffer();
  bool lastLineWasEmpty = false;
  for (final line in rawPrBody.split('\n')) {
    if (_kCheckboxPattern.hasMatch(line) ||
        _kCommentPattern.hasMatch(line) ||
        _kMarkdownLinkRefDef.hasMatch(line) ||
        _kPreLaunchHeader.hasMatch(line) ||
        _kDiscordPattern.hasMatch(line)) {
      continue;
    }
    if (line.trim().isEmpty) {
      // we don't need to include multiple empty lines
      if (lastLineWasEmpty) {
        continue;
      }
      lastLineWasEmpty = true;
    } else {
      lastLineWasEmpty = false;
    }
    buffer.writeln(line);
  }
  return buffer.toString().trim();
}
