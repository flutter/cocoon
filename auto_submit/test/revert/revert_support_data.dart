// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

String sampleRevertBody = '''
<!-- start_original_pr_link -->
Reverts: flutter/cocoon#3460
<!-- end_original_pr_link -->
<!-- start_initiating_author -->
Initiated by: yusuf-goog
<!-- end_initiating_author -->
<!-- start_revert_reason -->
Reason for reverting: comment was added by mistake.
<!-- end_revert_reason -->
<!-- start_original_pr_author -->
Original PR Author: ricardoamador
<!-- end_original_pr_author -->

<!-- start_reviewers -->
Reviewed By: {keyonghan}
<!-- end_reviewers -->

<!-- start_revert_body -->
Original Description: A long winded description about this change is revolutionary.
<!-- end_revert_body -->

*Replace this paragraph with a description of what this PR is changing or adding, and why. Consider including before/after screenshots.*

*List which issues are fixed by this PR. You must list at least one issue.*

''';

String sampleRevertBodyWithTrailingLink = '''
<!-- start_original_pr_link -->
Reverts: flutter/cocoon#3460
<!-- end_original_pr_link -->
<!-- start_initiating_author -->
Initiated by: yusuf-goog
<!-- end_initiating_author -->
<!-- start_revert_reason -->
Reason for revert: Broke engine post-submit, see https://logs.chromium.org/logs/flutter/buildbucket/cr-buildbucket/8753367119442265873/+/u/test:_Android_Unit_Tests__API_28_/stdout.
<!-- end_revert_reason -->
<!-- start_original_pr_author -->
Original PR Author: ricardoamador
<!-- end_original_pr_author -->

<!-- start_reviewers -->
Reviewed By: {keyonghan}
<!-- end_reviewers -->

<!-- start_revert_body -->
Original Description: A long winded description about this change is revolutionary.
<!-- end_revert_body -->

*Replace this paragraph with a description of what this PR is changing or adding, and why. Consider including before/after screenshots.*

*List which issues are fixed by this PR. You must list at least one issue.*

''';
