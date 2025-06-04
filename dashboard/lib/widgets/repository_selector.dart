// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/rpc_model.dart';
import 'package:flutter/material.dart';
import 'package:truncate/truncate.dart';

/// Displays and allows selecting a GitHub repository.
final class RepositorySelector extends StatelessWidget {
  const RepositorySelector({
    required this.repositories,
    required this.branches,
    required this.selectedRepository,
    required this.selectedBranch,
    required this.onRepositoryChange,
    required this.onBranchChange,
    required bool smallScreen,
  }) : isSmallScreen = smallScreen;

  /// Example branch for [truncate].
  ///
  /// Include the ellipsis to get the correct length that should be truncated at.
  static const _exampleBranch = 'flutter-3.12-candidate.23...';

  /// Repositories to select from.
  final List<String> repositories;

  /// Branches to select from for the [selectedRepository].
  final List<Branch> branches;

  /// The current repository being shown.
  final String selectedRepository;

  /// The current branch of the [selectedRepository].
  final String selectedBranch;

  /// Whether to display optimized for a smaller screen.
  final bool isSmallScreen;

  /// Invoked with the repository when a new selection is made.
  final void Function(String) onRepositoryChange;

  /// Invoked with the branch when a new selection is made.
  final void Function(String) onBranchChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 22, left: 5, right: 5),
          child: Text('repo: ', textAlign: TextAlign.center),
        ),
        DropdownButton<String>(
          key: const Key('repo dropdown'),
          isExpanded: isSmallScreen,
          value: selectedRepository,
          icon: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Icon(Icons.arrow_downward),
          ),
          iconSize: 24,
          elevation: 16,
          underline: Container(height: 2),
          onChanged: (selectedRepo) {
            if (selectedRepo != null) {
              onRepositoryChange(selectedRepo);
            }
          },
          items: [
            ...repositories.map((value) {
              return DropdownMenuItem(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.only(top: 11),
                  child: Center(
                    child: Text(
                      value,
                      style: theme.primaryTextTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(top: 22, left: 5, right: 5),
          child: Text('branch: ', textAlign: TextAlign.center),
        ),
        DropdownButton(
          key: const Key('branch dropdown'),
          isExpanded: isSmallScreen,
          value: selectedBranch,
          icon: const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Icon(Icons.arrow_downward),
          ),
          iconSize: 24,
          elevation: 16,
          underline: Container(height: 2),
          onChanged: (selectedBranch) {
            if (selectedBranch != null) {
              onBranchChange(selectedBranch);
            }
          },
          items: [
            DropdownMenuItem(
              value: selectedBranch,
              child: Padding(
                padding: const EdgeInsets.only(top: 9.0),
                child: Center(
                  child: Text(
                    truncate(selectedBranch, _exampleBranch.length),
                    style: theme.primaryTextTheme.bodyLarge,
                  ),
                ),
              ),
            ),
            ...branches.where((b) => b.reference != selectedBranch).map((b) {
              return DropdownMenuItem(
                value: b.reference,
                child: Padding(
                  padding: const EdgeInsets.only(top: 9.0),
                  child: Center(
                    child: Text(
                      '${(b.channel != 'master') ? '${b.channel}: ' : ''}${truncate(b.reference, _exampleBranch.length)}',
                      style: theme.primaryTextTheme.bodyLarge,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
      ],
    );
  }
}
