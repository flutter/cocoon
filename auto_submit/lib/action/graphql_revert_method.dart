import 'dart:io';

import 'package:auto_submit/action/revert_method.dart';
// import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/requests/graphql_queries.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
// import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/graphql_service.dart';
import 'package:auto_submit/service/revert_issue_body_formatter.dart';
import 'package:github/github.dart' as github;
import 'package:graphql/client.dart' as graphql;
import 'package:auto_submit/service/log.dart';

class GraphQLRevertMethod implements RevertMethod {
  @override
  Future<github.PullRequest?> createRevert(Config config, github.PullRequest pullRequest) async {
    const String initiatingAuthor = 'ricardoamador';
    final github.RepositorySlug slug = pullRequest.base!.repo!.slug();

    // Initialize the graphql service.
    final graphql.GraphQLClient graphQLClient = await config.createGitHubGraphQLClient(slug);
    final GraphQlService graphQlService = GraphQlService();

    final String nodeId = pullRequest.nodeId!;

    log.info('Initial pull request has node id: $nodeId');

    // Format the request fields for the new revert pull request.
    final RevertIssueBodyFormatter formatter = RevertIssueBodyFormatter(
      slug: slug,
      originalPrNumber: pullRequest.number!,
      initiatingAuthor: initiatingAuthor,
      originalPrTitle: pullRequest.title!,
      originalPrBody: pullRequest.body!,
    ).format;

    // Create the mutation.
    final RevertPullRequestMutation revertPullRequestMutation = RevertPullRequestMutation(
      formatter.revertPrBody!,
      'autosubmitbot',
      false,
      nodeId,
      formatter.revertPrTitle!,
    );

    log.info('Running mutate request to graphql.');
    // Request the revert issue.
    try {
      final Map<String, dynamic> data = await graphQlService.mutateGraphQL(
        documentNode: revertPullRequestMutation.documentNode,
        variables: revertPullRequestMutation.variables,
        client: graphQLClient,
      );
    } on Exception {
      // ignore for now since we know there will definitely be an exception.
      log.info('Got expected exception.');
    }

    sleep(const Duration(seconds: 10));

    log.info('Attempting to find the created pull request...');
    github.PullRequest? pullRequestFound;
    final GithubService githubService = await config.createGithubService(slug);
    final List<github.PullRequest> pullRequests =
        await githubService.listPullRequests(slug, pages: 1, head: 'user:autosubmit-dev[bot]');
    log.info('Found ${pullRequests.length} pull requests.');
    for (github.PullRequest pr in pullRequests) {
      if (pr.title!.contains('Reverts \"${pullRequest.title}\"')) {
        pullRequestFound = pr;
      }
    }

    // Process the data returned from the graphql mutation request.
    // final RevertPullRequestData revertPullRequestData = RevertPullRequestData.fromJson(data);
    // final PullRequest revertPullRequest = revertPullRequestData.revertPullRequest!.revertPullRequest!;

    return pullRequestFound;
  }
}
