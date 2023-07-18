import 'package:auto_submit/action/revert_method.dart';
import 'package:auto_submit/git/cli_command.dart';
import 'package:auto_submit/git/git_access_method.dart';
import 'package:auto_submit/git/git_cli.dart';
import 'package:auto_submit/git/git_repository_manager.dart';
import 'package:auto_submit/service/config.dart';
import 'package:github/github.dart' as gh;

// TODO update this as this is the old probably non working code.
class GitCliRevertMethod implements RevertMethod {
  GitCliRevertMethod();

  Future<void> processRevertRequest(
    gh.RepositorySlug slug,
    String workingDirectory,
    GitAccessMethod gitAccessMethod,
    String commitSha,
  ) async {
    final GitRepositoryManager repositoryManager = GitRepositoryManager(
      slug: slug,
      //path/to/working/directory/
      workingDirectory: workingDirectory,
      //flutter_453a23
      cloneToDirectory: '${slug.name}_$commitSha',
      gitCli: GitCli(gitAccessMethod, CliCommand()),
    );

    // final String cloneToFullPath = '$workingDirectory/${slug.name}_$commitSha';
    try {
      await repositoryManager.cloneRepository();
      await repositoryManager.revertCommit('main', commitSha);
    } finally {
      await repositoryManager.deleteRepository();
    }
  }

  @override
  Future<Object> createRevert(Config config, gh.PullRequest pullRequest) {
    // TODO: implement createRevert
    throw UnimplementedError();
  }
}