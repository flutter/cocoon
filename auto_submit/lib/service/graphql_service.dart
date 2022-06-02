import 'package:auto_submit/requests/check_pull_request_queries.dart';
import 'package:auto_submit/service/log.dart';
import 'package:github/github.dart';
import 'package:graphql/client.dart';

import '../requests/exceptions.dart';

class GraphQlService {
  Future<Map<String, dynamic>> queryGraphQL(
    RepositorySlug slug,
    int prNumber,
    GraphQLClient client,
  ) async {
    final QueryResult result = await client.query(
      QueryOptions(
        document: pullRequestWithReviewsQuery,
        fetchPolicy: FetchPolicy.noCache,
        variables: <String, dynamic>{
          'sOwner': slug.owner,
          'sName': slug.name,
          'sPrNumber': prNumber,
        },
      ),
    );

    if (result.hasException) {
      log.severe(result.exception.toString());
      throw const BadRequestException('GraphQL query failed');
    }
    return result.data!;
  }
}
