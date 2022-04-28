import 'package:auto_submit/service/log.dart';
import 'package:github/github.dart';

import '../service/config.dart';

class ApproverService {
  ApproverService(this.config);

  final Config config;

  approve(PullRequest pullRequest) async {
    final String? author = pullRequest.user!.login;

    if (!config.rollerAccounts.contains(author)) {
      log.info('Auto-review ignored for $author');
      return;
    }
    final RepositorySlug slug = pullRequest.base!.repo!.slug();
    final GitHub botClient = await config.createFlutterGitHubBotClient(slug);

    final CreatePullRequestReview review =
        CreatePullRequestReview(slug.owner, slug.name, pullRequest.number!, 'APPROVE');
    botClient.pullRequests.createReview(slug, review);
    log.info('Review for $author complete');
  }
}
