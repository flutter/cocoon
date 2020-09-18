// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:github/github.dart';
import 'package:graphql/client.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../model/appengine/github_gold_status_update.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/datastore.dart';

@immutable
class PushGoldStatusToGithub extends ApiRequestHandler<Body> {
  PushGoldStatusToGithub(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
    @visibleForTesting LoggingProvider loggingProvider,
    HttpClient goldClient,
  })  : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        loggingProvider = loggingProvider ?? Providers.serviceScopeLogger,
        goldClient = goldClient ?? HttpClient(),
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;
  final LoggingProvider loggingProvider;
  final HttpClient goldClient;

  @override
  Future<Body> get() async {
    final Logging log = loggingProvider();
    final DatastoreService datastore = datastoreProvider(config.db);

    if (authContext.clientContext.isDevelopmentEnvironment) {
      // Don't push gold status from the local dev server.
      return Body.empty;
    }

    final RepositorySlug slug = RepositorySlug('flutter', 'flutter');
    final GitHub gitHubClient = await config.createGitHubClient(slug.owner, slug.name);
    final List<GithubGoldStatusUpdate> statusUpdates = <GithubGoldStatusUpdate>[];
    log.debug('Beginning Gold checks...');
    await for (PullRequest pr in gitHubClient.pullRequests.list(slug)) {
      // Check when this PR was last updated. Gold does not keep results after
      // >20 days. If a PR has gone stale, we should draw attention to it to be
      // updated or closed.
      final DateTime updatedAt = pr.updatedAt.toUtc();
      final DateTime twentyDaysAgo = DateTime.now().toUtc().subtract(const Duration(days: 20));
      if (updatedAt.isBefore(twentyDaysAgo)) {
        log.debug('Stale PR, no gold status to report.');
        if (!await _alreadyCommented(gitHubClient, pr, slug, config.flutterGoldStalePR)) {
          log.debug('Notifying for stale PR.');
          await gitHubClient.issues.createComment(slug, pr.number, config.flutterGoldStalePR);
        }
        continue;
      }

      // Get last known Gold status from datastore.
      final GithubGoldStatusUpdate lastUpdate = await datastore.queryLastGoldUpdate(slug, pr);
      CreateStatus statusRequest;

      log.debug('Last known Gold status for #${pr.number} was with sha: '
          '${lastUpdate.head}, status: ${lastUpdate.status}, description: ${lastUpdate.description}');

      if (lastUpdate.status == GithubGoldStatusUpdate.statusCompleted && lastUpdate.head == pr.head.sha) {
        log.debug('Completed status already reported for this commit.');
        // We have already seen this commit and it is completed or, this is not
        // a change staged to land on master, which we should ignore.
        continue;
      }

      if (pr.base.ref != 'master') {
        log.debug('This change is not staged to land on master, skipping.');
        // This is potentially a release branch, or another change not landing
        // on master, we don't need a Gold check.
        continue;
      }

      if (pr.draft) {
        log.debug('This pull request is a draft.');
        // We don't want to query Gold while a PR is in a draft state, and we
        // don't want to needlessly hold a pending state either.
        // If a PR has been marked `draft` after the fact, and there has not
        // been a new commit, we cannot rescind a previously posted status, so
        // if it is already pending, we should make the contributor aware of
        // that fact.
        if (lastUpdate.status == GithubGoldStatusUpdate.statusRunning &&
            lastUpdate.head == pr.head.sha &&
            !await _alreadyCommented(gitHubClient, pr, slug, config.flutterGoldDraftChange)) {
          await gitHubClient.issues.createComment(slug, pr.number, config.flutterGoldDraftChange);
        }
        continue;
      }

      log.debug('Querying builds for pull request #${pr.number}...');
      final GraphQLClient gitHubGraphQLClient = await config.createGitHubGraphQLClient();
      final List<String> incompleteChecks = <String>[];
      bool runsGoldenFileTests = false;
      final Map<String, dynamic> data = await _queryGraphQL(
        log,
        gitHubGraphQLClient,
        pr.number,
      );
      final Map<String, dynamic> prData = data['repository']['pullRequest'] as Map<String, dynamic>;
      final Map<String, dynamic> commit = prData['commits']['nodes'].single['commit'] as Map<String, dynamic>;
      List<Map<String, dynamic>> checkRuns;
      if (commit['checkSuites']['nodes'] != null && (commit['checkSuites']['nodes'] as List<dynamic>).isNotEmpty) {
        checkRuns =
            (commit['checkSuites']['nodes']?.first['checkRuns']['nodes'] as List<dynamic>).cast<Map<String, dynamic>>();
      }
      checkRuns = checkRuns ?? <Map<String, dynamic>>[];
      for (Map<String, dynamic> checkRun in checkRuns) {
        log.debug('Found check run: $checkRun');
        final String name = checkRun['name'].toLowerCase() as String;
        if (name.contains('framework') || name.contains('web')) {
          runsGoldenFileTests = true;
        }
        if (checkRun['conclusion'] == null || checkRun['conclusion'].toUpperCase() != 'SUCCESS') {
          incompleteChecks.add(name);
        }
      }

      if (runsGoldenFileTests) {
        if (incompleteChecks.isNotEmpty) {
          // If checks on an open PR are running or failing, the gold status
          // should just be pending. Any draft PRs are skipped
          // until marked ready for review.
          log.debug('Waiting for checks to be completed.');
          statusRequest = _createStatus(GithubGoldStatusUpdate.statusRunning, config.flutterGoldPending, pr.number);
        } else {
          // We do not want to query Gold on a draft PR.
          assert(!pr.draft);
          // Get Gold status.
          final String goldStatus = await _getGoldStatus(pr, log);
          statusRequest = _createStatus(
              goldStatus,
              goldStatus == GithubGoldStatusUpdate.statusRunning
                  ? config.flutterGoldChanges
                  : config.flutterGoldSuccess,
              pr.number);
          log.debug('New status for potential update: ${statusRequest.state}, ${statusRequest.description}');
          if (goldStatus == GithubGoldStatusUpdate.statusRunning &&
              !await _alreadyCommented(gitHubClient, pr, slug, config.flutterGoldCommentID(pr))) {
            log.debug('Notifying for triage.');
            await _commentAndApplyGoldLabels(gitHubClient, pr, slug);
          }
        }

        // Push updates if there is a status change (detected by unique description)
        // or this is a new commit.
        if (lastUpdate.description != statusRequest.description || lastUpdate.head != pr.head.sha) {
          try {
            log.debug('Pushing status to GitHub: ${statusRequest.state}, ${statusRequest.description}');
            await gitHubClient.repositories.createStatus(slug, pr.head.sha, statusRequest);
            lastUpdate.status = statusRequest.state;
            lastUpdate.head = pr.head.sha;
            lastUpdate.updates += 1;
            lastUpdate.description = statusRequest.description;
            statusUpdates.add(lastUpdate);
          } catch (error) {
            log.error('Failed to post status update to ${slug.fullName}#${pr.number}: $error');
          }
        }
      }
    }
    await datastore.insert(statusUpdates);
    log.debug('Committed all updates');

    return Body.empty;
  }

  /// Returns a GitHub Status for the given state and description.
  CreateStatus _createStatus(String state, String description, int prNumber) {
    final CreateStatus statusUpdate = CreateStatus(state)
      ..targetUrl = _getTriageUrl(prNumber)
      ..context = 'flutter-gold'
      ..description = description;
    return statusUpdate;
  }

  /// Used to check for any tryjob results from Flutter Gold associated with a
  /// pull request.
  Future<String> _getGoldStatus(PullRequest pr, Logging log) async {
    // We wait for a few seconds in case tests _just_ finished and the tryjob
    // has not finished ingesting the results.
    await Future<void>.delayed(const Duration(seconds: 10));
    final Uri requestForTryjobStatus =
        Uri.parse('http://flutter-gold.skia.org/json/v1/changelist/github/${pr.number}/${pr.head.sha}/untriaged');
    String rawResponse;
    try {
      final HttpClientRequest request = await goldClient.getUrl(requestForTryjobStatus);
      final HttpClientResponse response = await request.close();

      rawResponse = await utf8.decodeStream(response);
      final Map<String, dynamic> decodedResponse = json.decode(rawResponse) as Map<String, dynamic>;

      if (decodedResponse['digests'] == null) {
        log.debug('There are no unexpected image results for #${pr.number} at sha '
            '${pr.head.sha}.');

        return GithubGoldStatusUpdate.statusCompleted;
      } else {
        log.debug('Tryjob for #${pr.number} at sha ${pr.head.sha} generated new '
            'images.}');

        return GithubGoldStatusUpdate.statusRunning;
      }
    } on FormatException catch (_) {
      throw BadRequestException('Formatting error detected requesting '
          'tryjob status for pr #${pr.number} from Flutter Gold.\n'
          'rawResponse: $rawResponse');
    } catch (e) {
      throw BadRequestException('Error detected requesting tryjob status for pr '
          '#${pr.number} from Flutter Gold.\n'
          'error: $e');
    }
  }

  String _getTriageUrl(int number) {
    return 'https://flutter-gold.skia.org/search?issue=$number&new_clstore=true';
  }

  /// Creates a comment on a given pull request identified to have golden file
  /// changes and applies the `will affect goldens` label.
  Future<void> _commentAndApplyGoldLabels(
    GitHub gitHubClient,
    PullRequest pr,
    RepositorySlug slug,
  ) async {
    String body;
    if (await _isFirstComment(gitHubClient, pr, slug)) {
      body = config.flutterGoldInitialAlert(_getTriageUrl(pr.number)) + config.flutterGoldAlertConstant;
    } else {
      body = config.flutterGoldFollowUpAlert(_getTriageUrl(pr.number));
    }
    body += config.flutterGoldCommentID(pr);
    await gitHubClient.issues.createComment(slug, pr.number, body);
    await gitHubClient.issues.addLabelsToIssue(slug, pr.number, <String>[
      'will affect goldens',
    ]);
  }

  Future<bool> _alreadyCommented(
    GitHub gitHubClient,
    PullRequest pr,
    RepositorySlug slug,
    String message,
  ) async {
    final Stream<IssueComment> comments = gitHubClient.issues.listCommentsByIssue(slug, pr.number);
    await for (IssueComment comment in comments) {
      if (comment.body.contains(message)) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _isFirstComment(
    GitHub gitHubClient,
    PullRequest pr,
    RepositorySlug slug,
  ) async {
    final Stream<IssueComment> comments = gitHubClient.issues.listCommentsByIssue(slug, pr.number);
    await for (IssueComment comment in comments) {
      if (comment.body.contains(config.flutterGoldInitialAlert(_getTriageUrl(pr.number)))) {
        return false;
      }
    }
    return true;
  }
}

Future<Map<String, dynamic>> _queryGraphQL(Logging log, GraphQLClient client, int prNumber) async {
  final QueryResult result = await client.query(
    QueryOptions(
      document: pullRequestChecksQuery,
      fetchPolicy: FetchPolicy.noCache,
      variables: <String, dynamic>{
        'sPullRequest': prNumber,
      },
    ),
  );

  if (result.hasErrors) {
    for (GraphQLError error in result.errors) {
      log.error(error.toString());
    }
    throw const BadRequestException('GraphQL query failed');
  }
  return result.data as Map<String, dynamic>;
}

const String pullRequestChecksQuery = r'''
query ChecksForPullRequest($sPullRequest: Int!) {
  repository(owner: "flutter", name: "flutter") {
    pullRequest(number: $sPullRequest) {
      commits(last: 1) {
        nodes {
          commit {
            # (appId: 64368) == flutter-dashboard. We only care about
            # flutter-dashboard checks.
            checkSuites(last: 1, filterBy: {appId: 64368}) {
              nodes {
                checkRuns(first: 100) {
                  nodes {
                    name
                    status
                    conclusion
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}''';
