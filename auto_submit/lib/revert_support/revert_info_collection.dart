// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class RevertInfoCollection {
  RevertInfoCollection();

  // tags that appear in the revert issue body.
  final String startOriginalPrLinkTag = '<!-- start_original_pr_link -->';
  final String endOriginalPrLinkTag = '<!-- end_original_pr_link -->';

  final String startInitiatingAuthorTag = '<!-- start_initiating_author -->';
  final String endInitiatingAuthorTag = '<!-- end_initiating_author -->';

  final String startRevertReasonTag = '<!-- start_revert_reason -->';
  final String endRevertReasonTag = '<!-- end_revert_reason -->';

  final String startOriginalPrAuthorTag = '<!-- start_original_pr_author -->';
  final String endOriginalPrAuthorTag = '<!-- end_original_pr_author -->';

  final String startReviewersTag = '<!-- start_reviewers -->';
  final String endReviewersTag = '<!-- end_reviewers -->';

  final String startRevertBodyTag = '<!-- start_revert_body -->';
  final String endRevertBodyTag = '<!-- end_revert_body -->';

  String? extractOriginalPrLink(String text) {
    // This one is weird and is done to match the github standard.
    return _extract(
      startOriginalPrLinkTag,
      endOriginalPrLinkTag,
      text,
    );
  }

  String? extractInitiatingAuthor(String text) {
    return _splitHelper(startInitiatingAuthorTag, endInitiatingAuthorTag, text, ':');
  }

  String? extractRevertReason(String text) {
    return _splitHelper(startRevertReasonTag, endRevertReasonTag, text, ':');
  }

  String? extractOriginalPrAuthor(String text) {
    return _splitHelper(startOriginalPrAuthorTag, endOriginalPrAuthorTag, text, ':');
  }

  String? extractReviewers(String text) {
    return _splitHelper(
      startReviewersTag,
      endReviewersTag,
      text,
      ':',
    );
  }

  String? extractRevertBody(String text) {
    return _extract(
      startRevertBodyTag,
      endRevertBodyTag,
      text,
    );
  }

  String? _splitHelper(String startTag, String endTag, String text, String separator) {
    final String? match = _extract(
      startTag,
      endTag,
      text,
    );
    final List<String> split = match!.split(separator);
    return split.elementAt(1).trim();
  }

  String? _extract(String startTag, String endTag, String text) {
    String? match;
    String pattern = '$startTag([\\S\\s]*)$endTag';
    pattern = pattern.replaceAll('<', '\\<');
    pattern = pattern.replaceAll('>', '\\>');
    pattern = pattern.replaceAll('-', '\\-');
    pattern = pattern.replaceAll('!', '\\!');
    final RegExp regExp = RegExp(
      pattern,
      multiLine: true,
    );
    if (regExp.hasMatch(text)) {
      final matches = regExp.allMatches(text);
      final Match m = matches.first;
      match = m.group(1);
    }
    return match!.trim();
  }
}
