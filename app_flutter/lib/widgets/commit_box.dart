// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cocoon_service/protos.dart' show Commit;

import 'commit_author_avatar.dart';

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
    final ThemeData theme = Theme.of(context);
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
            child: SafeArea(
              minimum: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CommitAuthorAvatar(commit: commit),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedDefaultTextStyle(
                              style: theme.textTheme.subtitle1,
                              duration: kThemeChangeDuration,
                              child: Hyperlink(
                                text: commit.sha.substring(0, 7),
                                onPressed: _openGithub,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (commit.message != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: AnimatedDefaultTextStyle(
                                style: theme.textTheme.bodyText2.copyWith(
                                  color: theme.textTheme.caption.color,
                                ),
                                duration: kThemeChangeDuration,
                                child: SelectableText(commit.message),
                              ),
                            ),
                          SelectableText(commit.author),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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

class Hyperlink extends StatefulWidget {
  const Hyperlink({
    Key key,
    @required this.text,
    this.onPressed,
  })  : assert(text != null),
        super(key: key);

  final String text;
  final VoidCallback onPressed;

  @override
  _HyperlinkState createState() => _HyperlinkState();
}

class _HyperlinkState extends State<Hyperlink> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final TextStyle defaultStyle = DefaultTextStyle.of(context).style;
    return MouseRegion(
      onEnter: (PointerEnterEvent _) => setState(() => hover = true),
      onExit: (PointerExitEvent _) => setState(() => hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Text(
          widget.text,
          style: defaultStyle.copyWith(
            color: const Color(0xff1377c0),
            decoration: hover ? TextDecoration.underline : TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
