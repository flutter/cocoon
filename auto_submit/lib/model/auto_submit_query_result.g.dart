// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_submit_query_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Author _$AuthorFromJson(Map<String, dynamic> json) => Author(
      login: json['login'] as String?,
    );

Map<String, dynamic> _$AuthorToJson(Author instance) => <String, dynamic>{
      'login': instance.login,
    };

ReviewNode _$ReviewNodeFromJson(Map<String, dynamic> json) => ReviewNode(
      author: json['author'] == null ? null : Author.fromJson(json['author'] as Map<String, dynamic>),
      authorAssociation: json['authorAssociation'] as String?,
      state: json['state'] as String?,
    );

Map<String, dynamic> _$ReviewNodeToJson(ReviewNode instance) => <String, dynamic>{
      'author': instance.author,
      'authorAssociation': instance.authorAssociation,
      'state': instance.state,
    };

Reviews _$ReviewsFromJson(Map<String, dynamic> json) => Reviews(
      nodes: (json['nodes'] as List<dynamic>?)?.map((e) => ReviewNode.fromJson(e as Map<String, dynamic>)).toList(),
    );

Map<String, dynamic> _$ReviewsToJson(Reviews instance) => <String, dynamic>{
      'nodes': instance.nodes,
    };

CommitNode _$CommitNodeFromJson(Map<String, dynamic> json) => CommitNode(
      commit: json['commit'] == null ? null : Commit.fromJson(json['commit'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CommitNodeToJson(CommitNode instance) => <String, dynamic>{
      'commit': instance.commit,
    };

Commits _$CommitsFromJson(Map<String, dynamic> json) => Commits(
      nodes: (json['nodes'] as List<dynamic>?)?.map((e) => CommitNode.fromJson(e as Map<String, dynamic>)).toList(),
    );

Map<String, dynamic> _$CommitsToJson(Commits instance) => <String, dynamic>{
      'nodes': instance.nodes,
    };

ContextNode _$ContextNodeFromJson(Map<String, dynamic> json) => ContextNode(
      context: json['context'] as String?,
      state: json['state'] as String?,
      targetUrl: json['targetUrl'] as String?,
    );

Map<String, dynamic> _$ContextNodeToJson(ContextNode instance) => <String, dynamic>{
      'context': instance.context,
      'state': instance.state,
      'targetUrl': instance.targetUrl,
    };

Status _$StatusFromJson(Map<String, dynamic> json) => Status(
      contexts:
          (json['contexts'] as List<dynamic>?)?.map((e) => ContextNode.fromJson(e as Map<String, dynamic>)).toList(),
    );

Map<String, dynamic> _$StatusToJson(Status instance) => <String, dynamic>{
      'contexts': instance.contexts,
    };

Commit _$CommitFromJson(Map<String, dynamic> json) => Commit(
      abbreviatedOid: json['abbreviatedOid'] as String?,
      oid: json['oid'] as String?,
      committedDate: json['committedDate'] == null ? null : DateTime.parse(json['committedDate'] as String),
      pushedDate: json['pushedDate'] == null ? null : DateTime.parse(json['pushedDate'] as String),
      status: json['status'] == null ? null : Status.fromJson(json['status'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CommitToJson(Commit instance) => <String, dynamic>{
      'abbreviatedOid': instance.abbreviatedOid,
      'oid': instance.oid,
      'committedDate': instance.committedDate?.toIso8601String(),
      'pushedDate': instance.pushedDate?.toIso8601String(),
      'status': instance.status,
    };

PullRequest _$PullRequestFromJson(Map<String, dynamic> json) => PullRequest(
      author: json['author'] == null ? null : Author.fromJson(json['author'] as Map<String, dynamic>),
      authorAssociation: json['authorAssociation'] as String?,
      id: json['id'] as String?,
      number: json['number'] as int?,
      title: json['title'] as String?,
      body: json['body'] as String?,
      reviews: json['reviews'] == null ? null : Reviews.fromJson(json['reviews'] as Map<String, dynamic>),
      commits: json['commits'] == null ? null : Commits.fromJson(json['commits'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PullRequestToJson(PullRequest instance) => <String, dynamic>{
      'author': instance.author,
      'authorAssociation': instance.authorAssociation,
      'id': instance.id,
      'number': instance.number,
      'title': instance.title,
      'body': instance.body,
      'reviews': instance.reviews,
      'commits': instance.commits,
    };

Repository _$RepositoryFromJson(Map<String, dynamic> json) => Repository(
      pullRequest:
          json['pullRequest'] == null ? null : PullRequest.fromJson(json['pullRequest'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RepositoryToJson(Repository instance) => <String, dynamic>{
      'pullRequest': instance.pullRequest,
    };

QueryResult _$QueryResultFromJson(Map<String, dynamic> json) => QueryResult(
      repository: json['repository'] == null ? null : Repository.fromJson(json['repository'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$QueryResultToJson(QueryResult instance) => <String, dynamic>{
      'repository': instance.repository,
    };

RevertPullRequest _$RevertPullRequestFromJson(Map<String, dynamic> json) => RevertPullRequest(
      clientMutationId: json['clientMutationId'] as String?,
      pullRequest:
          json['pullRequest'] == null ? null : PullRequest.fromJson(json['pullRequest'] as Map<String, dynamic>),
      revertPullRequest: json['revertPullRequest'] == null
          ? null
          : PullRequest.fromJson(json['revertPullRequest'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RevertPullRequestToJson(RevertPullRequest instance) => <String, dynamic>{
      'clientMutationId': instance.clientMutationId,
      'pullRequest': instance.pullRequest,
      'revertPullRequest': instance.revertPullRequest,
    };

RevertPullRequestData _$RevertPullRequestDataFromJson(Map<String, dynamic> json) => RevertPullRequestData(
      revertPullRequest: json['revertPullRequest'] == null
          ? null
          : RevertPullRequest.fromJson(json['revertPullRequest'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RevertPullRequestDataToJson(RevertPullRequestData instance) => <String, dynamic>{
      'revertPullRequest': instance.revertPullRequest,
    };
