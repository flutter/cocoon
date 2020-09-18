// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:cocoon_service/protos.dart' show Commit;

/// Shows the appropriate avatar for a [Commit]'s author.
///
/// Tries to use the author's image from GitHub, but failing that, uses a [CircleAvatar]
/// with the author's first name and a color arbitrarily but deterministically generated
/// from the avatar's name.
class CommitAuthorAvatar extends StatelessWidget {
  CommitAuthorAvatar({
    Key key,
    this.commit,
    this.width = 50,
    this.height = 50,
    http.Client client,
  })  : httpClient = client ?? http.Client(),
        super(key: key);

  final Commit commit;

  /// Width passed to [Image].
  final double width;

  /// Height passed to [Image]/
  final double height;

  /// Client to make network requests to.
  final http.Client httpClient;

  Future<Uint8List> _getAvatarBytes() async {
    final http.Response response = await httpClient.get(commit.authorAvatarUrl);
    return response.bodyBytes;
  }

  @override
  Widget build(BuildContext context) {
    assert(commit.author.isNotEmpty);
    final String authorName = commit.author;
    final String authorInitial = authorName.substring(0, 1).toUpperCase();
    final int authorHash = authorName.hashCode;
    final ThemeData theme = Theme.of(context);

    final double hue = (360.0 * authorHash / (1 << 15)) % 360.0;
    final double themeValue = HSVColor.fromColor(theme.backgroundColor).value;
    Color authorColor = HSVColor.fromAHSV(1.0, hue, 0.4, themeValue).toColor();
    if (theme.brightness == Brightness.dark) {
      authorColor = HSLColor.fromColor(authorColor).withLightness(.65).toColor();
    }

    /// Fallback widget that shows the initial of the commit author. In cases
    /// where GitHub is down or slow internet this will be seen.
    final Widget avatar = CircleAvatar(
      backgroundColor: authorColor,
      child: Text(
        authorInitial,
        style: TextStyle(color: authorColor.computeLuminance() > 0.25 ? Colors.black : Colors.white),
      ),
    );

    /// GitHub endpoint may throw an exception instead, which will have less bytes
    /// than required to construct an image from. A quick hack to ensure enough data
    /// exists for [Image.memory] can decode an image.
    const int minimumImageBytes = 10;

    return FutureBuilder<Uint8List>(
      future: _getAvatarBytes(),
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        if (snapshot.hasData && snapshot.data.length > minimumImageBytes) {
          return Image.memory(
            snapshot.data,
            width: width,
            height: height,
          );
        }
        return avatar;
      },
    );
  }
}
