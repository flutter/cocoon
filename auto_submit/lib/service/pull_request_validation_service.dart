import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/model/pull_request_data_types.dart';
import 'package:auto_submit/request_handling/pubsub.dart';
import 'package:auto_submit/requests/graphql_queries.dart';
import 'package:auto_submit/service/approver_service.dart';
import 'package:auto_submit/service/base_validation_service.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/graphql_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:auto_submit/service/process_method.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:auto_submit/validations/validation_filter.dart';
import 'package:github/github.dart' as github;
import 'package:graphql/client.dart' as graphql;
import 'package:retry/retry.dart';

class PullRequestValidationService extends BaseValidationService {
  PullRequestValidationService(Config config, {RetryOptions? retryOptions})
      : super(config, retryOptions: retryOptions) {
    /// Validates a PR marked with the reverts label.
    approverService = ApproverService(config);
  }

  ApproverService? approverService;

  /// Processes a pub/sub message associated with PullRequest event.
  Future<void> processMessage(github.PullRequest messagePullRequest, String ackId, PubSub pubsub) async {
    final ProcessMethod processMethod = await processPullRequestMethod(messagePullRequest);

    switch (processMethod) {
      case ProcessMethod.processAutosubmit:
        await processPullRequest(
          config: config,
          result: await getNewestPullRequestInfo(config, messagePullRequest),
          messagePullRequest: messagePullRequest,
          ackId: ackId,
          pubsub: pubsub,
        );
        break;
      case ProcessMethod.processRevert:
      case ProcessMethod.doNotProcess:
        log.info('Should not process ${messagePullRequest.toJson()}, and ack the message.');
        await pubsub.acknowledge('auto-submit-queue-sub', ackId);
        break;
    }
  }

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

  /// TODO this should become validate to determine if the pr status is good.
  /// Checks if a pullRequest is still open and with autosubmit label before trying to process it.
  Future<ProcessMethod> processPullRequestMethod(github.PullRequest pullRequest) async {
    final github.RepositorySlug slug = pullRequest.base!.repo!.slug();
    final GithubService githubService = await config.createGithubService(slug);
    final github.PullRequest currentPullRequest = await githubService.getPullRequest(slug, pullRequest.number!);
    final List<String> labelNames = (currentPullRequest.labels as List<github.IssueLabel>)
        .map<String>((github.IssueLabel labelMap) => labelMap.name)
        .toList();

    final RepositoryConfiguration repositoryConfiguration = await config.getRepositoryConfiguration(slug);

    if (currentPullRequest.state == 'open' && labelNames.contains(Config.kRevertLabel)) {
      // TODO (ricardoamador) this will not make sense now that reverts happen from closed.
      // we can open the pull request but who do we assign it to? The initiating author?
      if (!repositoryConfiguration.supportNoReviewReverts) {
        log.info(
          'Cannot allow revert request (${slug.fullName}/${pullRequest.number}) without review. Processing as regular pull request.',
        );
        return ProcessMethod.processAutosubmit;
      }
      return ProcessMethod.processRevert;
    } else if (currentPullRequest.state == 'open' && labelNames.contains(Config.kAutosubmitLabel)) {
      return ProcessMethod.processAutosubmit;
    } else {
      return ProcessMethod.doNotProcess;
    }
  }

  /// Processes a PullRequest running several validations to decide whether to
  /// land the commit or remove the autosubmit label.
  Future<void> processPullRequest({
    required Config config,
    required QueryResult result,
    required github.PullRequest messagePullRequest,
    required String ackId,
    required PubSub pubsub,
  }) async {
    final List<ValidationResult> results = <ValidationResult>[];
    final github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final RepositoryConfiguration repositoryConfiguration = await config.getRepositoryConfiguration(slug);

    // filter out validations here
    final ValidationFilter validationFilter = ValidationFilter(
      config,
      ProcessMethod.processAutosubmit,
      repositoryConfiguration,
    );
    final Set<Validation> validations = validationFilter.getValidations();

    /// Runs all the validation defined in the service.
    /// If the runCi flag is false then we need a way to not run the ciSuccessful validation.
    for (Validation validation in validations) {
      final ValidationResult validationResult = await validation.validate(
        result,
        messagePullRequest,
      );
      results.add(validationResult);
    }

    final GithubService githubService = await config.createGithubService(slug);

    /// If there is at least one action that requires to remove label do so and add comments for all the failures.
    bool shouldReturn = false;
    final int prNumber = messagePullRequest.number!;
    for (ValidationResult result in results) {
      if (!result.result && result.action == Action.REMOVE_LABEL) {
        final String commmentMessage = result.message.isEmpty ? 'Validations Fail.' : result.message;
        final String message = 'auto label is removed for ${slug.fullName}, pr: $prNumber, due to $commmentMessage';
        await githubService.removeLabel(slug, prNumber, Config.kAutosubmitLabel);
        await githubService.createComment(slug, prNumber, message);
        log.info(message);
        shouldReturn = true;
      }
    }

    if (shouldReturn) {
      log.info('The pr ${slug.fullName}/$prNumber with message: $ackId should be acknowledged.');
      await pubsub.acknowledge('auto-submit-queue-sub', ackId);
      log.info('The pr ${slug.fullName}/$prNumber is not feasible for merge and message: $ackId is acknowledged.');
      return;
    }

    // If PR has some failures to ignore temporarily do nothing and continue.
    for (ValidationResult result in results) {
      if (!result.result && result.action == Action.IGNORE_TEMPORARILY) {
        return;
      }
    }

    // If we got to this point it means we are ready to submit the PR.
    final MergeResult processed = await processMerge(
      config: config,
      messagePullRequest: messagePullRequest,
    );

    if (!processed.result) {
      final String message = 'auto label is removed for ${slug.fullName}, pr: $prNumber, ${processed.message}.';
      await githubService.removeLabel(slug, prNumber, Config.kAutosubmitLabel);
      await githubService.createComment(slug, prNumber, message);
      log.info(message);
    } else {
      log.info('Pull Request ${slug.fullName}/$prNumber was merged successfully!');
      log.info('Attempting to insert a pull request record into the database for $prNumber');
      await insertPullRequestRecord(
        config: config,
        pullRequest: messagePullRequest,
        pullRequestType: PullRequestChangeType.change,
      );
    }

    log.info('Ack the processed message : $ackId.');
    await pubsub.acknowledge('auto-submit-queue-sub', ackId);
  }
}
