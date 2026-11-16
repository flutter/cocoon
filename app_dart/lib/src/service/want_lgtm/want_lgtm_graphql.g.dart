// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'want_lgtm_graphql.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GraphQLResponse _$GraphQLResponseFromJson(Map json) => _GraphQLResponse(
  repository: json['repository'] == null
      ? null
      : _GraphQLRepository.fromJson(
          Map<String, Object?>.from(json['repository'] as Map),
        ),
);

_GraphQLRepository _$GraphQLRepositoryFromJson(Map json) => _GraphQLRepository(
  pullRequest: json['pullRequest'] == null
      ? null
      : _GraphQLPullRequest.fromJson(
          Map<String, Object?>.from(json['pullRequest'] as Map),
        ),
);

_GraphQLPullRequest _$GraphQLPullRequestFromJson(Map json) =>
    _GraphQLPullRequest(
      state: json['state'] as String?,
      body: json['body'] as String?,
      headRefOid: json['headRefOid'] as String?,
      author: json['author'] == null
          ? null
          : _GraphQLActor.fromJson(
              Map<String, Object?>.from(json['author'] as Map),
            ),
      reviewRequests: json['reviewRequests'] == null
          ? null
          : _GraphQLConnection<_GraphQLReviewRequestNode>.fromJson(
              Map<String, Object?>.from(json['reviewRequests'] as Map),
              (value) => _GraphQLReviewRequestNode.fromJson(
                Map<String, Object?>.from(value as Map),
              ),
            ),
      reviews: json['reviews'] == null
          ? null
          : _GraphQLConnection<_GraphQLReviewNode>.fromJson(
              Map<String, Object?>.from(json['reviews'] as Map),
              (value) => _GraphQLReviewNode.fromJson(
                Map<String, Object?>.from(value as Map),
              ),
            ),
      timelineItems: json['timelineItems'] == null
          ? null
          : _GraphQLConnection<_GraphQLTimelineNode>.fromJson(
              Map<String, Object?>.from(json['timelineItems'] as Map),
              (value) => _GraphQLTimelineNode.fromJson(
                Map<String, Object?>.from(value as Map),
              ),
            ),
    );

_GraphQLConnection<T> _$GraphQLConnectionFromJson<T>(
  Map json,
  T Function(Object? json) fromJsonT,
) => _GraphQLConnection<T>(
  pageInfo: json['pageInfo'] == null
      ? null
      : _GraphQLPageInfo.fromJson(
          Map<String, Object?>.from(json['pageInfo'] as Map),
        ),
  nodes:
      (json['nodes'] as List<dynamic>?)
          ?.map((e) => _$nullableGenericFromJson(e, fromJsonT))
          .toList() ??
      const [],
);

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

_GraphQLPageInfo _$GraphQLPageInfoFromJson(Map json) => _GraphQLPageInfo(
  hasNextPage: json['hasNextPage'] as bool? ?? false,
  endCursor: json['endCursor'] as String?,
);

_GraphQLActor _$GraphQLActorFromJson(Map json) =>
    _GraphQLActor(login: json['login'] as String?);

_GraphQLReviewRequestNode _$GraphQLReviewRequestNodeFromJson(Map json) =>
    _GraphQLReviewRequestNode(
      requestedReviewer: json['requestedReviewer'] == null
          ? null
          : _GraphQLActor.fromJson(
              Map<String, Object?>.from(json['requestedReviewer'] as Map),
            ),
    );

_GraphQLReviewNode _$GraphQLReviewNodeFromJson(Map json) => _GraphQLReviewNode(
  author: json['author'] == null
      ? null
      : _GraphQLActor.fromJson(
          Map<String, Object?>.from(json['author'] as Map),
        ),
  state: _parseReviewState(json['state']),
  submittedAt: _tryParseUtcDateTime(json['submittedAt']),
);

_GraphQLTimelineNode _$GraphQLTimelineNodeFromJson(Map json) =>
    _GraphQLTimelineNode(
      action: _parseTimelineAction(json['__typename']),
      createdAt: _tryParseUtcDateTime(json['createdAt']),
      requestedReviewer: json['requestedReviewer'] == null
          ? null
          : _GraphQLActor.fromJson(
              Map<String, Object?>.from(json['requestedReviewer'] as Map),
            ),
    );
