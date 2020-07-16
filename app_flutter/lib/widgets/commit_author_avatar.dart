// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:cocoon_service/protos.dart' show Commit;

import 'web_image.dart';

/// Shows the appropriate avatar for a [Commit]'s author.
///
/// Tries to use the author's image from GitHub, but failing that, uses a [CircleAvatar]
/// with the author's first name and a color arbitrarily but deterministically generated
/// from the avatar's name.
class CommitAuthorAvatar extends StatelessWidget {
  const CommitAuthorAvatar({
    Key key,
    this.commit,
  }) : super(key: key);

  final Commit commit;

  @override
  Widget build(BuildContext context) {
    assert(commit.author.isNotEmpty);
    final String authorName = commit.author.substring(0, 1).toUpperCase();
    final int authorHash = authorName.hashCode;
    final ThemeData theme = Theme.of(context);

    final double hue = (360.0 * authorHash / (1 << 15)) % 360.0;
    final double themeValue = HSVColor.fromColor(theme.backgroundColor).value;
    Color authorColor = HSVColor.fromAHSV(1.0, hue, 0.4, themeValue).toColor();
    if (theme.brightness == Brightness.dark)
      authorColor =
          HSLColor.fromColor(authorColor).withLightness(.65).toColor();

    final Widget avatar = CircleAvatar(
      backgroundColor: authorColor,
      child: Text(
        authorName,
        style: TextStyle(
            color: authorColor.computeLuminance() > 0.25
                ? Colors.black
                : Colors.white),
      ),
    );

    return WebImage(
      imageUrl: commit.authorAvatarUrl,
      imageBuilder: (BuildContext context, ImageProvider provider) =>
          CircleAvatar(
        backgroundImage: provider,
      ),
      placeholder: (BuildContext context, String url) => avatar,
      errorWidget: (BuildContext context, String url, Object error) => avatar,
    );
  }
}
