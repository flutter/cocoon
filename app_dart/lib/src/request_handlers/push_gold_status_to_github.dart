// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:gql/language.dart' as lang;
import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../model/appengine/github_gold_status_update.dart';
import '../model/firestore/github_gold_status.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/exceptions.dart';
import '../service/datastore.dart';
import '../service/logging.dart';

@immutable
class PushGoldStatusToGithub extends ApiRequestHandler<Body> {
  PushGoldStatusToGithub({
    required super.config,
    required super.authenticationProvider,
    @visibleForTesting DatastoreServiceProvider? datastoreProvider,
    http.Client? goldClient,
    this.ingestionDelay = const Duration(seconds: 10),
  })  : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        goldClient = goldClient ?? http.Client();

  final DatastoreServiceProvider datastoreProvider;
  final http.Client goldClient;
  final Duration ingestionDelay;

  @override
  Future<Body> get() async {
    final DatastoreService datastore = datastoreProvider(config.db);
    final FirestoreService firestoreService = await config.createFirestoreService();

    if (authContext!.clientContext.isDevelopmentEnvironment) {
      // Don't push gold status from the local dev server.
      return Body.empty;
    }

    await _sendStatusUpdates(datastore, firestoreService, Config.flutterSlug);
    await _sendStatusUpdates(datastore, firestoreService, Config.engineSlug);

    return Body.empty;
  }

  Future<void> _sendStatusUpdates(
    DatastoreService datastore,
    FirestoreService firestoreService,
    RepositorySlug slug,
  ) async {
    final GitHub gitHubClient = await config.createGitHubClient(slug: slug);
    final List<GithubGoldStatusUpdate> statusUpdates = <GithubGoldStatusUpdate>[];
    final List<GithubGoldStatus> githubGoldStatuses= <GithubGoldStatus>[];
    log.fine('Beginning Gold checks...');
    await for (PullRequest pr in gitHubClient.pullRequests.list(slug)) {
      assert(pr.number != null);
      // Get last known Gold status from firestore.
      final GithubGoldStatusUpdate lastUpdate = await datastore.queryLastGoldUpdate(slug, pr);
      final GithubGoldStatus githubGoldStatus = await firestoreService.queryLastGoldStatus(slug, pr.number!);
      CreateStatus statusRequest;

      log.fine('Last known Gold status for $slug#${pr.number} was with sha: '
          '${githubGoldStatus.head}, status: ${githubGoldStatus.status}, description: ${githubGoldStatus.description}');

      if (githubGoldStatus.status == GithubGoldStatus.statusCompleted && githubGoldStatus.head == pr.head!.sha) {
        log.fine('Completed status already reported for this commit.');
        // We have already seen this commit and it is completed or, this is not
        // a change staged to land on master, which we should ignore.
        continue;
      }

      final String defaultBranch = Config.defaultBranch(slug);
      if (pr.base!.ref != defaultBranch) {
        log.fine('This change is not staged to land on $defaultBranch, skipping.');
        // This is potentially a release branch, or another change not landing
        // on master, we don't need a Gold check.
        continue;
      }

      if (pr.draft!) {
        log.fine('This pull request is a draft.');
        // We don't want to query Gold while a PR is in a draft state, and we
        // don't want to needlessly hold a pending state either.
        // If a PR has been marked `draft` after the fact, and there has not
        // been a new commit, we cannot rescind a previously posted status, so
        // if it is already pending, we should make the contributor aware of
        // that fact.
        if (githubGoldStatus.status == GithubGoldStatus.statusRunning &&
            githubGoldStatus.head == pr.head!.sha &&
            !await _alreadyCommented(gitHubClient, pr, slug, config.flutterGoldDraftChange)) {
          await gitHubClient.issues
              .createComment(slug, pr.number!, config.flutterGoldDraftChange + config.flutterGoldAlertConstant(slug));
        }
        continue;
      }

      log.fine('Querying builds for pull request #${pr.number} with sha: ${githubGoldStatus.head}...');
      final GraphQLClient gitHubGraphQLClient = await config.createGitHubGraphQLClient();
      final List<String> incompleteChecks = <String>[];
      bool runsGoldenFileTests = false;
      final Map<String, dynamic> data = (await _queryGraphQL(
        gitHubGraphQLClient,
        slug,
        pr.number!,
      ))!;
      final Map<String, dynamic> prData = data['repository']['pullRequest'] as Map<String, dynamic>;
      final Map<String, dynamic> commit = prData['commits']['nodes'].single['commit'] as Map<String, dynamic>;
      List<Map<String, dynamic>>? checkRuns;
      if (commit['checkSuites']['nodes'] != null && (commit['checkSuites']['nodes'] as List<dynamic>).isNotEmpty) {
        checkRuns =
            (commit['checkSuites']['nodes']?.first['checkRuns']['nodes'] as List<dynamic>).cast<Map<String, dynamic>>();
      }
      checkRuns = checkRuns ?? <Map<String, dynamic>>[];
      log.fine('This PR has ${checkRuns.length} checks.');
      for (Map<String, dynamic> checkRun in checkRuns) {
        log.fine('Check run: $checkRun');
        final String name = checkRun['name'].toLowerCase() as String;
        if (slug == Config.engineSlug) {
          if (const <String>[
            'linux_android_emulator',
            'linux_host_engine',
            'mac_host_engine',
            'linux_web_engine',
          ].any((String shardSubString) => name.contains(shardSubString))) {
            runsGoldenFileTests = true;
          }
        } else if (slug == Config.flutterSlug) {
          if (const <String>[
            'framework',
            'misc',
          ].any((String shardSubString) => name.contains(shardSubString))) {
            runsGoldenFileTests = true;
          }
        }
        if (checkRun['conclusion'] == null || checkRun['conclusion'].toUpperCase() != 'SUCCESS') {
          incompleteChecks.add(name);
        }
      }

      if (runsGoldenFileTests) {
        log.fine('This PR executes golden file tests.');
        // Check when this PR was last updated. Gold does not keep results after
        // >20 days. If a PR has gone stale, we should draw attention to it to be
        // updated or closed.
        final DateTime updatedAt = pr.updatedAt!.toUtc();
        final DateTime twentyDaysAgo = DateTime.now().toUtc().subtract(const Duration(days: 20));
        if (updatedAt.isBefore(twentyDaysAgo)) {
          log.fine('Stale PR, no gold status to report.');
          if (!await _alreadyCommented(gitHubClient, pr, slug, config.flutterGoldStalePR)) {
            log.fine('Notifying for stale PR.');
            await gitHubClient.issues
                .createComment(slug, pr.number!, config.flutterGoldStalePR + config.flutterGoldAlertConstant(slug));
          }
          continue;
        }

        if (incompleteChecks.isNotEmpty) {
          // If checks on an open PR are running or failing, the gold status
          // should just be pending. Any draft PRs are skipped
          // until marked ready for review.
          log.fine('Waiting for checks to be completed.');
          statusRequest =
              _createStatus(GithubGoldStatus.statusRunning, config.flutterGoldPending, slug, pr.number!);
        } else {
          // We do not want to query Gold on a draft PR.
          assert(!pr.draft!);
          // Get Gold status.
          final String goldStatus = await _getGoldStatus(slug, pr);
          statusRequest = _createStatus(
            goldStatus,
            goldStatus == GithubGoldStatus.statusRunning ? config.flutterGoldChanges : config.flutterGoldSuccess,
            slug,
            pr.number!,
          );
          log.fine('New status for potential update: ${statusRequest.state}, ${statusRequest.description}');
          if (goldStatus == GithubGoldStatus.statusRunning &&
              !await _alreadyCommented(gitHubClient, pr, slug, config.flutterGoldCommentID(pr))) {
            log.fine('Notifying for triage.');
            await _commentAndApplyGoldLabels(gitHubClient, pr, slug);
          }
        }

        // Push updates if there is a status change (detected by unique description)
        // or this is a new commit.
        if (githubGoldStatus.description != statusRequest.description || githubGoldStatus.head != pr.head!.sha) {
          try {
            log.fine('Pushing status to GitHub: ${statusRequest.state}, ${statusRequest.description}');
            await gitHubClient.repositories.createStatus(slug, pr.head!.sha!, statusRequest);
            lastUpdate.status = statusRequest.state!;
            lastUpdate.head = pr.head!.sha;
            lastUpdate.updates = (lastUpdate.updates ?? 0) + 1;
            lastUpdate.description = statusRequest.description!;
            statusUpdates.add(lastUpdate);

            githubGoldStatus.setStatus(statusRequest.state!);
            githubGoldStatus.setHead(pr.head!.sha!);
            githubGoldStatus.setUpdates((lastUpdate.updates ?? 0) + 1);
            githubGoldStatus.setDescription(statusRequest.description!);
            githubGoldStatus.name = '$kDatabase/documents/$kGithubGoldStatusCollectionId/${githubGoldStatus.head}_${githubGoldStatus.prNumber}';
            githubGoldStatuses.add(githubGoldStatus);
          } catch (error) {
            log.severe('Failed to post status update to ${slug.fullName}#${pr.number}: $error');
          }
        }
      } else {
        log.fine('This PR does not execute golden file tests.');
      }
    }
    await datastore.insert(statusUpdates);
    log.fine('Committed all updates for $slug');

    // TODO(keyonghan): remove try block after fully migrated to firestore
    // https://github.com/flutter/flutter/issues/142951
    try {
      await updateGithubGoldStatusDocuments(statusUpdates, firestoreService);
    } catch (error) {
      log.warning('Failed to update github gold status in Firestore: $error');
    }
  }

  Future<void> updateGithubGoldStatusDocuments(
    List<GithubGoldStatusUpdate> statusUpdates,
    FirestoreService firestoreService,
  ) async {
    if (statusUpdates.isEmpty) {
      return;
    }
    final List<GithubGoldStatus> githubGoldStatusDocuments =
        statusUpdates.map((e) => githubGoldStatusToDocument(e)).toList();
    final List<Write> writes = documentsToWrites(githubGoldStatusDocuments);
    await firestoreService.batchWriteDocuments(BatchWriteRequest(writes: writes), kDatabase);
  }

  /// Returns a GitHub Status for the given state and description.
  CreateStatus _createStatus(String state, String description, RepositorySlug slug, int prNumber) {
    final CreateStatus statusUpdate = CreateStatus(state)
      ..targetUrl = _getTriageUrl(slug, prNumber)
      ..context = 'flutter-gold'
      ..description = description;
    return statusUpdate;
  }

  /// Used to check for any tryjob results from Flutter Gold associated with a
  /// pull request.
  Future<String> _getGoldStatus(RepositorySlug slug, PullRequest pr) async {
    // We wait for a few seconds in case tests _just_ finished and the tryjob
    // has not finished ingesting the results.
    await Future<void>.delayed(ingestionDelay);
    final Uri requestForTryjobStatus =
        Uri.parse('${_getGoldHost(slug)}/json/v1/changelist_summary/github/${pr.number}');
    try {
      log.fine('Querying Gold for image results...');
      final http.Response response = await goldClient.get(requestForTryjobStatus);
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(response.body);
      }

      final dynamic jsonResponseTriage = json.decode(response.body);
      if (jsonResponseTriage is! Map<String, dynamic>) {
        throw const FormatException('Skia gold changelist summary does not match expected format.');
      }
      final List<dynamic> patchsets = jsonResponseTriage['patchsets'] as List<dynamic>;
      int untriaged = 0;
      for (int i = 0; i < patchsets.length; i++) {
        final Map<String, dynamic> patchset = patchsets[i] as Map<String, dynamic>;
        if (patchset['patchset_id'] == pr.head!.sha) {
          untriaged = patchset['new_untriaged_images'] as int;
          break;
        }
      }

      if (untriaged == 0) {
        log.fine('There are no unexpected image results for #${pr.number} at sha '
            '${pr.head!.sha}.');

        return GithubGoldStatusUpdate.statusCompleted;
      } else {
        log.fine('Tryjob for #${pr.number} at sha ${pr.head!.sha} generated new '
            'images.');

        return GithubGoldStatusUpdate.statusRunning;
      }
    } on FormatException catch (e) {
      throw BadRequestException('Formatting error detected requesting '
          'tryjob status for pr #${pr.number} from Flutter Gold.\n'
          'response: $response\n'
          'error: $e');
    } catch (e) {
      throw BadRequestException('Error detected requesting tryjob status for pr '
          '#${pr.number} from Flutter Gold.\n'
          'error: $e');
    }
  }

  String _getTriageUrl(RepositorySlug slug, int number) {
    return '${_getGoldHost(slug)}/cl/github/$number';
  }

  String _getGoldHost(RepositorySlug slug) {
    if (slug == Config.flutterSlug) {
      return 'https://flutter-gold.skia.org';
    }

    if (slug == Config.engineSlug) {
      return 'https://flutter-engine-gold.skia.org';
    }

    throw Exception('Unknown slug: $slug');
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
      body = config.flutterGoldInitialAlert(_getTriageUrl(slug, pr.number!));
    } else {
      body = config.flutterGoldFollowUpAlert(_getTriageUrl(slug, pr.number!));
    }
    body += config.flutterGoldAlertConstant(slug) + config.flutterGoldCommentID(pr);
    await gitHubClient.issues.createComment(slug, pr.number!, body);
    await gitHubClient.issues.addLabelsToIssue(slug, pr.number!, <String>[
      'will affect goldens',
    ]);
  }

  Future<bool> _alreadyCommented(
    GitHub gitHubClient,
    PullRequest pr,
    RepositorySlug slug,
    String message,
  ) async {
    final Stream<IssueComment> comments = gitHubClient.issues.listCommentsByIssue(slug, pr.number!);
    await for (IssueComment comment in comments) {
      if (comment.body!.contains(message)) {
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
    final Stream<IssueComment> comments = gitHubClient.issues.listCommentsByIssue(slug, pr.number!);
    await for (IssueComment comment in comments) {
      if (comment.body!.contains(config.flutterGoldInitialAlert(_getTriageUrl(slug, pr.number!)))) {
        return false;
      }
    }
    return true;
  }
}

Future<Map<String, dynamic>?> _queryGraphQL(
  GraphQLClient client,
  RepositorySlug slug,
  int prNumber,
) async {
  final QueryResult result = await client.query(
    QueryOptions(
      document: lang.parseString(pullRequestChecksQuery),
      fetchPolicy: FetchPolicy.noCache,
      variables: <String, dynamic>{
        'sPullRequest': prNumber,
        'sRepoOwner': slug.owner,
        'sRepoName': slug.name,
      },
    ),
  );

  if (result.hasException) {
    log.severe(result.exception.toString());
    throw const BadRequestException('GraphQL query failed');
  }
  return result.data;
}

const String pullRequestChecksQuery = r'''
query ChecksForPullRequest($sPullRequest: Int!, $sRepoOwner: String!, $sRepoName: String!) {
  repository(owner: $sRepoOwner, name: $sRepoName) {
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
