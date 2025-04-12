// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:gql/language.dart' as lang;
import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/firestore/github_gold_status.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/exceptions.dart';

@immutable
class PushGoldStatusToGithub extends ApiRequestHandler<Body> {
  PushGoldStatusToGithub({
    required super.config,
    required super.authenticationProvider,
    http.Client? goldClient,
    this.ingestionDelay = const Duration(seconds: 10),
  }) : goldClient = goldClient ?? http.Client();

  final http.Client goldClient;
  final Duration ingestionDelay;

  @override
  Future<Body> get() async {
    final firestoreService = await config.createFirestoreService();

    if (authContext!.clientContext.isDevelopmentEnvironment) {
      // Don't push gold status from the local dev server.
      return Body.empty;
    }

    await _sendStatusUpdates(firestoreService, Config.flutterSlug);

    return Body.empty;
  }

  Future<void> _sendStatusUpdates(
    FirestoreService firestoreService,
    RepositorySlug slug,
  ) async {
    final gitHubClient = await config.createGitHubClient(slug: slug);
    final githubGoldStatuses = <GithubGoldStatus>[];
    log.debug('Beginning Gold checks...');
    await for (PullRequest pr in gitHubClient.pullRequests.list(slug)) {
      assert(pr.number != null);
      // Get last known Gold status from firestore.
      final githubGoldStatus = await firestoreService.queryLastGoldStatus(
        slug,
        pr.number!,
      );
      CreateStatus statusRequest;

      log.debug(
        'Last known Gold status for $slug#${pr.number} was with sha: '
        '${githubGoldStatus.head}, status: ${githubGoldStatus.status}, '
        'description: ${githubGoldStatus.description}',
      );

      if (githubGoldStatus.status == GithubGoldStatus.statusCompleted &&
          githubGoldStatus.head == pr.head!.sha) {
        log.debug('Completed status already reported for this commit.');
        // We have already seen this commit and it is completed or, this is not
        // a change staged to land on master, which we should ignore.
        continue;
      }

      if (!Config.doesSkiaGoldRunOnBranch(slug, pr.base!.ref)) {
        log.debug(
          'This change\'s destination, ${pr.base!.ref}, does not run Skia Gold '
          'checks, skipping.',
        );
        // This is potentially a release branch, or another change not landing
        // on master, we don't need a Gold check.
        continue;
      }

      if (pr.draft!) {
        log.debug('This pull request is a draft.');
        // We don't want to query Gold while a PR is in a draft state, and we
        // don't want to needlessly hold a pending state either.
        // If a PR has been marked `draft` after the fact, and there has not
        // been a new commit, we cannot rescind a previously posted status, so
        // if it is already pending, we should make the contributor aware of
        // that fact.
        if (githubGoldStatus.status == GithubGoldStatus.statusRunning &&
            githubGoldStatus.head == pr.head!.sha &&
            !await _alreadyCommented(
              gitHubClient,
              pr,
              slug,
              config.flutterGoldDraftChange,
            )) {
          await gitHubClient.issues.createComment(
            slug,
            pr.number!,
            config.flutterGoldDraftChange +
                config.flutterGoldAlertConstant(slug),
          );
        }
        continue;
      }

      log.debug(
        'Querying builds for pull request #${pr.number} with sha: '
        '${githubGoldStatus.head}...',
      );
      final gitHubGraphQLClient = await config.createGitHubGraphQLClient();
      final incompleteChecks = <String>[];
      var runsGoldenFileTests = false;
      final data =
          (await _queryGraphQL(gitHubGraphQLClient, slug, pr.number!))!;
      final prData = data['repository']['pullRequest'] as Map<String, dynamic>;
      final commit =
          prData['commits']['nodes'].single['commit'] as Map<String, dynamic>;
      List<Map<String, dynamic>>? checkRuns;
      if (commit['checkSuites']['nodes'] != null &&
          (commit['checkSuites']['nodes'] as List<dynamic>).isNotEmpty) {
        checkRuns =
            (commit['checkSuites']['nodes']?.first['checkRuns']['nodes']
                    as List<dynamic>)
                .cast<Map<String, dynamic>>();
      }
      checkRuns = checkRuns ?? <Map<String, dynamic>>[];
      log.debug('This PR has ${checkRuns.length} checks.');
      for (var checkRun in checkRuns) {
        log.debug('Check run: $checkRun');
        final name = checkRun['name'].toLowerCase() as String;
        if (slug == Config.flutterSlug) {
          if (const <String>[
            // Framework test shards that run golden file tests
            'framework',
            'misc',

            // Engine test shards that run golden file tests
            // Monorepo
            'linux_android_emulator',
            'linux_host_engine',
            'linux_web_engine',
            'mac_host_engine',
            'mac_unopt',

            // Integration test shards that run golden file tests
            'android_engine_vulkan_tests',
            'android_engine_opengles_tests',
            'flutter_driver_android_test',
          ].any(name.contains)) {
            runsGoldenFileTests = true;
          }
        }
        if (checkRun['conclusion'] == null ||
            checkRun['conclusion'].toUpperCase() != 'SUCCESS') {
          incompleteChecks.add(name);
        }
      }

      if (runsGoldenFileTests) {
        log.debug('This PR executes golden file tests.');
        // Check when this PR was last updated. Gold does not keep results after
        // >20 days. If a PR has gone stale, we should draw attention to it to be
        // updated or closed.
        final updatedAt = pr.updatedAt!.toUtc();
        final twentyDaysAgo = DateTime.now().toUtc().subtract(
          const Duration(days: 20),
        );
        if (updatedAt.isBefore(twentyDaysAgo)) {
          log.debug('Stale PR, no gold status to report.');
          if (!await _alreadyCommented(
            gitHubClient,
            pr,
            slug,
            config.flutterGoldStalePR,
          )) {
            log.debug('Notifying for stale PR.');
            await gitHubClient.issues.createComment(
              slug,
              pr.number!,
              config.flutterGoldStalePR + config.flutterGoldAlertConstant(slug),
            );
          }
          continue;
        }

        // TODO(Piinks): Check after monorepo settles that this accounts for
        // framework checks added after engine checks complete, there could be a
        // hole here.
        if (incompleteChecks.isNotEmpty) {
          // If checks on an open PR are running or failing, the gold status
          // should just be pending. Any draft PRs are skipped
          // until marked ready for review.
          log.debug('Waiting for checks to be completed.');
          statusRequest = _createStatus(
            GithubGoldStatus.statusRunning,
            config.flutterGoldPending,
            slug,
            pr.number!,
          );
        } else {
          // We do not want to query Gold on a draft PR.
          assert(!pr.draft!);
          // Get Gold status.
          final goldStatus = await _getGoldStatus(slug, pr);
          statusRequest = _createStatus(
            goldStatus,
            goldStatus == GithubGoldStatus.statusRunning
                ? config.flutterGoldChanges
                : config.flutterGoldSuccess,
            slug,
            pr.number!,
          );
          log.debug(
            'New status for potential update: ${statusRequest.state}, '
            '${statusRequest.description}',
          );
          if (goldStatus == GithubGoldStatus.statusRunning &&
              !await _alreadyCommented(
                gitHubClient,
                pr,
                slug,
                config.flutterGoldCommentID(pr),
              )) {
            log.debug('Notifying for triage.');
            await _commentAndApplyGoldLabels(gitHubClient, pr, slug);
          }
        }

        // Push updates if there is a status change (detected by unique description)
        // or this is a new commit.
        if (githubGoldStatus.description != statusRequest.description ||
            githubGoldStatus.head != pr.head!.sha) {
          try {
            log.debug(
              'Pushing status to GitHub: ${statusRequest.state}, ${statusRequest.description}',
            );
            await gitHubClient.repositories.createStatus(
              slug,
              pr.head!.sha!,
              statusRequest,
            );

            githubGoldStatus.setStatus(statusRequest.state!);
            githubGoldStatus.setHead(pr.head!.sha!);
            githubGoldStatus.setUpdates(githubGoldStatus.updates + 1);
            githubGoldStatus.setDescription(statusRequest.description!);
            githubGoldStatuses.add(githubGoldStatus);
          } catch (e) {
            log.error(
              'Failed to post status update to ${slug.fullName}#${pr.number}',
              e,
            );
          }
        }
      } else {
        log.debug('This PR does not execute golden file tests.');
      }
    }
    await _updateGithubGoldStatusDocuments(
      githubGoldStatuses,
      firestoreService,
    );
    log.debug('Saved all updates to firestore for $slug');
  }

  Future<void> _updateGithubGoldStatusDocuments(
    List<GithubGoldStatus> githubGoldStatuses,
    FirestoreService firestoreService,
  ) async {
    if (githubGoldStatuses.isEmpty) {
      return;
    }
    final writes = documentsToWrites(githubGoldStatuses);
    await firestoreService.batchWriteDocuments(
      BatchWriteRequest(writes: writes),
      kDatabase,
    );
  }

  /// Returns a GitHub Status for the given state and description.
  CreateStatus _createStatus(
    String state,
    String description,
    RepositorySlug slug,
    int prNumber,
  ) {
    final statusUpdate =
        CreateStatus(state)
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
    final requestForTryjobStatus = Uri.parse(
      '${_getGoldHost(slug)}/json/v1/changelist_summary/github/${pr.number}',
    );
    try {
      log.debug('Querying Gold for image results...');
      final response = await goldClient.get(requestForTryjobStatus);
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(response.body);
      }

      final dynamic jsonResponseTriage = json.decode(response.body);
      if (jsonResponseTriage is! Map<String, dynamic>) {
        throw const FormatException(
          'Skia gold changelist summary does not match expected format.',
        );
      }
      final patchsets = jsonResponseTriage['patchsets'] as List<dynamic>;
      // Note: there can be multiple patchsets with the same id, ensure that
      // all are collected.
      var untriaged = 0;
      for (var i = 0; i < patchsets.length; i++) {
        final patchset = patchsets[i] as Map<String, dynamic>;
        if (patchset['patchset_id'] == pr.head!.sha) {
          untriaged += patchset['new_untriaged_images'] as int;
        }
      }

      if (untriaged == 0) {
        log.debug(
          'There are no unexpected image results for #${pr.number} at sha '
          '${pr.head!.sha}.',
        );

        return GithubGoldStatus.statusCompleted;
      } else {
        log.debug(
          'Tryjob for #${pr.number} at sha ${pr.head!.sha} generated new '
          'images.',
        );

        return GithubGoldStatus.statusRunning;
      }
    } on FormatException catch (e) {
      throw BadRequestException(
        'Formatting error detected requesting '
        'tryjob status for pr #${pr.number} from Flutter Gold.\n'
        'response: $response\n'
        'error: $e',
      );
    } catch (e, s) {
      log.error('Failed to get tryjob status', e, s);
      throw BadRequestException(
        'Error detected requesting tryjob status for pr '
        '#${pr.number} from Flutter Gold.\n'
        'error: $e',
      );
    }
  }

  String _getTriageUrl(RepositorySlug slug, int number) {
    return '${_getGoldHost(slug)}/cl/github/$number';
  }

  String _getGoldHost(RepositorySlug slug) {
    if (slug == Config.flutterSlug) {
      return 'https://flutter-gold.skia.org';
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
    body +=
        config.flutterGoldAlertConstant(slug) + config.flutterGoldCommentID(pr);
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
    final comments = gitHubClient.issues.listCommentsByIssue(slug, pr.number!);
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
    final comments = gitHubClient.issues.listCommentsByIssue(slug, pr.number!);
    await for (IssueComment comment in comments) {
      if (comment.body!.contains(
        config.flutterGoldInitialAlert(_getTriageUrl(slug, pr.number!)),
      )) {
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
  final result = await client.query(
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
    log.error('GraphQL query failed', result.exception);
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
