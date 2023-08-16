import 'package:auto_submit/action/revert_method.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/requests/graphql_queries.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/graphql_service.dart';
import 'package:auto_submit/service/revert_issue_body_formatter.dart';
import 'package:github/github.dart' as github;
import 'package:graphql/client.dart' as graphql;
import 'package:auto_submit/service/log.dart';

class GraphQLRevertMethod implements RevertMethod {
  @override
  Future<PullRequest?> createRevert(Config config, github.PullRequest pullRequest) async {
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

    // This fails reliably with graphql and will always return an exception though will
    // sometimes generate the revert request. Though this is not reliable.
    final Map<String, dynamic> data = await graphQlService.mutateGraphQL(
      documentNode: revertPullRequestMutation.documentNode,
      variables: revertPullRequestMutation.variables,
      client: graphQLClient,
    );

    // Process the data returned from the graphql mutation request.
    final RevertPullRequestData revertPullRequestData = RevertPullRequestData.fromJson(data);
    final PullRequest revertPullRequest = revertPullRequestData.revertPullRequest!.revertPullRequest!;

    return revertPullRequest;
  }
}
