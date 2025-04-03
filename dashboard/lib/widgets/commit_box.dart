// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_common/rpc_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/link.dart';

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
    super.key,
    required this.commit,
    this.schedulePostsubmitBuild,
  });

  /// The commit being shown
  final Commit commit;

  /// Whether to provide a 'schedule build' button'.
  final Future<void> Function()? schedulePostsubmitBuild;

  @override
  CommitBoxState createState() => CommitBoxState();
}

class CommitBoxState extends State<CommitBox> {
  OverlayEntry? _commitOverlay;

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
      builder:
          (_) => CommitOverlayContents(
            parentContext: context,
            commit: widget.commit,
            closeCallback: _closeOverlay,
            schedulePostsubmitBuild: widget.schedulePostsubmitBuild,
          ),
    );

    Overlay.of(context).insert(_commitOverlay!);
  }

  void _closeOverlay() => _commitOverlay?.remove();
}

/// Displays the information from a Git commit.
///
/// This is intended to be inserted in an [OverlayEntry] as it requires
/// [closeCallback] that will remove the widget from the tree.
class CommitOverlayContents extends StatelessWidget {
  const CommitOverlayContents({
    super.key,
    required this.parentContext,
    required this.commit,
    required this.closeCallback,
    required this.schedulePostsubmitBuild,
  });

  /// The parent context that has the size of the whole screen
  final BuildContext parentContext;

  /// The commit data to display in the overlay
  final Commit commit;

  /// This callback removes the parent overlay from the widget tree.
  ///
  /// On a click that is outside the area of the overlay (the rest of the screen),
  /// this callback is called closing the overlay.
  final void Function() closeCallback;

  /// This callback schedules a post-submit build.
  final Future<void> Function()? schedulePostsubmitBuild;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final renderBox = parentContext.findRenderObject() as RenderBox;
    final offsetLeft = renderBox.localToGlobal(Offset.zero);
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
                              style: theme.textTheme.titleMedium!,
                              duration: kThemeChangeDuration,
                              child: Row(
                                children: <Widget>[
                                  Link(
                                    uri: Uri.https(
                                      'github.com',
                                      '${commit.repository}/commit/${commit.sha}',
                                    ),
                                    builder: (context, open) {
                                      return ElevatedButton(
                                        onPressed: open,
                                        child: Text(commit.sha.substring(0, 7)),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy),
                                    onPressed:
                                        () => unawaited(
                                          Clipboard.setData(
                                            ClipboardData(text: commit.sha),
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: AnimatedDefaultTextStyle(
                              style: theme.textTheme.bodyMedium!.copyWith(
                                color: theme.textTheme.bodySmall!.color,
                              ),
                              duration: kThemeChangeDuration,
                              child: SelectableText(
                                commit.message.split('\n').first,
                              ),
                            ),
                          ),
                          SelectableText(commit.author.login),
                          Tooltip(
                            key: const ValueKey('schedulePostsubmit'),
                            message:
                                schedulePostsubmitBuild == null
                                    ? 'Only enabled for release branches'
                                    : ''
                                        'For release branches, the post-submit artifacts are not '
                                        'immediately available and must be manually scheduled.',
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: ProgressButton(
                                child: const Text('Run all tasks'),
                                onPressed: schedulePostsubmitBuild,
                              ),
                            ),
                          ),
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
}
