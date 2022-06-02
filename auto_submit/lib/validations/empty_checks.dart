import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:github/github.dart' as github;

import '../service/config.dart';
import '../service/github_service.dart';

class EmptyChecks extends Validation {
  EmptyChecks({
    required Config config,
  }) : super(config: config);

  @override
  Future<ValidationResult> validate(QueryResult result, github.PullRequest messagePullRequest) async {
    github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final GithubService gitHubService = await config.createGithubService(slug);
    final PullRequest pullRequest = result.repository!.pullRequest!;
    Commit commit = pullRequest.commits!.nodes!.single.commit!;
    final String? sha = commit.oid;
    List<github.CheckRun> checkRuns = await gitHubService.getCheckRuns(slug, sha!);
    String message = '- This commit has no checks. Please check that ci.yaml validation has started'
        ' and there are multiple checks. If not, try uploading an empty commit.';
    return ValidationResult(checkRuns.isNotEmpty, Action.REMOVE_LABEL, message);
  }
}
