// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Displays Git commit information.
class CommitBox extends StatefulWidget {
  // TODO(chillers): convert to use commit model
  const CommitBox(
      {Key key,
      @required this.message,
      @required this.avatarUrl,
      @required this.author,
      @required this.sha})
      : super(key: key);

  /// Commit message that summarizes the change made.
  final String message;

  /// Image URL to the avatar of the author of this commit.
  final String avatarUrl;

  /// The person that authored this commit.
  final String author;

  /// The unique identifier for the commit in this repository
  final String sha;

  @override
  _CommitBoxState createState() => _CommitBoxState();
}

class _CommitBoxState extends State<CommitBox> {
  OverlayEntry _commitOverlay;
  final LayerLink _layerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        this._commitOverlay = this._createCommitOverlay(widget);
        Overlay.of(context).insert(this._commitOverlay);
      },
      child: Container(
        margin: const EdgeInsets.all(1.0),
        child: Image.network(
          widget.avatarUrl,
          height: 40,
        ),
      ),
    );
  }

  OverlayEntry _createCommitOverlay(CommitBox widget) {
    RenderBox renderBox = context.findRenderObject();

    return OverlayEntry(
        builder: (context) => Stack(
              children: <Widget>[
                // This is the area a user can click (the rest of the screen) to close the overlay.
                GestureDetector(
                  onTap: () {
                    print(renderBox.localToGlobal(Offset.zero).dx);
                    _commitOverlay.remove();
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    // Color must be defined otherwise the container can't be clicked on
                    color: Colors.transparent,
                  ),
                ),
                Positioned(
                  width: 300,
                  top: renderBox.localToGlobal(Offset.zero).dy + (renderBox.size.height / 2),
                  left: renderBox.localToGlobal(Offset.zero).dx + (renderBox.size.width / 2),
                  child: CompositedTransformFollower(
                    link: this._layerLink,
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
                ),
              ],
            ));
  }
}
