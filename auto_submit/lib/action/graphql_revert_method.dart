import 'package:auto_submit/action/revert_method.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/requests/graphql_queries.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/graphql_service.dart';
import 'package:auto_submit/service/revert_issue_body_formatter.dart';
import 'package:github/github.dart' as github;
import 'package:graphql/client.dart' as graphql;

/// The graphql revert method uses the new revert mutation introduced by github.
///
/// Note: In order to make this work you need to enable the permission to push in
/// the application otherwise a cryptic error stating an issue that there are no
/// commits between the head and the target branch.
/// https://support.github.com/ticket/personal/0/2258630
class GraphQLRevertMethod implements RevertMethod {
  @override
  Future<PullRequest> createRevert(Config config, github.PullRequest pullRequest) async {
    const String initiatingAuthor = 'ricardoamador';
    final github.RepositorySlug slug = pullRequest.base!.repo!.slug();

    // Initialize the graphql service.
    final graphql.GraphQLClient graphQLClient = await config.createGitHubGraphQLClient(slug);
    final GraphQlService graphQlService = GraphQlService();

    final String nodeId = pullRequest.nodeId!;

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
