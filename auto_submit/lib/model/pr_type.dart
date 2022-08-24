// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

enum PullRequestType {
  merge(name: 'merge'),
  rebase(name: 'rebase'),
  revert(name: 'revert');

  const PullRequestType({
    required this.name
  });

  final String name;

  String get getName => name;
}