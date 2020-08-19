// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:cocoon_service/src/service/github/schema.public.schema.gql.dart'
    as _i1;

class $LabeledPullRequestsWithReviews {
  const $LabeledPullRequestsWithReviews(this.data);

  final Map<String, dynamic> data;

  $LabeledPullRequestsWithReviews$repository get repository =>
      data['repository'] == null
          ? null
          : $LabeledPullRequestsWithReviews$repository(
              (data['repository'] as Map<String, dynamic>));
}

class $LabeledPullRequestsWithReviews$repository {
  const $LabeledPullRequestsWithReviews$repository(this.data);

  final Map<String, dynamic> data;

  $LabeledPullRequestsWithReviews$repository$labels get labels =>
      data['labels'] == null
          ? null
          : $LabeledPullRequestsWithReviews$repository$labels(
              (data['labels'] as Map<String, dynamic>));
}

class $LabeledPullRequestsWithReviews$repository$labels {
  const $LabeledPullRequestsWithReviews$repository$labels(this.data);

  final Map<String, dynamic> data;

  List<$LabeledPullRequestsWithReviews$repository$labels$nodes> get nodes =>
      data['nodes'] == null
          ? null
          : (data['nodes'] as List)
              .map((dynamic e) =>
                  $LabeledPullRequestsWithReviews$repository$labels$nodes(
                      (e as Map<String, dynamic>)))
              .toList();
}

class $LabeledPullRequestsWithReviews$repository$labels$nodes {
  const $LabeledPullRequestsWithReviews$repository$labels$nodes(this.data);

  final Map<String, dynamic> data;

  String get id => (data['id'] as String);
  $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests
      get pullRequests => data['pullRequests'] == null
          ? null
          : $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests(
              (data['pullRequests'] as Map<String, dynamic>));
}

class $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests {
  const $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests(
      this.data);

  final Map<String, dynamic> data;

  List<$LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes>
      get nodes => data['nodes'] == null
          ? null
          : (data['nodes'] as List)
              .map((dynamic e) =>
                  $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes(
                      (e as Map<String, dynamic>)))
              .toList();
}

class $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes {
  const $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes(
      this.data);

  final Map<String, dynamic> data;

  $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$author
      get author => data['author'] == null
          ? null
          : $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$author(
              (data['author'] as Map<String, dynamic>));
  String get id => (data['id'] as String);
  int get number => (data['number'] as int);
  _i1.MergeableState get mergeable =>
      _i1.MergeableState((data['mergeable'] as String));
  $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits
      get commits => data['commits'] == null
          ? null
          : $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits(
              (data['commits'] as Map<String, dynamic>));
  $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews
      get reviews => data['reviews'] == null
          ? null
          : $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews(
              (data['reviews'] as Map<String, dynamic>));
}

class $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$author {
  const $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$author(
      this.data);

  final Map<String, dynamic> data;

  String get login => (data['login'] as String);
}

class $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits {
  const $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits(
      this.data);

  final Map<String, dynamic> data;

  List<$LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes>
      get nodes => data['nodes'] == null
          ? null
          : (data['nodes'] as List)
              .map((dynamic e) =>
                  $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes(
                      (e as Map<String, dynamic>)))
              .toList();
}

class $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes {
  const $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes(
      this.data);

  final Map<String, dynamic> data;

  $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit
      get commit => data['commit'] == null
          ? null
          : $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit(
              (data['commit'] as Map<String, dynamic>));
}

class $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit {
  const $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit(
      this.data);

  final Map<String, dynamic> data;

  String get abbreviatedOid => (data['abbreviatedOid'] as String);
  _i1.GitObjectID get oid => _i1.GitObjectID((data['oid'] as String));
  _i1.DateTime get committedDate =>
      _i1.DateTime((data['committedDate'] as String));
  _i1.DateTime get pushedDate => _i1.DateTime((data['pushedDate'] as String));
  $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$status
      get status => data['status'] == null
          ? null
          : $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$status(
              (data['status'] as Map<String, dynamic>));
  $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$checkSuites
      get checkSuites => data['checkSuites'] == null
          ? null
          : $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$checkSuites(
              (data['checkSuites'] as Map<String, dynamic>));
}

class $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$status {
  const $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$status(
      this.data);

  final Map<String, dynamic> data;

  List<$LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$status$contexts>
      get contexts => data['contexts'] == null
          ? null
          : (data['contexts'] as List)
              .map((dynamic e) =>
                  $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$status$contexts(
                      (e as Map<String, dynamic>)))
              .toList();
}

class $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$status$contexts {
  const $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$status$contexts(
      this.data);

  final Map<String, dynamic> data;

  String get context => (data['context'] as String);
  _i1.StatusState get state => _i1.StatusState((data['state'] as String));
}

class $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$checkSuites {
  const $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$checkSuites(
      this.data);

  final Map<String, dynamic> data;

  List<$LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$checkSuites$nodes>
      get nodes => data['nodes'] == null
          ? null
          : (data['nodes'] as List)
              .map((dynamic e) =>
                  $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$checkSuites$nodes(
                      (e as Map<String, dynamic>)))
              .toList();
}

class $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$checkSuites$nodes {
  const $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$checkSuites$nodes(
      this.data);

  final Map<String, dynamic> data;

  $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$checkSuites$nodes$checkRuns
      get checkRuns => data['checkRuns'] == null
          ? null
          : $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$checkSuites$nodes$checkRuns(
              (data['checkRuns'] as Map<String, dynamic>));
}

class $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$checkSuites$nodes$checkRuns {
  const $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$checkSuites$nodes$checkRuns(
      this.data);

  final Map<String, dynamic> data;

  List<$LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$checkSuites$nodes$checkRuns$nodes>
      get nodes => data['nodes'] == null
          ? null
          : (data['nodes'] as List)
              .map((dynamic e) =>
                  $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$checkSuites$nodes$checkRuns$nodes(
                      (e as Map<String, dynamic>)))
              .toList();
}

class $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$checkSuites$nodes$checkRuns$nodes {
  const $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$checkSuites$nodes$checkRuns$nodes(
      this.data);

  final Map<String, dynamic> data;

  String get name => (data['name'] as String);
  _i1.CheckStatusState get status =>
      _i1.CheckStatusState((data['status'] as String));
  _i1.CheckConclusionState get conclusion =>
      _i1.CheckConclusionState((data['conclusion'] as String));
}

class $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews {
  const $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews(
      this.data);

  final Map<String, dynamic> data;

  List<$LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews$nodes>
      get nodes => data['nodes'] == null
          ? null
          : (data['nodes'] as List)
              .map((dynamic e) =>
                  $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews$nodes(
                      (e as Map<String, dynamic>)))
              .toList();
}

class $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews$nodes {
  const $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews$nodes(
      this.data);

  final Map<String, dynamic> data;

  $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews$nodes$author
      get author => data['author'] == null
          ? null
          : $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews$nodes$author(
              (data['author'] as Map<String, dynamic>));
  _i1.CommentAuthorAssociation get authorAssociation =>
      _i1.CommentAuthorAssociation((data['authorAssociation'] as String));
  _i1.PullRequestReviewState get state =>
      _i1.PullRequestReviewState((data['state'] as String));
}

class $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews$nodes$author {
  const $LabeledPullRequestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews$nodes$author(
      this.data);

  final Map<String, dynamic> data;

  String get login => (data['login'] as String);
}
