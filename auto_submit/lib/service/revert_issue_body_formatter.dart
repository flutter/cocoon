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
  final RepositorySlug slug;
  final String initiatingAuthor;
  final int originalPrNumber;
  final String originalPrTitle;
  final String originalPrBody;

  late String? revertPrTitle;
  late String? revertPrBody;
  late String? revertPrLink;

  RevertIssueBodyFormatter get format {
    // Create the title for the revert issue.
    revertPrTitle = 'Reverts "$originalPrTitle"';

    // create the reverts Link for the body. Looks like Reverts flutter/cocoon#123 but will render as a link.
    revertPrLink = 'Reverts ${slug.fullName}#$originalPrNumber';

    // Create the body for the revert issue.
    revertPrBody = '''
$revertPrLink
Initiated by: $initiatingAuthor
This change reverts the following previous change:
$originalPrBody
''';

    return this;
  }

  String? get formattedRevertPrTitle => revertPrTitle;

  String? get formattedRevertPrBody => revertPrBody;
}
