// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/rpc_model.dart';
import 'package:flutter/material.dart';

import 'optional_image.dart';

/// Shows the appropriate avatar for a [Commit]'s author.
///
/// Tries to use the author's image from GitHub, but failing that, uses a [CircleAvatar]
/// with the author's first name and a color arbitrarily but deterministically generated
/// from the avatar's name.
class CommitAuthorAvatar extends StatelessWidget {
  const CommitAuthorAvatar({super.key, this.commit});

  final Commit? commit;

  @override
  Widget build(BuildContext context) {
    assert(commit!.author.login.isNotEmpty);
    final authorName = commit!.author.login;
    final authorInitial = authorName.substring(0, 1).toUpperCase();
    final authorHash = authorName.hashCode;
    final theme = Theme.of(context);

    final hue = (360.0 * authorHash / (1 << 15)) % 360.0;
    final themeValue = HSVColor.fromColor(theme.colorScheme.surface).value;
    var authorColor = HSVColor.fromAHSV(1.0, hue, 0.4, themeValue).toColor();
    if (theme.brightness == Brightness.dark) {
      authorColor =
          HSLColor.fromColor(authorColor).withLightness(.65).toColor();
    }

    /// Fallback widget that shows the initial of the commit author. In cases
    /// where GitHub is down or slow internet this will be seen.
    final Widget avatar = CircleAvatar(
      backgroundColor: authorColor,
      child: Text(
        authorInitial,
        style: TextStyle(
          color:
              authorColor.computeLuminance() > 0.25
                  ? Colors.black
                  : Colors.white,
        ),
      ),
    );

    return OptionalImage(
      imageUrl: commit!.author.avatarUrl,
      placeholder: avatar,
    );
  }
}
