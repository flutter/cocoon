// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cocoon_service/protos.dart' show Commit;

/// Displays Git commit information.
///
/// On click, it will open an [OverlayEntry] with [CommitOverlayContents]
/// to show the information provided. Otherwise, it just shows the avatar
/// for the author of this commit. Clicking outside of the [OverlayEntry]
/// will close it.
class CommitBox extends StatefulWidget {
  const CommitBox({Key key, @required this.commit})
      : assert(commit != null),
        super(key: key);

  /// The commit being shown
  final Commit commit;

  @override
  _CommitBoxState createState() => _CommitBoxState();
}

class _CommitBoxState extends State<CommitBox> {
  OverlayEntry _commitOverlay;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        margin: const EdgeInsets.all(1.0),
        child: Image.network(
          widget.commit.authorAvatarUrl,
          height: 40,
        ),
      ),
    );
  }

  void _handleTap() {
    _commitOverlay = OverlayEntry(
      builder: (_) => CommitOverlayContents(
          parentContext: context,
          commit: widget.commit,
          closeCallback: _closeOverlay),
    );

    Overlay.of(context).insert(_commitOverlay);
  }

  void _closeOverlay() => _commitOverlay.remove();
}

/// Displays the information from a Git commit.
///
/// This is intended to be inserted in an [OverlayEntry] as it requires
/// [closeCallback] that will remove the widget from the tree.
class CommitOverlayContents extends StatelessWidget {
  const CommitOverlayContents({
    Key key,
    @required this.parentContext,
    @required this.commit,
    @required this.closeCallback,
  })  : assert(parentContext != null),
        assert(commit != null),
        assert(closeCallback != null),
        super(key: key);

  /// The parent context that has the size of the whole screen
  final BuildContext parentContext;

  /// The commit data to display in the overlay
  final Commit commit;

  /// This callback removes the parent overlay from the widget tree.
  ///
  /// On a click that is outside the area of the overlay (the rest of the screen),
  /// this callback is called closing the overlay.
  final void Function() closeCallback;

  @override
  Widget build(BuildContext context) {
    final RenderBox renderBox = parentContext.findRenderObject();
    final Offset offsetLeft = renderBox.localToGlobal(Offset.zero);

    return Stack(
      children: <Widget>[
        // This is the area a user can click (the rest of the screen) to close the overlay.
        GestureDetector(
          onTap: closeCallback,
          child: Container(
            width: MediaQuery.of(parentContext).size.width,
            height: MediaQuery.of(parentContext).size.height,
            // Color must be defined otherwise the container can't be clicked on
            color: Colors.transparent,
          ),
        ),
        Positioned(
          width: 300,
          // Move this overlay to be where the parent is
          top: offsetLeft.dy + (renderBox.size.height / 2),
          left: offsetLeft.dx + (renderBox.size.width / 2),
          child: Card(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                ListTile(
                  leading: CircleAvatar(
                    radius: 25.0,
                    backgroundImage: NetworkImage(commit.authorAvatarUrl),
                    backgroundColor: Colors.transparent,
                  ),
                  // TODO(chillers): Show commit message here instead: https://github.com/flutter/cocoon/issues/435
                  title: Text(commit.sha),
                  subtitle: Text(commit.author),
                ),
                ButtonBar(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.repeat),
                      onPressed: () {
                        // TODO(chillers): rerun all tests for this commit
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () async {
                        final String githubUrl =
                            'https://github.com/${commit.repository}/commit/${commit.sha}';
                        await launch(githubUrl);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
