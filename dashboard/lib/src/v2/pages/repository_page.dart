// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../models/git_branch.dart';
import '../models/github_repository.dart';
import '../widgets/dropdown_select.dart';

final class V2RepositoryPage extends StatelessWidget {
  const V2RepositoryPage({required this.repository, required this.branch});

  /// Repository being viewed.
  final GithubRepository repository;

  /// Branch being viewed for the repository.
  final GitBranch branch;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cocoon V2 Preview'), actions: []),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownSelect(
              // TODO(matanlurey): Use real branches from the backend.
              options: [GitBranch.from('master')],
              labelBuilder: (branch) => branch.name,
              itemBuilder: (branch) {
                // TODO(matanlurey): Use branch.alias as well, if provided.
                return Text(branch.name);
              },
              selected: GitBranch.from('master'),
              onSelect: (selectedBranch) async {
                await Navigator.pushReplacementNamed(
                  context,
                  '/v2/${repository.fullName}/${selectedBranch.name}',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
