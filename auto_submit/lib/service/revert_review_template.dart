// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class RevertReviewTemplate {
  RevertReviewTemplate({
      required this.repositorySlug,
      required this.revertPrNumber, 
      required this.revertPrAuthor,
      required this.originalPrLink,}) {
    constructTitle();
    constructBody();
  }

  String repositorySlug;
  int revertPrNumber;
  String revertPrAuthor;
  String originalPrLink;

  String? _title;
  String? _body; 

  void constructTitle() {
    _title = '''
Review request for Revert PR $repositorySlug#$revertPrNumber
''';
  }

  void constructBody() {
_body = '''
Pull request $repositorySlug#$revertPrNumber was submitted and merged by 
$revertPrAuthor in order to revert changes made in this pull request $originalPrLink. 

Please assign this issue to the person that will make the formal review on the
revert request listed above.

Please do the following so that we may track this issue to completion:
1. Add the reviewer of revert pull request as the assignee of this issue.
2. Add the label 'revert_review' to this issue.
3. Close only when the review has been completed.


PLEASE DO NOT MODIFY THE FOLLOWING
{
  'originalPrLink': '$originalPrLink',
  'revertPrLink': '$repositorySlug#$revertPrNumber',
  'revertPrAuthor': '$revertPrAuthor'
}
''';
  }

  String? get title => _title;
  String? get body => _body;
}