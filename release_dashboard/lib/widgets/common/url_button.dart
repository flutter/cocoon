// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

/// Constructs a [TextButton] that displays [textToDisplay].
///
/// Clicking on [TextButton] will open [urlOrUri].
/// Supports opening a URL in the web browser or URI in the local file system.
/// The widget automatically detects if [urlOrUri] is a URL or URI.
class UrlButton extends StatelessWidget {
  const UrlButton({
    Key? key,
    required this.textToDisplay,
    required this.urlOrUri,
  }) : super(key: key);

// TODO(Yugue): [release_dashboard] UrlButton textToDisplay should be a widget
// https://github.com/flutter/flutter/issues/93931
  final String textToDisplay;
  final String urlOrUri;

  @override
  Widget build(BuildContext context) {
    return Link(
      /// URL supports case insensitive links such as 'HTTP://...'.
      ///
      /// Converts [urlOrUri] to lowercase first then check if it matches with 'http' to support all cases.
      uri: urlOrUri.toLowerCase().startsWith('http') ? Uri.parse(urlOrUri) : Uri.file(urlOrUri),
      target: LinkTarget.blank,
      builder: (ctx, openLink) {
        return TextButton(
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: openLink,
          child: Text(textToDisplay),
        );
      },
    );
  }
}
