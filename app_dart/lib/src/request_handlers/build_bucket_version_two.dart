import 'dart:convert';

import 'package:cocoon_service/src/request_handling/subscription_handler_v2.dart';
import 'package:cocoon_service/src/service/build_bucket_v2_client.dart';
import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/appengine/task.dart';
import '../service/logging.dart';

// https://flutter-dashboard.appspot.com/api/build-bucket-version-two

class BuildBucketVersionTwo extends SubscriptionHandlerV2 {
  /// Creates an endpoint for listening for dart-internal build results.
  /// The message should contain a single buildbucket id
  const BuildBucketVersionTwo({
    required super.cache,
    required super.config,
    super.authProvider,
    required this.buildBucketV2Client,
    @visibleForTesting this.datastoreProvider = DatastoreService.defaultProvider,
  }) : super(subscriptionName: 'bbv2-test-topic-sub');

  final BuildBucketV2Client buildBucketV2Client;
  final DatastoreServiceProvider datastoreProvider;

  @override
  Future<Body> post() async {
    final DatastoreService datastore = datastoreProvider(config.db);

    if (message.data == null) {
      log.info('no data in message');
      return Body.empty;
    }

    log.info('build bucket v2 test endpoind received schedule build request.');
    log.info(jsonDecode(message.data!));

    final bbv2.PubSubCallBack pubSubCallBack = bbv2.PubSubCallBack();
    pubSubCallBack.mergeFromProto3Json(jsonDecode(message.data!) as Map<String, dynamic>);

    final bbv2.BuildsV2PubSub buildsV2PubSub = pubSubCallBack.buildPubsub;

    if (!buildsV2PubSub.hasBuild()) {
      log.info('no build information in message');
      return Body.empty;
    } else {
      log.info('Success buildsV2PubSub decoded!');
    }

    // final bbv2.Build build = buildsV2PubSub.build;

    // final String project = build.builder.project;
    // final String bucket = build.builder.bucket;
    // final String builder = build.builder.builder;


    // log.info('Creating build request object with build id ${build.id}');

    return Body.empty;

    // final bbv2.ScheduleBuildRequest scheduleBuildRequest = bbv2.ScheduleBuildRequest.create();

    // final bbv2.GetBuildRequest getBuildRequest = bbv2.GetBuildRequest();
    // getBuildRequest.id = build.id;

    // log.info(
    //   'Calling buildbucket api to get build data for build ${build.id}',
    // );

    // bbv2.Build existingBuild = bbv2.Build.create();
    // existingBuild = await buildBucketV2Client.getBuild(getBuildRequest);

    // log.info('Got back existing builder with name: ${existingBuild.builder.builder}');

    // log.info('Checking for existing task in datastore');
    // final Task? existingTask = await datastore.getTaskFromBuildbucketV2Build(existingBuild);

    // late Task taskToInsert;
    // if (existingTask != null) {
    //   log.info('Updating Task from existing Build');
    //   existingTask.updateFromBuildbucketV2Build(existingBuild);
    //   taskToInsert = existingTask;
    // } else {
    //   log.info('Creating Task from Buildbucket result');
    //   taskToInsert = await Task.fromBuildbucketV2Build(existingBuild, datastore);
    // }

    // log.info('Inserting Task into the datastore: ${taskToInsert.toString()}');
    // await datastore.insert(<Task>[taskToInsert]);

    // return Body.forJson(taskToInsert.toString());
  }
}