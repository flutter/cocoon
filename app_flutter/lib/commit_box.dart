// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Displays Git commit information.
///
/// On click, it will open an [OverlayEntry] with [CommitOverlayContents]
/// to show the information provided. Otherwise, it just shows the avatar
/// for the author of this commit. Clicking outside of the [OverlayEntry]
/// will close it.
class CommitBox extends StatefulWidget {
  // TODO(chillers): convert to use commit model
  const CommitBox(
      {Key key,
      @required this.message,
      @required this.avatarUrl,
      @required this.author})
      : super(key: key);

  /// Commit message that summarizes the change made.
  final String message;

  /// Image URL to the avatar of the author of this commit.
  final String avatarUrl;

  /// The person that authored this commit.
  final String author;

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
          widget.avatarUrl,
          height: 40,
        ),
      ),
    );
  }

  void _handleTap() {
    _commitOverlay = OverlayEntry(
        builder: (overlayContext) => CommitOverlayContents(
            parentContext: context,
            widget: widget,
            closeCallback: _closeOverlay));

    Overlay.of(context).insert(_commitOverlay);
  }

  void _closeOverlay() => _commitOverlay.remove();
}

/// Displays the information from a Git commit.
///
/// This is intended to be inserted in an [OverlayEntry] as it requires
/// [closeCallback] that will remove the widget from the tree.
class CommitOverlayContents extends StatelessWidget {
  CommitOverlayContents({
    Key key,
    @required this.parentContext,
    @required this.widget,
    @required this.closeCallback,
  }) : super(key: key);

  /// The parent context that has the size of the whole screen
  final BuildContext parentContext;

  /// The parent widget that contains state variables
  final CommitBox widget;

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
                    backgroundImage: NetworkImage(widget.avatarUrl),
                    backgroundColor: Colors.transparent,
                  ),
                  title: Text(widget.message),
                  subtitle: Text(widget.author),
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
                      onPressed: () {
                        // TODO(chillers): open new tab with the commit on Github
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
