import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/service/buildbucket.dart';

Future<void> main() async {
  print('Starting!');
  BuildBucketClient client = BuildBucketClient();

  final result = await client.scheduleBuild(
    ScheduleBuildRequest(builderId: BuilderId(project: 'flutter', bucket: 'prod', builder: 'Linux')),
  );
  client.close(force: true);
  print(result.status);
  print(result.id);
  print(result.number);
  print(result.summaryMarkdown);
}
