
import 'package:auto_submit/service/config.dart';
import 'package:github/github.dart' as github;

abstract class RevertMethod {
  // Allows substitution of the method of creating the revert request.
  Future<Object> createRevert(Config config, github.PullRequest pullRequest);
}