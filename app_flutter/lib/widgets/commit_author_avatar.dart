// Copyright (c) 2019 The Chromium Authors. All rights reserved.
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
    final int authorHash = commit.author.hashCode;
    final String authorName = commit.author.substring(0, 1).toUpperCase();
    final Widget avatar = CircleAvatar(
      backgroundColor: Color.fromRGBO(authorHash & 0xFF,
          (authorHash >> 8) & 0xFF, (authorHash >> 16) & 0xFF, 1),
      child: Text(authorName),
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
