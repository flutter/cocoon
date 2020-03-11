import 'package:cocoon_service/src/service/github/schema.public.schema.gql.dart'
    as _i1;

class $LabeledPullRequcodeestsWithReviews {
  const $LabeledPullRequcodeestsWithReviews(this.data);

  final Map<String, dynamic> data;

  $LabeledPullRequcodeestsWithReviews$repository get repository =>
      data['repository'] == null
          ? null
          : $LabeledPullRequcodeestsWithReviews$repository(
              (data['repository'] as Map<String, dynamic>));
}

class $LabeledPullRequcodeestsWithReviews$repository {
  const $LabeledPullRequcodeestsWithReviews$repository(this.data);

  final Map<String, dynamic> data;

  $LabeledPullRequcodeestsWithReviews$repository$labels get labels =>
      data['labels'] == null
          ? null
          : $LabeledPullRequcodeestsWithReviews$repository$labels(
              (data['labels'] as Map<String, dynamic>));
}

class $LabeledPullRequcodeestsWithReviews$repository$labels {
  const $LabeledPullRequcodeestsWithReviews$repository$labels(this.data);

  final Map<String, dynamic> data;

  List<$LabeledPullRequcodeestsWithReviews$repository$labels$nodes> get nodes =>
      data['nodes'] == null
          ? null
          : (data['nodes'] as List)
              .map((dynamic e) =>
                  $LabeledPullRequcodeestsWithReviews$repository$labels$nodes(
                      (e as Map<String, dynamic>)))
              .toList();
}

class $LabeledPullRequcodeestsWithReviews$repository$labels$nodes {
  const $LabeledPullRequcodeestsWithReviews$repository$labels$nodes(this.data);

  final Map<String, dynamic> data;

  String get id => (data['id'] as String);
  $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests
      get pullRequests => data['pullRequests'] == null
          ? null
          : $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests(
              (data['pullRequests'] as Map<String, dynamic>));
}

class $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests {
  const $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests(
      this.data);

  final Map<String, dynamic> data;

  List<$LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes>
      get nodes => data['nodes'] == null
          ? null
          : (data['nodes'] as List)
              .map((dynamic e) =>
                  $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes(
                      (e as Map<String, dynamic>)))
              .toList();
}

class $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes {
  const $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes(
      this.data);

  final Map<String, dynamic> data;

  $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$author
      get author => data['author'] == null
          ? null
          : $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$author(
              (data['author'] as Map<String, dynamic>));
  String get id => (data['id'] as String);
  int get number => (data['number'] as int);
  _i1.MergeableState get mergeable =>
      _i1.MergeableState((data['mergeable'] as String));
  $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits
      get commits => data['commits'] == null
          ? null
          : $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits(
              (data['commits'] as Map<String, dynamic>));
  $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews
      get reviews => data['reviews'] == null
          ? null
          : $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews(
              (data['reviews'] as Map<String, dynamic>));
}

class $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$author {
  const $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$author(
      this.data);

  final Map<String, dynamic> data;

  String get login => (data['login'] as String);
}

class $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits {
  const $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits(
      this.data);

  final Map<String, dynamic> data;

  List<$LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes>
      get nodes => data['nodes'] == null
          ? null
          : (data['nodes'] as List)
              .map((dynamic e) =>
                  $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes(
                      (e as Map<String, dynamic>)))
              .toList();
}

class $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes {
  const $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes(
      this.data);

  final Map<String, dynamic> data;

  $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit
      get commit => data['commit'] == null
          ? null
          : $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit(
              (data['commit'] as Map<String, dynamic>));
}

class $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit {
  const $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit(
      this.data);

  final Map<String, dynamic> data;

  String get abbreviatedOid => (data['abbreviatedOid'] as String);
  _i1.GitObjectID get oid => _i1.GitObjectID((data['oid'] as String));
  _i1.DateTime get committedDate =>
      _i1.DateTime((data['committedDate'] as String));
  _i1.DateTime get pushedDate => _i1.DateTime((data['pushedDate'] as String));
  $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$status
      get status => data['status'] == null
          ? null
          : $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$status(
              (data['status'] as Map<String, dynamic>));
}

class $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$status {
  const $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$status(
      this.data);

  final Map<String, dynamic> data;

  List<$LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$status$contexts>
      get contexts => data['contexts'] == null
          ? null
          : (data['contexts'] as List)
              .map((dynamic e) =>
                  $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$status$contexts(
                      (e as Map<String, dynamic>)))
              .toList();
}

class $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$status$contexts {
  const $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$commits$nodes$commit$status$contexts(
      this.data);

  final Map<String, dynamic> data;

  String get context => (data['context'] as String);
  _i1.StatusState get state => _i1.StatusState((data['state'] as String));
}

class $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews {
  const $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews(
      this.data);

  final Map<String, dynamic> data;

  List<$LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews$nodes>
      get nodes => data['nodes'] == null
          ? null
          : (data['nodes'] as List)
              .map((dynamic e) =>
                  $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews$nodes(
                      (e as Map<String, dynamic>)))
              .toList();
}

class $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews$nodes {
  const $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews$nodes(
      this.data);

  final Map<String, dynamic> data;

  $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews$nodes$author
      get author => data['author'] == null
          ? null
          : $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews$nodes$author(
              (data['author'] as Map<String, dynamic>));
  _i1.CommentAuthorAssociation get authorAssociation =>
      _i1.CommentAuthorAssociation((data['authorAssociation'] as String));
  _i1.PullRequestReviewState get state =>
      _i1.PullRequestReviewState((data['state'] as String));
}

class $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews$nodes$author {
  const $LabeledPullRequcodeestsWithReviews$repository$labels$nodes$pullRequests$nodes$reviews$nodes$author(
      this.data);

  final Map<String, dynamic> data;

  String get login => (data['login'] as String);
}
