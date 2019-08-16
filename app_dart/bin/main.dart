import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';

Future<void> main(List<String> args) async {
  final buildBucketClient = BuildBucketClient();
  final SearchBuildsResponse response = await buildBucketClient.searchBuilds(
   const SearchBuildsRequest(
      predicate: BuildPredicate(
        builderId: BuilderId(
          project: 'engine',
          bucket: 'try',
        ),
        tags: <String, List<String>>{
          'user_agent': <String>['flutter-cocoon'],
        },
      ),
    ),
  );
  print(response.toJson());
  buildBucketClient.close();
}
