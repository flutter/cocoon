// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Displays Git commit information.
///
/// On click, shows an expanded overlay for additional funcionality, such as rerunning tasks for a commit.
class CommitBox extends StatefulWidget {
  // TODO(chillers): convert to use commit model
  const CommitBox(
      {Key key,
      @required this.message,
      @required this.avatarUrl,
      @required this.author,
      @required this.hash})
      : super(key: key);

  final String message;
  final String avatarUrl;
  final String author;
  final String hash;

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
        child: CompositedTransformTarget(
          link: this._layerLink,
          child: Row(
            children: <Widget>[
              Image.network(
                widget.avatarUrl,
                height: 40,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(widget.message),
              ),
            ],
          ),
        ));
  }

  OverlayEntry _createCommitOverlay(CommitBox widget) {
    RenderBox renderBox = context.findRenderObject();

    return OverlayEntry(
        builder: (context) => Positioned(
              width: 300,
              child: CompositedTransformFollower(
                link: this._layerLink,
                showWhenUnlinked: false,
                offset: Offset(25.0, renderBox.size.height),
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
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              // TODO(chillers): Refactor this so clicking outside of the overlay closes it
                              _commitOverlay.remove();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ));
  }
}
