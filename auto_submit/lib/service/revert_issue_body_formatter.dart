// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';

class RevertIssueBodyFormatter {
  RevertIssueBodyFormatter({
    required this.slug,
    required this.originalPrNumber,
    required this.initiatingAuthor,
    required this.originalPrTitle,
    required this.originalPrBody,
  });

  // Possible format for the revert issue
  RepositorySlug slug;
  String initiatingAuthor;
  int originalPrNumber;
  // These two fields can be null in the original pull request.
  String? originalPrTitle;
  String? originalPrBody;

  late String? revertPrTitle;
  late String? revertPrBody;
  late String? revertPrLink;

  RevertIssueBodyFormatter get format {
    // Create the title for the revert issue.
    originalPrTitle ??= 'No title provided.';
    revertPrTitle = 'Reverts "$originalPrTitle"';

    // create the reverts Link for the body. Looks like Reverts flutter/cocoon#123 but will render as a link.
    revertPrLink = 'Reverts ${slug.fullName}#$originalPrNumber';

    originalPrBody ??= 'No description provided.';

    // Create the body for the revert issue.
    revertPrBody = '''
$revertPrLink
Initiated by: $initiatingAuthor
This change reverts the following previous change:
Original Description:
$originalPrBody
''';

    return this;
  }

  String? get formattedRevertPrTitle => revertPrTitle;

  String? get formattedRevertPrBody => revertPrBody;
}
