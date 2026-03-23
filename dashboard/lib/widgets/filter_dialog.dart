// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/task_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/presubmit.dart';
import 'task_box.dart';

/// A dialog that allows users to filter jobs in the Presubmit Dashboard.
class FilterDialog extends StatefulWidget {
  const FilterDialog({super.key});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late Set<TaskStatus> _selectedStatuses;
  late Set<String> _selectedPlatforms;
  late TextEditingController _regexController;
  final FocusNode _regexFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final presubmitState = Provider.of<PresubmitState>(context, listen: false);
    _selectedStatuses = Set.from(presubmitState.selectedStatuses);
    _selectedPlatforms = Set.from(presubmitState.selectedPlatforms);
    _regexController = TextEditingController(
      text: presubmitState.jobNameFilter,
    );
    _regexFocusNode.addListener(_onRegexFocusChange);
  }

  @override
  void dispose() {
    _regexFocusNode.removeListener(_onRegexFocusChange);
    _regexFocusNode.dispose();
    _regexController.dispose();
    super.dispose();
  }

  void _onRegexFocusChange() {
    if (!_regexFocusNode.hasFocus) {
      _applyFilters();
    }
  }

  void _applyFilters() {
    final presubmitState = Provider.of<PresubmitState>(context, listen: false);
    presubmitState.updateFilters(
      statuses: _selectedStatuses,
      platforms: _selectedPlatforms,
      jobNameFilter: _regexController.text,
    );
  }

  void _onRegexChanged(String value) {
    setState(() {});
    _applyFilters();
  }

  void _toggleStatus(TaskStatus status) {
    setState(() {
      if (_selectedStatuses.contains(status)) {
        if (_selectedStatuses.length > 1) {
          _selectedStatuses.remove(status);
        }
      } else {
        _selectedStatuses.add(status);
      }
    });
    _applyFilters();
  }

  void _togglePlatform(String platform) {
    setState(() {
      if (_selectedPlatforms.contains(platform)) {
        if (_selectedPlatforms.length > 1) {
          _selectedPlatforms.remove(platform);
        }
      } else {
        _selectedPlatforms.add(platform);
      }
    });
    _applyFilters();
  }

  void _clearAll() {
    setState(() {
      final presubmitState = Provider.of<PresubmitState>(
        context,
        listen: false,
      );
      _selectedStatuses = TaskStatus.values.toSet();
      _selectedPlatforms = Set.from(presubmitState.availablePlatforms);
      _regexController.clear();
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final presubmitState = Provider.of<PresubmitState>(context);
    final theme = Theme.of(context);
    final availablePlatforms = presubmitState.availablePlatforms.toList()
      ..sort();

    final filteredCount =
        presubmitState.filteredGuardResponse?.stages.fold<int>(
          0,
          (prev, stage) => prev + stage.builds.length,
        ) ??
        0;

    return AlertDialog(
      title: const Text('Filter jobs'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TaskStatus.values.map((status) {
                  final isSelected = _selectedStatuses.contains(status);
                  return FilterChip(
                    label: Text(status.value),
                    selected: isSelected,
                    onSelected: (_) => _toggleStatus(status),
                    avatar: _getStatusIcon(status),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Platform', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availablePlatforms.map((platform) {
                  return FilterChip(
                    label: Text(platform),
                    selected: _selectedPlatforms.contains(platform),
                    onSelected: (_) => _togglePlatform(platform),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Job Name (Regex)', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _regexController,
                focusNode: _regexFocusNode,
                decoration: const InputDecoration(
                  hintText: 'e.g. .*test.*',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onChanged: _onRegexChanged,
                onEditingComplete: _applyFilters,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _clearAll,
          child: const Text('Clear all filters'),
        ),
        ElevatedButton(
          onPressed: () {
            _applyFilters();
            Navigator.of(context).pop();
          },
          child: Text('Show $filteredCount jobs'),
        ),
      ],
    );
  }

  Widget _getStatusIcon(TaskStatus status) {
    return Icon(
      _getIconData(status),
      color: TaskBox.statusColor[status],
      size: 16,
    );
  }

  IconData _getIconData(TaskStatus status) {
    switch (status) {
      case .succeeded:
        return Icons.check_circle_outline;
      case .failed:
        return Icons.error_outline;
      case .infraFailure:
        return Icons.error_outline;
      case .waitingForBackfill:
        return Icons.not_started_outlined;
      case .skipped:
        return Icons.do_not_disturb_on_outlined;
      case .neutral:
        return Icons.flaky;
      case .cancelled:
        return Icons.block_outlined;
      case .inProgress:
        return Icons.sync;
    }
  }
}
