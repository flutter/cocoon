// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logic/qualified_task.dart';
import '../state/build.dart';

/// Shows details about a test/task and allows modifying its suppression status.
class TestDetailsPopover extends StatefulWidget {
  const TestDetailsPopover({
    super.key,
    required this.qualifiedTask,
    required this.buildState,
    required this.showSnackBarCallback,
    required this.closeCallback,
  });

  final QualifiedTask qualifiedTask;
  final BuildState buildState;
  final void Function(SnackBar) showSnackBarCallback;
  final VoidCallback closeCallback;

  @override
  State<TestDetailsPopover> createState() => _TestDetailsPopoverState();
}

class _TestDetailsPopoverState extends State<TestDetailsPopover> {
  bool get isSuppressed {
    return widget.buildState.suppressedTests.any(
      (s) => s.name == widget.qualifiedTask.task,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.qualifiedTask.task,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: widget.buildState,
                builder: (context, child) {
                  final suppressed = isSuppressed;
                  final isAuthenticated =
                      widget.buildState.authService.isAuthenticated;

                  if (!isAuthenticated) {
                    return const Text(
                      'Sign in to change tree blocking status',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    );
                  }

                  if (suppressed) {
                    // Test is suppressed (NOT Blocking Tree).
                    // Button: "Include Test" -> Unsuppress
                    return ElevatedButton.icon(
                      onPressed: () => _toggleSuppression(false),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Include Test in Tree'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade100,
                        foregroundColor: Colors.green.shade900,
                      ),
                    );
                  } else {
                    // Test is NOT suppressed (Blocking Tree).
                    // Button: "Unblock Tree" -> Suppress
                    return ElevatedButton.icon(
                      onPressed: () => _showSuppressDialog(context),
                      icon: const Icon(Icons.do_not_disturb_on_outlined),
                      label: const Text('Unblock Tree'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade100,
                        foregroundColor: Colors.amber.shade900,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      await launchUrl(
                        widget.qualifiedTask.sourceConfigurationUrl,
                      );
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Source Config'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSuppressDialog(BuildContext context) async {
    final issueLinkController = TextEditingController(
      text: 'https://github.com/flutter/flutter/issues/',
    );
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unblock Tree'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Suppressing this test means it will no longer block the tree. '
                    'Please provide an issue link tracking this failure.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: issueLinkController,
                    decoration: const InputDecoration(
                      labelText: 'Issue Link (Required)',
                      hintText: 'https://github.com/flutter/flutter/issues/...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an issue link';
                      }
                      if (!Uri.tryParse(value)!.hasAbsolutePath) {
                        return 'Please enter a valid URL';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (Optional)',
                      hintText: 'Reason for suppression...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  _toggleSuppression(
                    true,
                    issueLink: issueLinkController.text,
                    note: noteController.text,
                  );
                }
              },
              child: const Text('Unblock Tree'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleSuppression(
    bool suppress, {
    String? issueLink,
    String? note,
  }) async {
    final success = await widget.buildState.updateTestSuppression(
      testName: widget.qualifiedTask.task,
      suppress: suppress,
      issueLink: issueLink,
      note: note,
    );
    if (!success) {
      widget.showSnackBarCallback(
        const SnackBar(content: Text('Failed to update test suppression')),
      );
    }
  }
}
