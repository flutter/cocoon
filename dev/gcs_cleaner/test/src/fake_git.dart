import 'package:gcs_cleaner/git.dart';
import 'package:process/src/interface/process_manager.dart';

class FakeGit implements Git {
  @override
  Future<String?> lookupEngineCommit(String frameworkCommit) async => 'eeeee';

  @override
  String get path => '/home/user/flutter';

  @override
  ProcessManager get pm => throw UnimplementedError();

  @override
  Future<Map<String, String>> tags() async => <String, String>{
        '3.0.0': 'abc123',
      };

  @override
  Future<DateTime?> lookupCommitTime(String sha) async {
    if (sha.contains('old')) {
      return DateTime(2020, 10, 1);
    }

    return DateTime(2023, 10, 1);
  }
}
