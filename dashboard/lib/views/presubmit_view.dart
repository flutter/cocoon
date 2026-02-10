// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_common/guard_status.dart';
import 'package:cocoon_common/rpc_model.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/build.dart';
import '../widgets/scaffold.dart';

/// A detailed monitoring view for a specific Pull Request (PR) or commit SHA.
///
/// This view displays CI check statuses and execution logs.
final class PreSubmitView extends StatefulWidget {
  const PreSubmitView({super.key, this.queryParameters});

  static const String routeSegment = 'presubmit';
  static const String routeName = '/$routeSegment';

  final Map<String, String>? queryParameters;

  @override
  State<PreSubmitView> createState() => _PreSubmitViewState();
}

class _PreSubmitViewState extends State<PreSubmitView> {
  late String repo;
  String? sha;
  String? pr;
  PresubmitGuardResponse? _guardResponse;
  bool _isLoading = false;
  String? _selectedCheck;

  @override
  void initState() {
    super.initState();
    final params = widget.queryParameters ?? {};
    repo = params['repo'] ?? 'flutter';
    sha = params['sha'];
    pr = params['pr'];

    if (pr != null && sha == null) {
      // Mocked data for PR route
      _guardResponse = PresubmitGuardResponse(
        prNum: int.parse(pr!),
        checkRunId: 456,
        author: 'dash',
        guardStatus: GuardStatus.inProgress,
        stages: [
          const PresubmitGuardStage(
            name: 'Engine',
            createdAt: 0,
            builds: {
              'Mac mac_host_engine': TaskStatus.failed,
              'Mac mac_ios_engine': TaskStatus.failed,
              'Linux linux_android_aot_engine': TaskStatus.succeeded,
            },
          ),
          const PresubmitGuardStage(
            name: 'Framework',
            createdAt: 0,
            builds: {
              'Linux framework_tests': TaskStatus.inProgress,
            },
          ),
        ],
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (sha != null && _guardResponse == null && !_isLoading) {
      unawaited(_fetchGuardStatus());
    }
  }

  Future<void> _fetchGuardStatus() async {
    setState(() {
      _isLoading = true;
    });
    final buildState = Provider.of<BuildState>(context, listen: false);
    final response = await buildState.cocoonService.fetchPresubmitGuard(
      repo: repo,
      sha: sha!,
    );
    if (mounted) {
      setState(() {
        _guardResponse = response.data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String title = _guardResponse != null
        ? 'PR #${_guardResponse!.prNum}: [${_guardResponse!.author}]'
        : (pr != null ? 'PR #$pr: Feature Implementation' : 'PreSubmit: $repo @ $sha');

    final String statusText = _guardResponse?.guardStatus.value ?? (pr != null ? 'Pending' : 'Loading...');
    final Color statusColor = _getStatusColor(statusText, isDark);

    return CocoonScaffold(
      title: Row(
        children: [
          Flexible(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.2)),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                if (_guardResponse != null)
                  _ChecksSidebar(
                    guardResponse: _guardResponse!,
                    selectedCheck: _selectedCheck,
                    onCheckSelected: (name) {
                      setState(() {
                        _selectedCheck = name;
                      });
                    },
                  ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: _selectedCheck == null
                      ? const Center(child: Text('Select a check to view logs'))
                      : _LogViewerPane(
                          repo: repo,
                          checkRunId: _guardResponse!.checkRunId,
                          buildName: _selectedCheck!,
                          isMocked: pr != null && sha == null,
                        ),
                ),
              ],
            ),
      onUpdateNavigation: ({required branch, required repo}) {
        // Handle navigation updates if needed.
      },
    );
  }

  Color _getStatusColor(String status, bool isDark) {
    switch (status) {
      case 'Succeeded':
        return const Color(0xFF2DA44E);
      case 'Failed':
        return const Color(0xFFF85149);
      case 'In Progress':
      case 'Pending':
        return const Color(0xFFD29922);
      default:
        return isDark ? Colors.grey[400]! : Colors.grey[600]!;
    }
  }
}

class _LogViewerPane extends StatefulWidget {
  const _LogViewerPane({
    required this.repo,
    required this.checkRunId,
    required this.buildName,
    this.isMocked = false,
  });

  final String repo;
  final int checkRunId;
  final String buildName;
  final bool isMocked;

  @override
  State<_LogViewerPane> createState() => _LogViewerPaneState();
}

class _LogViewerPaneState extends State<_LogViewerPane> {
  List<PresubmitCheckResponse>? _checks;
  bool _isLoading = false;
  int _selectedAttemptIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchCheckDetails();
  }

  @override
  void didUpdateWidget(_LogViewerPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buildName != widget.buildName || oldWidget.checkRunId != widget.checkRunId) {
      _selectedAttemptIndex = 0;
      _fetchCheckDetails();
    }
  }

  Future<void> _fetchCheckDetails() async {
    if (widget.isMocked) {
      setState(() {
        _checks = [
          PresubmitCheckResponse(
            attemptNumber: 1,
            buildName: widget.buildName,
            creationTime: 0,
            status: 'Succeeded',
            summary: '[INFO] Starting task ${widget.buildName}...\n[SUCCESS] Dependencies installed.\n[INFO] Running build script...\n[SUCCESS] All tests passed (452/452)',
          ),
          PresubmitCheckResponse(
            attemptNumber: 2,
            buildName: widget.buildName,
            creationTime: 0,
            status: 'Failed',
            summary: '[INFO] Starting task ${widget.buildName}...\n[ERROR] Test failed: Unit Tests',
          ),
        ];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final buildState = Provider.of<BuildState>(context, listen: false);
    final response = await buildState.cocoonService.fetchPresubmitCheckDetails(
      checkRunId: widget.checkRunId,
      buildName: widget.buildName,
    );
    if (mounted) {
      setState(() {
        _checks = response.data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFD1D5DB);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_checks == null || _checks!.isEmpty) {
      return const Center(child: Text('No details found for this check'));
    }

    final selectedCheck = _checks![_selectedAttemptIndex < _checks!.length ? _selectedAttemptIndex : 0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.repo} / ${widget.buildName}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Status: ${selectedCheck.status}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF8B949E) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF3F4F6),
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              ..._checks!.asMap().entries.map((entry) {
                final index = entry.key;
                final check = entry.value;
                final isSelected = _selectedAttemptIndex == index;
                return InkWell(
                  onTap: () => setState(() => _selectedAttemptIndex = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      '#${check.attemptNumber}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? const Color(0xFF8B949E) : const Color(0xFF6B7280)),
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              const Text(
                'BUILD HISTORY',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              const Text('Execution Log', style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              const Text('Raw output', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF9FAFB),
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(6),
            ),
            width: double.infinity,
            child: SingleChildScrollView(
              child: Text(
                selectedCheck.summary ?? 'No log summary available',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: InkWell(
            onTap: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.open_in_new,
                  size: 18,
                  color: isDark ? const Color(0xFF58A6FF) : const Color(0xFF0969DA),
                ),
                const SizedBox(width: 8),
                Text(
                  'View more details on LUCI UI',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF58A6FF) : const Color(0xFF0969DA),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChecksSidebar extends StatelessWidget {
  const _ChecksSidebar({
    required this.guardResponse,
    this.selectedCheck,
    required this.onCheckSelected,
  });

  final PresubmitGuardResponse guardResponse;
  final String? selectedCheck;
  final ValueChanged<String> onCheckSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFD1D5DB);

    return Container(
      width: 350,
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(6),
                      color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF9FAFB),
                    ),
                    child: const Row(
                      children: [
                        Flexible(
                          child: Text(
                            'a1b2c3d4e (Latest)',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.expand_more, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Re-run failed', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF3F4F6),
                    foregroundColor: isDark ? Colors.white : Colors.black,
                    elevation: 0,
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: guardResponse.stages.length,
              itemBuilder: (context, stageIndex) {
                final stage = guardResponse.stages[stageIndex];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF9FAFB),
                      child: Text(
                        stage.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF8B949E) : const Color(0xFF6B7280),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ...stage.builds.entries.map((entry) {
                      final isSelected = selectedCheck == entry.key;
                      return _CheckItem(
                        name: entry.key,
                        status: entry.value,
                        isSelected: isSelected,
                        onTap: () => onCheckSelected(entry.key),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  const _CheckItem({
    required this.name,
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final TaskStatus status;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEFF6FF)) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            _getStatusIcon(status),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected && !isDark ? const Color(0xFF1F2937) : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (status == TaskStatus.failed || status == TaskStatus.infraFailure)
              TextButton(
                onPressed: () {},
                child: Text(
                  'Re-run',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF58A6FF) : const Color(0xFF0969DA),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.succeeded:
        return const Icon(Icons.check_circle_outline, color: Color(0xFF2DA44E), size: 18);
      case TaskStatus.failed:
      case TaskStatus.infraFailure:
        return const Icon(Icons.error_outline, color: Color(0xFFF85149), size: 18);
      case TaskStatus.inProgress:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD29922)),
          ),
        );
      default:
        return const Icon(Icons.help_outline, color: Colors.grey, size: 18);
    }
  }
}
