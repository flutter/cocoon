// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_common/rpc_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/build.dart';
import '../widgets/scaffold.dart';

/// Shows diagnostic information about tree health, and allows manual disabling.
final class TreeStatusPage extends StatefulWidget {
  const TreeStatusPage({super.key, this.queryParameters});

  static const String routeSegment = 'status';
  static const String routeName = '/$routeSegment';

  final Map<String, String>? queryParameters;

  @override
  State<TreeStatusPage> createState() => _TreeStatusPageState();
}

class _TreeStatusPageState extends State<TreeStatusPage> {
  late List<TreeStatusChange> changes;

  @override
  void initState() {
    changes = [];
    super.initState();
  }

  @override
  void didChangeDependencies() {
    unawaited(_fetchTreeStatusChanges());
    super.didChangeDependencies();
  }

  Future<void> _fetchTreeStatusChanges() async {
    final buildState = Provider.of<BuildState>(context, listen: false);
    final response = await buildState.cocoonService.fetchTreeStatusChanges(
      repo: buildState.currentRepo,
    );
    if (response.data case final data?) {
      setState(() {
        changes = data;
      });
    }
  }

  void _updateNavigation(
    BuildContext context, {
    required String repo,
    required String branch,
  }) {
    final queryParameters = {
      ...?widget.queryParameters,
      'repo': repo,
      'branch': branch,
    };
    final uri = Uri(
      path: TreeStatusPage.routeName,
      queryParameters: queryParameters,
    );
    unawaited(Navigator.pushNamed(context, uri.toString()));
  }

  @override
  Widget build(BuildContext context) {
    final markedFailing = changes.firstOrNull?.status == TreeStatus.failure;
    return CocoonScaffold(
      title: const Text('Tree Status'),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            actions: [
              ElevatedButton.icon(
                onPressed: () async {
                  // Launch a dialog that takes an optional reason.
                  final reason = await showDialog<String>(
                    context: context,
                    builder: (_) => const _ConfirmChangeDialog(),
                  );
                  if (reason == null) {
                    return;
                  }
                  final buildState = Provider.of<BuildState>(
                    context,
                    listen: false,
                  );
                  await buildState.cocoonService.updateTreeStatus(
                    repo: buildState.currentRepo,
                    status:
                        markedFailing ? TreeStatus.success : TreeStatus.failure,
                    reason: reason,
                  );
                  await _fetchTreeStatusChanges();
                },
                label:
                    markedFailing
                        ? const Text('Enable Tree')
                        : const Text('Disable Tree'),
                icon:
                    markedFailing
                        ? const Icon(Icons.check, color: Colors.green)
                        : const Icon(Icons.close, color: Colors.red),
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((_, i) {
              final item = changes[i];
              return ListTile(
                leading:
                    item.status == TreeStatus.success
                        ? const Icon(Icons.check, color: Colors.green)
                        : const Icon(Icons.error, color: Colors.red),
                title: Text(item.authoredBy),
                subtitle: Text(
                  item.reason != null ? 'Reason: ${item.reason}' : '',
                ),
                trailing: Text(item.createdOn.toString()),
              );
            }, childCount: changes.length),
          ),
        ],
      ),
      onUpdateNavigation: ({required branch, required repo}) {
        _updateNavigation(context, repo: repo, branch: branch);
      },
    );
  }
}

final class _ConfirmChangeDialog extends StatefulWidget {
  const _ConfirmChangeDialog();

  @override
  State<_ConfirmChangeDialog> createState() => _ConfirmChangeDialogState();
}

class _ConfirmChangeDialogState extends State<_ConfirmChangeDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reason'),
      content: TextField(
        controller: _reasonController,
        decoration: const InputDecoration(hintText: 'Enter reason (optional)'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_reasonController.text);
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
