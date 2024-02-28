import 'package:auto_submit/revert_support/revert_info_collection.dart';
import 'package:test/test.dart';

void main() {

  RevertInfoCollection? revertInfoCollection;

  setUp(() {
    revertInfoCollection = RevertInfoCollection();
  });

  test('extract reverts link', () {
    const String expected = 'Reverts flutter/cocoon#3460';
    expect(revertInfoCollection!.extractOriginalPrLink(sampleRevertBody), expected);
  });

  test('extract initiating author', () {
    const String expected = 'yusuf-goog';
    expect(revertInfoCollection!.extractInitiatingAuthor(sampleRevertBody), expected);
  });

  test('extract revert reason', () {
    const String expected = 'comment was added by mistake.';
    expect(revertInfoCollection!.extractRevertReason(sampleRevertBody), expected);
  });

  test('extract original pr author', () {
    const String expected = 'ricardoamador';
    expect(revertInfoCollection!.extractOriginalPrAuthor(sampleRevertBody), expected);
  });

  test('extract original pr reviewers', () {
    const String expected = '{keyonghan}';
    expect(revertInfoCollection!.extractReviewers(sampleRevertBody), expected);
  });

  test('extract the original revert info', () {
    const String expected1 = 'This change reverts the following previous change';
    const String expected2 = 'Original Description: A long winded description about this change is revolutionary.';
    final String? description = revertInfoCollection!.extractRevertBody(sampleRevertBody);
    expect(description!.contains(expected1), isTrue);
    expect(description.contains(expected2), isTrue);
  });
}


String sampleRevertBody = '''
<!-- start_original_pr_link -->
Reverts flutter/cocoon#3460
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
This change reverts the following previous change:
Original Description: A long winded description about this change is revolutionary.
<!-- end_revert_body -->

*Replace this paragraph with a description of what this PR is changing or adding, and why. Consider including before/after screenshots.*

*List which issues are fixed by this PR. You must list at least one issue.*

''';