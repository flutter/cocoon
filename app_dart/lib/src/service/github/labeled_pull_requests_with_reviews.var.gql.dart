// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:cocoon_service/src/service/github/serializers.gql.dart' as _i1;

part 'labeled_pull_requests_with_reviews.var.gql.g.dart';

abstract class GLabeledPullRequestsWithReviewsVars
    implements
        Built<GLabeledPullRequestsWithReviewsVars,
            GLabeledPullRequestsWithReviewsVarsBuilder> {
  GLabeledPullRequestsWithReviewsVars._();

  factory GLabeledPullRequestsWithReviewsVars(
          [Function(GLabeledPullRequestsWithReviewsVarsBuilder b) updates]) =
      _$GLabeledPullRequestsWithReviewsVars;

  String get sOwner;
  String get sName;
  String get sLabelName;
  static Serializer<GLabeledPullRequestsWithReviewsVars> get serializer =>
      _$gLabeledPullRequestsWithReviewsVarsSerializer;
  Map<String, dynamic> toJson() => _i1.serializers
      .serializeWith(GLabeledPullRequestsWithReviewsVars.serializer, this);
  static GLabeledPullRequestsWithReviewsVars fromJson(
          Map<String, dynamic> json) =>
      _i1.serializers.deserializeWith(
          GLabeledPullRequestsWithReviewsVars.serializer, json);
}
