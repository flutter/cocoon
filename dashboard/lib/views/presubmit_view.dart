// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_common/guard_status.dart';
import 'package:cocoon_common/rpc_model.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dashboard_navigation_drawer.dart';
import '../state/build.dart';
import '../widgets/app_bar.dart';
import '../widgets/sha_selector.dart';
import '../widgets/task_box.dart';

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

    if (pr == '123' || (sha != null && sha!.startsWith('mock_sha_'))) {
      // Use a default mock SHA for the PR route if none selected
      sha ??= 'mock_sha_1_long_hash_value';
      pr ??= '123';
      _loadMockData(sha!);
    }
  }

  void _loadMockData(String sha) {
    // Extract the number from the mock SHA to determine which mock data to load
    // sha aways start with `mock_sha_` for mocked data, so we can safely parse
    // the number after second `_`
    final num = sha.split('_')[2];
    _guardResponse = PresubmitGuardResponse(
      prNum: int.parse(pr!),
      checkRunId: 456,
      author: 'dash',
      guardStatus: GuardStatus.inProgress,
      stages: [
        PresubmitGuardStage(
          name: 'Engine',
          createdAt: 0,
          builds: {
            'Mac mac_host_engine $num': TaskStatus.failed,
            'Mac mac_ios_engine $num': TaskStatus.waitingForBackfill,
            'Linux linux_android_aot_engine $num': TaskStatus.succeeded,
          },
        ),
        PresubmitGuardStage(
          name: 'Framework',
          createdAt: 0,
          builds: {
            'Linux framework_tests $num': TaskStatus.inProgress,
            'Mac framework_tests $num': TaskStatus.cancelled,
            'Linux android framework_tests $num': TaskStatus.skipped,
            'Windows framework_tests $num': TaskStatus.infraFailure,
          },
        ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (sha != null &&
        _guardResponse == null &&
        !_isLoading &&
        !sha!.startsWith('mock_sha_')) {
      unawaited(_fetchGuardStatus());
    }
  }

  Future<void> _fetchGuardStatus() async {
    setState(() {
      _isLoading = true;
      _selectedCheck = null;
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
    final buildState = Provider.of<BuildState>(context);

    final availableShas = pr != null
        ? [
            'mock_sha_1_long_hash_value',
            'mock_sha_2_long_hash_value',
            'mock_sha_3_long_hash_value',
            'mock_sha_4_long_hash_value',
          ]
        : buildState.statuses.map((s) => s.commit.sha).toList();

    // Ensure current sha is in the list
    if (sha != null && !availableShas.contains(sha)) {
      availableShas.insert(0, sha!);
    }

    final title = _guardResponse != null
        ? 'PR #${_guardResponse!.prNum}: [${_guardResponse!.author}]'
        : (pr != null
              ? 'PR #$pr: Feature Implementation'
              : 'PreSubmit: $repo @ $sha');

    final statusText =
        _guardResponse?.guardStatus.value ??
        (pr != null ? 'Pending' : 'Loading...');
    final statusColor = _getStatusColor(statusText, isDark);

    return Scaffold(
      appBar: CocoonAppBar(
        title: Row(
          children: [
            Flexible(
              child: SelectionArea(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
              ),
              child: SelectionArea(
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: 250,
            child: ShaSelector(
              availableShas: availableShas,
              selectedSha: sha,
              onShaSelected: (newSha) {
                setState(() {
                  sha = newSha;
                  _guardResponse = null;
                });
                if (sha!.startsWith('mock_sha_')) {
                  setState(() => _loadMockData(sha!));
                } else {
                  unawaited(_fetchGuardStatus());
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Re-run failed'),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const DashboardNavigationDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Divider(height: 1, thickness: 1),
                Expanded(
                  child: SelectionArea(
                    child: Row(
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
                              ? const Center(
                                  child: Text('Select a check to view logs'),
                                )
                              : _LogViewerPane(
                                  repo: repo,
                                  checkRunId: _guardResponse!.checkRunId,
                                  buildName: _selectedCheck!,
                                  isMocked: sha!.startsWith('mock_sha_'),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
    if (oldWidget.buildName != widget.buildName ||
        oldWidget.checkRunId != widget.checkRunId) {
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
            summary:
                '[INFO] Starting task ${widget.buildName}...\n[SUCCESS] Dependencies installed.\n[INFO] Running build script...\n[SUCCESS] All tests passed (452/452)',
          ),
          PresubmitCheckResponse(
            attemptNumber: 2,
            buildName: widget.buildName,
            creationTime: 0,
            status: 'Failed',
            summary:
                '[INFO] Starting task ${widget.buildName}...\n[ERROR] Test failed: Unit Tests',
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
    final borderColor = isDark
        ? const Color(0xFF333333)
        : const Color(0xFFD1D5DB);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_checks == null || _checks!.isEmpty) {
      return const Center(child: Text('No details found for this check'));
    }

    final selectedCheck =
        _checks![_selectedAttemptIndex < _checks!.length
            ? _selectedAttemptIndex
            : 0];

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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Status: ${selectedCheck.status}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFF8B949E)
                      : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
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
                          color: isSelected
                              ? const Color(0xFF3B82F6)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      '#${check.attemptNumber}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark
                                  ? const Color(0xFF8B949E)
                                  : const Color(0xFF6B7280)),
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              const Text(
                'BUILD HISTORY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Text(
                'Execution Log',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Spacer(),
              Text(
                'Raw output',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
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
                  color: isDark
                      ? const Color(0xFF58A6FF)
                      : const Color(0xFF0969DA),
                ),
                const SizedBox(width: 8),
                Text(
                  'View more details on LUCI UI',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF58A6FF)
                        : const Color(0xFF0969DA),
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

class _ChecksSidebar extends StatefulWidget {
  const _ChecksSidebar({
    required this.guardResponse,
    this.selectedCheck,
    required this.onCheckSelected,
  });

  final PresubmitGuardResponse guardResponse;
  final String? selectedCheck;
  final ValueChanged<String> onCheckSelected;

  @override
  State<_ChecksSidebar> createState() => _ChecksSidebarState();
}

class _ChecksSidebarState extends State<_ChecksSidebar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 350,
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: widget.guardResponse.stages.length,
                itemBuilder: (context, stageIndex) {
                  final stage = widget.guardResponse.stages[stageIndex];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: theme.scaffoldBackgroundColor,
                        child: Text(
                          stage.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFF8B949E)
                                : const Color(0xFF6B7280),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      ...stage.builds.entries.map((entry) {
                        final isSelected = widget.selectedCheck == entry.key;
                        return _CheckItem(
                          name: entry.key,
                          status: entry.value,
                          isSelected: isSelected,
                          onTap: () => widget.onCheckSelected(entry.key),
                        );
                      }),
                    ],
                  );
                },
              ),
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
          color: isSelected
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05))
              : Colors.transparent,

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
            if (status == TaskStatus.failed ||
                status == TaskStatus.infraFailure)
              TextButton(
                onPressed: () {},
                child: Text(
                  'Re-run',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF58A6FF)
                        : const Color(0xFF0969DA),
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
        return Icon(
          Icons.check_circle_outline,
          color: TaskBox.statusColor[status],
          size: 18,
        );
      case TaskStatus.failed:
        return Icon(
          Icons.error_outline,
          color: TaskBox.statusColor[status],
          size: 18,
        );
      case TaskStatus.infraFailure:
        return Icon(
          Icons.error_outline,
          color: TaskBox.statusColor[status],
          size: 18,
        );
      case TaskStatus.waitingForBackfill:
        return Icon(
          Icons.not_started_outlined,
          color: TaskBox.statusColor[status],
          size: 18,
        );
      case TaskStatus.skipped:
        return Icon(
          Icons.do_not_disturb_on_outlined,
          color: TaskBox.statusColor[status],
          size: 18,
        );
      case TaskStatus.cancelled:
        return Icon(
          Icons.block_outlined,
          color: TaskBox.statusColor[status],
          size: 18,
        );
      case TaskStatus.inProgress:
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              TaskBox.statusColor[status] ?? const Color(0xFFD29922),
            ),
          ),
        );
    }
  }
}
