import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:github/github.dart';

import '../request_handling/pubsub.dart';

class MergeUpdateService {
  final Config config;

  MergeUpdateService(this.config);

  /// Updates a pull request by merging the HEAD into the current PR branch.
  Future<void> processMessage(RepositorySlug slug, int issueNumber, IssueComment issueComment, String ackId, PubSub pubsub,) async {
    final GithubService githubService = await config.createGithubService(slug);
    // Need to get the Reposlug from the issue
    if (issueComment.authorAssociation != 'MEMBER' || issueComment.authorAssociation != 'OWNER') {
      const String message = 'You must be a MEMBER or OWNER author to request a merge update.';
      log.info(message);
      // Add a message to the issue.
      await githubService.createComment(slug, issueNumber, message);
    } else {
      final String defaultBranch = (slug.name == 'flutter') ? Config.flutterDefaultBranch : Config.defaultBranch;
      final GitReference gitReference = await githubService.getReference(slug, 'heads/$defaultBranch');
      final bool status = await githubService.updateBranch(slug, issueNumber, gitReference.object!.sha!);
      String message;
      if (status) {
        message = 'Successfully merged ${gitReference.object!.sha!} into pull request $issueNumber';
        log.info(message);
      } else {
        message = 'Unable to merge ${gitReference.object!.sha!} into pull request $issueNumber';
        log.severe(message);
      }
      await githubService.createComment(slug, issueNumber, message);
    }
  }
}
