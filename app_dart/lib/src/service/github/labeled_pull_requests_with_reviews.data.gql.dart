// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:cocoon_service/src/service/github/schema.public.schema.gql.dart' as _i2;
import 'package:cocoon_service/src/service/github/serializers.gql.dart' as _i1;

part 'labeled_pull_requests_with_reviews.data.gql.g.dart';

abstract class GLabeledPullRequestsWithReviewsData
    implements Built<GLabeledPullRequestsWithReviewsData, GLabeledPullRequestsWithReviewsDataBuilder> {
  GLabeledPullRequestsWithReviewsData._();

  factory GLabeledPullRequestsWithReviewsData([Function(GLabeledPullRequestsWithReviewsDataBuilder b) updates]) =
      _$GLabeledPullRequestsWithReviewsData;

  static void _initializeBuilder(GLabeledPullRequestsWithReviewsDataBuilder b) => b..G__typename = 'Query';
  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  @nullable
  GLabeledPullRequestsWithReviewsData_repository get repository;
  static Serializer<GLabeledPullRequestsWithReviewsData> get serializer =>
      _$gLabeledPullRequestsWithReviewsDataSerializer;
  Map<String, dynamic> toJson() => _i1.serializers.serializeWith(GLabeledPullRequestsWithReviewsData.serializer, this);
  static GLabeledPullRequestsWithReviewsData fromJson(Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(GLabeledPullRequestsWithReviewsData.serializer, json);
}

abstract class GLabeledPullRequestsWithReviewsData_repository
    implements
        Built<GLabeledPullRequestsWithReviewsData_repository, GLabeledPullRequestsWithReviewsData_repositoryBuilder> {
  GLabeledPullRequestsWithReviewsData_repository._();

  factory GLabeledPullRequestsWithReviewsData_repository(
          [Function(GLabeledPullRequestsWithReviewsData_repositoryBuilder b) updates]) =
      _$GLabeledPullRequestsWithReviewsData_repository;

  static void _initializeBuilder(GLabeledPullRequestsWithReviewsData_repositoryBuilder b) =>
      b..G__typename = 'Repository';
  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  @nullable
  GLabeledPullRequestsWithReviewsData_repository_labels get labels;
  static Serializer<GLabeledPullRequestsWithReviewsData_repository> get serializer =>
      _$gLabeledPullRequestsWithReviewsDataRepositorySerializer;
  Map<String, dynamic> toJson() =>
      _i1.serializers.serializeWith(GLabeledPullRequestsWithReviewsData_repository.serializer, this);
  static GLabeledPullRequestsWithReviewsData_repository fromJson(Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(GLabeledPullRequestsWithReviewsData_repository.serializer, json);
}

abstract class GLabeledPullRequestsWithReviewsData_repository_labels
    implements
        Built<GLabeledPullRequestsWithReviewsData_repository_labels,
            GLabeledPullRequestsWithReviewsData_repository_labelsBuilder> {
  GLabeledPullRequestsWithReviewsData_repository_labels._();

  factory GLabeledPullRequestsWithReviewsData_repository_labels(
          [Function(GLabeledPullRequestsWithReviewsData_repository_labelsBuilder b) updates]) =
      _$GLabeledPullRequestsWithReviewsData_repository_labels;

  static void _initializeBuilder(GLabeledPullRequestsWithReviewsData_repository_labelsBuilder b) =>
      b..G__typename = 'LabelConnection';
  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  @nullable
  BuiltList<GLabeledPullRequestsWithReviewsData_repository_labels_nodes> get nodes;
  static Serializer<GLabeledPullRequestsWithReviewsData_repository_labels> get serializer =>
      _$gLabeledPullRequestsWithReviewsDataRepositoryLabelsSerializer;
  Map<String, dynamic> toJson() =>
      _i1.serializers.serializeWith(GLabeledPullRequestsWithReviewsData_repository_labels.serializer, this);
  static GLabeledPullRequestsWithReviewsData_repository_labels fromJson(Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(GLabeledPullRequestsWithReviewsData_repository_labels.serializer, json);
}

abstract class GLabeledPullRequestsWithReviewsData_repository_labels_nodes
    implements
        Built<GLabeledPullRequestsWithReviewsData_repository_labels_nodes,
            GLabeledPullRequestsWithReviewsData_repository_labels_nodesBuilder> {
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes._();

  factory GLabeledPullRequestsWithReviewsData_repository_labels_nodes(
          [Function(GLabeledPullRequestsWithReviewsData_repository_labels_nodesBuilder b) updates]) =
      _$GLabeledPullRequestsWithReviewsData_repository_labels_nodes;

  static void _initializeBuilder(GLabeledPullRequestsWithReviewsData_repository_labels_nodesBuilder b) =>
      b..G__typename = 'Label';
  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  String get id;
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests get pullRequests;
  static Serializer<GLabeledPullRequestsWithReviewsData_repository_labels_nodes> get serializer =>
      _$gLabeledPullRequestsWithReviewsDataRepositoryLabelsNodesSerializer;
  Map<String, dynamic> toJson() =>
      _i1.serializers.serializeWith(GLabeledPullRequestsWithReviewsData_repository_labels_nodes.serializer, this);
  static GLabeledPullRequestsWithReviewsData_repository_labels_nodes fromJson(Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(GLabeledPullRequestsWithReviewsData_repository_labels_nodes.serializer, json);
}

abstract class GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests
    implements
        Built<GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests,
            GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequestsBuilder> {
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests._();

  factory GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests(
          [Function(GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequestsBuilder b) updates]) =
      _$GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests;

  static void _initializeBuilder(GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequestsBuilder b) =>
      b..G__typename = 'PullRequestConnection';
  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  @nullable
  BuiltList<GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes> get nodes;
  static Serializer<GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests> get serializer =>
      _$gLabeledPullRequestsWithReviewsDataRepositoryLabelsNodesPullRequestsSerializer;
  Map<String, dynamic> toJson() => _i1.serializers
      .serializeWith(GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests.serializer, this);
  static GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests fromJson(Map<String, dynamic> json) =>
      _i1.serializers
          .deserializeWith(GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests.serializer, json);
}

abstract class GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes
    implements
        Built<GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes,
            GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodesBuilder> {
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes._();

  factory GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes(
          [Function(GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodesBuilder b) updates]) =
      _$GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes;

  static void _initializeBuilder(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodesBuilder b) =>
      b..G__typename = 'PullRequest';
  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  @nullable
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_author get author;
  String get id;
  int get number;
  _i2.GMergeableState get mergeable;
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits get commits;
  @nullable
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews get reviews;
  static Serializer<GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes> get serializer =>
      _$gLabeledPullRequestsWithReviewsDataRepositoryLabelsNodesPullRequestsNodesSerializer;
  Map<String, dynamic> toJson() => _i1.serializers
      .serializeWith(GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes.serializer, this);
  static GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes fromJson(
          Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes.serializer, json);
}

abstract class GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_author
    implements
        Built<GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_author,
            GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_authorBuilder> {
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_author._();

  factory GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_author(
      [Function(GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_authorBuilder b)
          updates]) = _$GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_author;

  static void _initializeBuilder(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_authorBuilder b) =>
      b..G__typename = 'Actor';
  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  String get login;
  static Serializer<GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_author>
      get serializer => _$gLabeledPullRequestsWithReviewsDataRepositoryLabelsNodesPullRequestsNodesAuthorSerializer;
  Map<String, dynamic> toJson() => _i1.serializers.serializeWith(
      GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_author.serializer, this);
  static GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_author fromJson(
          Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_author.serializer, json);
}

abstract class GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits
    implements
        Built<GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits,
            GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commitsBuilder> {
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits._();

  factory GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits(
      [Function(GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commitsBuilder b)
          updates]) = _$GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits;

  static void _initializeBuilder(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commitsBuilder b) =>
      b..G__typename = 'PullRequestCommitConnection';
  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  @nullable
  BuiltList<GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes> get nodes;
  static Serializer<GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits>
      get serializer => _$gLabeledPullRequestsWithReviewsDataRepositoryLabelsNodesPullRequestsNodesCommitsSerializer;
  Map<String, dynamic> toJson() => _i1.serializers.serializeWith(
      GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits.serializer, this);
  static GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits fromJson(
          Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits.serializer, json);
}

abstract class GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes
    implements
        Built<GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes,
            GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodesBuilder> {
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes._();

  factory GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes(
      [Function(GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodesBuilder b)
          updates]) = _$GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes;

  static void _initializeBuilder(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodesBuilder b) =>
      b..G__typename = 'PullRequestCommit';
  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit get commit;
  static Serializer<GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes>
      get serializer =>
          _$gLabeledPullRequestsWithReviewsDataRepositoryLabelsNodesPullRequestsNodesCommitsNodesSerializer;
  Map<String, dynamic> toJson() => _i1.serializers.serializeWith(
      GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes.serializer, this);
  static GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes fromJson(
          Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes.serializer,
          json);
}

abstract class GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit
    implements
        Built<GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit,
            GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commitBuilder> {
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit._();

  factory GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit(
      [Function(
              GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commitBuilder
                  b)
          updates]) = _$GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit;

  static void _initializeBuilder(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commitBuilder
              b) =>
      b..G__typename = 'Commit';
  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  String get abbreviatedOid;
  _i2.GGitObjectID get oid;
  _i2.GDateTime get committedDate;
  @nullable
  _i2.GDateTime get pushedDate;
  @nullable
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_status get status;
  @nullable
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites
      get checkSuites;
  static Serializer<GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit>
      get serializer =>
          _$gLabeledPullRequestsWithReviewsDataRepositoryLabelsNodesPullRequestsNodesCommitsNodesCommitSerializer;
  Map<String, dynamic> toJson() => _i1.serializers.serializeWith(
      GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit.serializer,
      this);
  static GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit fromJson(
          Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit
              .serializer,
          json);
}

abstract class GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_status
    implements
        Built<
            GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_status,
            GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_statusBuilder> {
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_status._();

  factory GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_status(
          [Function(
                  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_statusBuilder
                      b)
              updates]) =
      _$GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_status;

  static void _initializeBuilder(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_statusBuilder
              b) =>
      b..G__typename = 'Status';
  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  BuiltList<
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_status_contexts>
      get contexts;
  static Serializer<
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_status>
      get serializer =>
          _$gLabeledPullRequestsWithReviewsDataRepositoryLabelsNodesPullRequestsNodesCommitsNodesCommitStatusSerializer;
  Map<String, dynamic> toJson() => _i1.serializers.serializeWith(
      GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_status
          .serializer,
      this);
  static GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_status
      fromJson(Map<String, dynamic> json) => _i1.serializers.deserializeWith(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_status
              .serializer,
          json);
}

abstract class GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_status_contexts
    implements
        Built<
            GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_status_contexts,
            GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_status_contextsBuilder> {
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_status_contexts._();

  factory GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_status_contexts(
          [Function(
                  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_status_contextsBuilder
                      b)
              updates]) =
      _$GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_status_contexts;

  static void _initializeBuilder(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_status_contextsBuilder
              b) =>
      b..G__typename = 'StatusContext';
  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  String get context;
  _i2.GStatusState get state;
  static Serializer<
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_status_contexts>
      get serializer =>
          _$gLabeledPullRequestsWithReviewsDataRepositoryLabelsNodesPullRequestsNodesCommitsNodesCommitStatusContextsSerializer;
  Map<String, dynamic> toJson() => _i1.serializers.serializeWith(
      GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_status_contexts
          .serializer,
      this);
  static GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_status_contexts
      fromJson(Map<String, dynamic> json) => _i1.serializers.deserializeWith(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_status_contexts
              .serializer,
          json);
}

abstract class GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites
    implements
        Built<
            GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites,
            GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuitesBuilder> {
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites._();

  factory GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites(
          [Function(
                  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuitesBuilder
                      b)
              updates]) =
      _$GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites;

  static void _initializeBuilder(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuitesBuilder
              b) =>
      b..G__typename = 'CheckSuiteConnection';
  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  @nullable
  BuiltList<
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes>
      get nodes;
  static Serializer<
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites>
      get serializer =>
          _$gLabeledPullRequestsWithReviewsDataRepositoryLabelsNodesPullRequestsNodesCommitsNodesCommitCheckSuitesSerializer;
  Map<String, dynamic> toJson() => _i1.serializers.serializeWith(
      GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites
          .serializer,
      this);
  static GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites
      fromJson(Map<String, dynamic> json) => _i1.serializers.deserializeWith(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites
              .serializer,
          json);
}

abstract class GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes
    implements
        Built<
            GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes,
            GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodesBuilder> {
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes._();

  factory GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes(
          [Function(
                  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodesBuilder
                      b)
              updates]) =
      _$GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes;

  static void _initializeBuilder(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodesBuilder
              b) =>
      b..G__typename = 'CheckSuite';
  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  @nullable
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRuns
      get checkRuns;
  static Serializer<
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes>
      get serializer =>
          _$gLabeledPullRequestsWithReviewsDataRepositoryLabelsNodesPullRequestsNodesCommitsNodesCommitCheckSuitesNodesSerializer;
  Map<String, dynamic> toJson() => _i1.serializers.serializeWith(
      GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes
          .serializer,
      this);
  static GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes
      fromJson(Map<String, dynamic> json) => _i1.serializers.deserializeWith(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes
              .serializer,
          json);
}

abstract class GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRuns
    implements
        Built<
            GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRuns,
            GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRunsBuilder> {
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRuns._();

  factory GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRuns(
          [Function(
                  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRunsBuilder
                      b)
              updates]) =
      _$GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRuns;

  static void _initializeBuilder(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRunsBuilder
              b) =>
      b..G__typename = 'CheckRunConnection';
  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  @nullable
  BuiltList<
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRuns_nodes>
      get nodes;
  static Serializer<
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRuns>
      get serializer =>
          _$gLabeledPullRequestsWithReviewsDataRepositoryLabelsNodesPullRequestsNodesCommitsNodesCommitCheckSuitesNodesCheckRunsSerializer;
  Map<String, dynamic> toJson() => _i1.serializers.serializeWith(
      GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRuns
          .serializer,
      this);
  static GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRuns
      fromJson(Map<String, dynamic> json) => _i1.serializers.deserializeWith(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRuns
              .serializer,
          json);
}

abstract class GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRuns_nodes
    implements
        Built<
            GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRuns_nodes,
            GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRuns_nodesBuilder> {
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRuns_nodes._();

  factory GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRuns_nodes(
          [Function(
                  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRuns_nodesBuilder
                      b)
              updates]) =
      _$GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRuns_nodes;

  static void _initializeBuilder(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRuns_nodesBuilder
              b) =>
      b..G__typename = 'CheckRun';
  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  String get name;
  _i2.GCheckStatusState get status;
  @nullable
  _i2.GCheckConclusionState get conclusion;
  static Serializer<
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRuns_nodes>
      get serializer =>
          _$gLabeledPullRequestsWithReviewsDataRepositoryLabelsNodesPullRequestsNodesCommitsNodesCommitCheckSuitesNodesCheckRunsNodesSerializer;
  Map<String, dynamic> toJson() => _i1.serializers.serializeWith(
      GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRuns_nodes
          .serializer,
      this);
  static GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRuns_nodes
      fromJson(Map<String, dynamic> json) => _i1.serializers.deserializeWith(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_commits_nodes_commit_checkSuites_nodes_checkRuns_nodes
              .serializer,
          json);
}

abstract class GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews
    implements
        Built<GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews,
            GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviewsBuilder> {
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews._();

  factory GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews(
      [Function(GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviewsBuilder b)
          updates]) = _$GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews;

  static void _initializeBuilder(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviewsBuilder b) =>
      b..G__typename = 'PullRequestReviewConnection';
  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  @nullable
  BuiltList<GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodes> get nodes;
  static Serializer<GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews>
      get serializer => _$gLabeledPullRequestsWithReviewsDataRepositoryLabelsNodesPullRequestsNodesReviewsSerializer;
  Map<String, dynamic> toJson() => _i1.serializers.serializeWith(
      GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews.serializer, this);
  static GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews fromJson(
          Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews.serializer, json);
}

abstract class GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodes
    implements
        Built<GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodes,
            GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodesBuilder> {
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodes._();

  factory GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodes(
      [Function(GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodesBuilder b)
          updates]) = _$GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodes;

  static void _initializeBuilder(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodesBuilder b) =>
      b..G__typename = 'PullRequestReview';
  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  @nullable
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodes_author get author;
  _i2.GCommentAuthorAssociation get authorAssociation;
  _i2.GPullRequestReviewState get state;
  static Serializer<GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodes>
      get serializer =>
          _$gLabeledPullRequestsWithReviewsDataRepositoryLabelsNodesPullRequestsNodesReviewsNodesSerializer;
  Map<String, dynamic> toJson() => _i1.serializers.serializeWith(
      GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodes.serializer, this);
  static GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodes fromJson(
          Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodes.serializer,
          json);
}

abstract class GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodes_author
    implements
        Built<GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodes_author,
            GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodes_authorBuilder> {
  GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodes_author._();

  factory GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodes_author(
      [Function(
              GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodes_authorBuilder
                  b)
          updates]) = _$GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodes_author;

  static void _initializeBuilder(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodes_authorBuilder
              b) =>
      b..G__typename = 'Actor';
  @BuiltValueField(wireName: '__typename')
  String get G__typename;
  String get login;
  static Serializer<GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodes_author>
      get serializer =>
          _$gLabeledPullRequestsWithReviewsDataRepositoryLabelsNodesPullRequestsNodesReviewsNodesAuthorSerializer;
  Map<String, dynamic> toJson() => _i1.serializers.serializeWith(
      GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodes_author.serializer,
      this);
  static GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodes_author fromJson(
          Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(
          GLabeledPullRequestsWithReviewsData_repository_labels_nodes_pullRequests_nodes_reviews_nodes_author
              .serializer,
          json);
}
