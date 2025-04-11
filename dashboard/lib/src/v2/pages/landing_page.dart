// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../models/github_repository.dart';
import '../widgets/tappable_select.dart';

final class V2LandingPage extends StatelessWidget {
  const V2LandingPage([this.repoOwner]);
  final String? repoOwner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cocoon V2 Preview'), actions: []),
      body: TappableSelect.withFiltering(
        onFilter: (r, f) => r.fullName.contains(f),
        options: [
          GithubRepository.from('flutter', 'cocoon'),
          GithubRepository.from('flutter', 'flutter'),
          GithubRepository.from('flutter', 'packages'),
        ],
        itemBuilder: (repo) => Text(repo.fullName),
        onSelect: (repo) async {
          await Navigator.pushNamed(context, '/v2/${repo.fullName}');
        },
        initialFilter: repoOwner == null ? null : '$repoOwner/',
      ),
    );
  }
}
