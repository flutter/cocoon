// Copyright (c) 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cocoon_service/protos.dart' show Commit;

import 'commit_author_avatar.dart';
import 'progress_button.dart';

// TODO(ianh): Factor out the logic in task_overlay.dart and use it here as well,
// so that all our popups have the same look and feel and we don't duplicate code.

/// Displays Git commit information.
///
/// On click, it will open an [OverlayEntry] with [CommitOverlayContents]
/// to show the information provided. Otherwise, it just shows the avatar
/// for the author of this commit. Clicking outside of the [OverlayEntry]
/// will close it.
class CommitBox extends StatefulWidget {
  const CommitBox({
    Key key,
    @required this.commit,
  })  : assert(commit != null),
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
    return InkWell(
      onTap: _handleTap,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: CommitAuthorAvatar(commit: widget.commit),
      ),
    );
  }

  void _handleTap() {
    _commitOverlay = OverlayEntry(
      builder: (_) => CommitOverlayContents(
        parentContext: context,
        commit: widget.commit,
        closeCallback: _closeOverlay,
      ),
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
    final RenderBox renderBox = parentContext.findRenderObject() as RenderBox;
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
                  leading: CommitAuthorAvatar(commit: commit),
                  // TODO(chillers): Show commit message here instead: https://github.com/flutter/cocoon/issues/435
                  // Shorten the SHA as we only need first 7 digits to be able
                  // to lookup the commit.
                  title: SelectableText(commit.sha.substring(0, 7)),
                  subtitle: SelectableText(commit.author),
                ),
                ButtonBar(
                  children: <Widget>[
                    ProgressButton(
                      child: const Text('OPEN GITHUB'),
                      onPressed: _openGithub,
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

  Future<void> _openGithub() async {
    final String githubUrl = 'https://github.com/${commit.repository}/commit/${commit.sha}';
    await launch(githubUrl);
  }
}
