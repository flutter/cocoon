import 'package:auto_submit/action/revert_method.dart';
import 'package:auto_submit/service/config.dart';
import 'package:github/src/common/model/pulls.dart';

class FakeRevertMethod implements RevertMethod {
  Object? object;
  bool throwException = false;

  @override
  Future<Object?> createRevert(Config config, PullRequest pullRequest) async {
    if (throwException) {
      throw 'Crappy github exception not related to the actual error.';
    }
    return object;
  }
}
