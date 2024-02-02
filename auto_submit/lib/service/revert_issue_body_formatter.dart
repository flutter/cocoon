// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'dart:collection';

class RevertIssueBodyFormatter {
  RevertIssueBodyFormatter({
    required this.slug,
    required this.prToRevertNumber,
    required this.initiatingAuthor,
    required this.revertReason,
    required this.prToRevertAuthor,
    required this.prToRevertReviewers,
    required this.prToRevertTitle,
    required this.prToRevertBody,
  });

  // Possible format for the revert issue
  RepositorySlug slug;
  String initiatingAuthor;
  int prToRevertNumber;
  // These two fields can be null in the original pull request.
  String? prToRevertTitle;
  String? prToRevertBody;
  String? revertReason;
  String? prToRevertAuthor;
  Set<String> prToRevertReviewers;

  late String? revertPrTitle;
  late String? revertPrBody;
  late String? revertPrLink;

  RevertIssueBodyFormatter get format {
    // Create the title for the revert issue.
    prToRevertTitle ??= 'No title provided.';
    revertPrTitle = 'Reverts "$prToRevertTitle"';

    // create the reverts Link for the body. Looks like Reverts flutter/cocoon#123 but will render as a link.
    revertPrLink = 'Reverts ${slug.fullName}#$prToRevertNumber';

    prToRevertBody ??= 'No description provided.';

    // Create the body for the revert issue.
    revertPrBody = '''
$revertPrLink
Initiated by: $initiatingAuthor

Reason for reverting: $revertReason

Original PR Author: $prToRevertAuthor
Reviewed By: ${SetBase.setToString(prToRevertReviewers)}

This change reverts the following previous change:
Original Description:
$prToRevertBody
''';

    return this;
  }

  String? get formattedRevertPrTitle => revertPrTitle;

  String? get formattedRevertPrBody => revertPrBody;
}
