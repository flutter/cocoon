// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'auto_submit_query_result.g.dart';

/// The classes in this file are used to serialize/deserialize graphql results.
/// Using classes rather than complex maps improves the readability of the code
/// and makes possible to define an extensible interface for the validations.

@JsonSerializable()
class Author {
  Author({
    this.login,
  });
  final String? login;

  factory Author.fromJson(Map<String, dynamic> json) => _$AuthorFromJson(json);

  Map<String, dynamic> toJson() => _$AuthorToJson(this);
}

@JsonSerializable()
class ReviewNode {
  ReviewNode({
    this.author,
    this.authorAssociation,
    this.state,
  });
  final Author? author;
  @JsonKey(name: 'authorAssociation')
  final String? authorAssociation;
  final String? state;

  factory ReviewNode.fromJson(Map<String, dynamic> json) => _$ReviewNodeFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewNodeToJson(this);
}

@JsonSerializable()
class Reviews {
  Reviews({this.nodes});

  List<ReviewNode>? nodes;

  factory Reviews.fromJson(Map<String, dynamic> json) => _$ReviewsFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewsToJson(this);
}

@JsonSerializable()
class CommitNode {
  CommitNode({this.commit});

  Commit? commit;

  factory CommitNode.fromJson(Map<String, dynamic> json) => _$CommitNodeFromJson(json);

  Map<String, dynamic> toJson() => _$CommitNodeToJson(this);
}

@JsonSerializable()
class Commits {
  Commits({this.nodes});

  List<CommitNode>? nodes;

  factory Commits.fromJson(Map<String, dynamic> json) => _$CommitsFromJson(json);

  Map<String, dynamic> toJson() => _$CommitsToJson(this);
}

enum MergeableState {
  CONFLICTING,
  MERGEABLE,
  UNKNOWN,
}

@JsonSerializable()
class ContextNode {
  ContextNode({
    this.createdAt,
    this.context,
    this.state,
    this.targetUrl,
  });

  @JsonKey(name: 'createdAt')
  DateTime? createdAt;
  String? context;
  String? state;
  @JsonKey(name: 'targetUrl')
  String? targetUrl;

  factory ContextNode.fromJson(Map<String, dynamic> json) => _$ContextNodeFromJson(json);

  Map<String, dynamic> toJson() => _$ContextNodeToJson(this);

  @override
  String toString() => jsonEncode(_$ContextNodeToJson(this));
}

@JsonSerializable()
class Status {
  Status({this.contexts});

  List<ContextNode>? contexts;

  factory Status.fromJson(Map<String, dynamic> json) => _$StatusFromJson(json);

  Map<String, dynamic> toJson() => _$StatusToJson(this);
}

@JsonSerializable()
class Commit {
  Commit({
    this.abbreviatedOid,
    this.oid,
    this.committedDate,
    this.pushedDate,
    this.status,
  });
  @JsonKey(name: 'abbreviatedOid')
  final String? abbreviatedOid;
  final String? oid;
  @JsonKey(name: 'committedDate')
  final DateTime? committedDate;
  @JsonKey(name: 'pushedDate')
  final DateTime? pushedDate;
  final Status? status;

  factory Commit.fromJson(Map<String, dynamic> json) => _$CommitFromJson(json);

  Map<String, dynamic> toJson() => _$CommitToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.none)
class PullRequest {
  PullRequest({
    this.author,
    this.authorAssociation,
    this.id,
    this.title,
    this.body,
    this.reviews,
    this.commits,
    this.number,
    this.mergeable,
    this.isInMergeQueue = false,
  });

  final Author? author;
  final String? authorAssociation;
  final String? id;
  final String? title;
  final String? body;
  final Reviews? reviews;
  final Commits? commits;
  final int? number;
  // https://docs.github.com/en/graphql/reference/enums#mergeablestate
  final MergeableState? mergeable;
  final bool isInMergeQueue;

  factory PullRequest.fromJson(Map<String, dynamic> json) => _$PullRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PullRequestToJson(this);
}

@JsonSerializable()
class Repository {
  Repository({
    this.pullRequest,
  });

  @JsonKey(name: 'pullRequest')
  PullRequest? pullRequest;

  factory Repository.fromJson(Map<String, dynamic> json) => _$RepositoryFromJson(json);

  Map<String, dynamic> toJson() => _$RepositoryToJson(this);
}

// TODO(yjbanov): rename to AutosubmitQueryResult to avoid name clash with graphql.dart/QueryResult
@JsonSerializable()
class QueryResult {
  QueryResult({
    this.repository,
  });

  Repository? repository;

  factory QueryResult.fromJson(Map<String, dynamic> json) => _$QueryResultFromJson(json);

  Map<String, dynamic> toJson() => _$QueryResultToJson(this);
}

/// The reason for this funky naming scheme can be blamed on GitHub.
///
/// See: https://docs.github.com/en/graphql/reference/mutations#revertpullrequest
/// The enclosing object is called RevertPullRequest and has a nested field also
/// called RevertPullRequest.
@JsonSerializable()
class RevertPullRequest {
  RevertPullRequest({
    this.clientMutationId,
    this.pullRequest,
    this.revertPullRequest,
  });

  @JsonKey(name: 'clientMutationId')
  String? clientMutationId;
  @JsonKey(name: 'pullRequest')
  PullRequest? pullRequest;
  @JsonKey(name: 'revertPullRequest')
  PullRequest? revertPullRequest;

  factory RevertPullRequest.fromJson(Map<String, dynamic> json) => _$RevertPullRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RevertPullRequestToJson(this);
}

/// This is needed since the data we get is buried within this outer object and
/// to simplify the deserialization need this wrapper.
///
/// The return data is nested as such:
/// "data": {
///   "revertPullRequest": {
///     "clientMutationId": xxx,
///     "pullRequest": { ... },
///     "revertPullRequest": { ... }
///   }
/// }
@JsonSerializable()
class RevertPullRequestData {
  RevertPullRequestData({this.revertPullRequest});

  @JsonKey(name: 'revertPullRequest')
  RevertPullRequest? revertPullRequest;

  factory RevertPullRequestData.fromJson(Map<String, dynamic> json) => _$RevertPullRequestDataFromJson(json);

  Map<String, dynamic> toJson() => _$RevertPullRequestDataToJson(this);
}
