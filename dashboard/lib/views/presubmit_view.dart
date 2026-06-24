// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_common/build_log_url.dart';
import 'package:cocoon_common/guard_status.dart';
import 'package:cocoon_common/rpc_model.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../dashboard_navigation_drawer.dart';
import '../logic/task_sorting.dart';
import '../state/presubmit.dart';
import '../widgets/app_bar.dart';
import '../widgets/filter_dialog.dart';
import '../widgets/guard_status.dart' as pw;
import '../widgets/sha_selector.dart';
import '../widgets/task_box.dart';

/// A detailed monitoring view for a specific Pull Request (PR) or commit SHA.
///
/// This view displays CI job statuses and execution details.
final class PreSubmitView extends StatefulWidget {
  const PreSubmitView({
    super.key,
    this.queryParameters,
    this.syncNavigation = true,
    this.isMobile = false,
  });

  static const String routeSegment = 'presubmit';
  static const String routeName = '/$routeSegment';

  final Map<String, String>? queryParameters;
  final bool syncNavigation;
  final bool isMobile;

  @override
  State<PreSubmitView> createState() => _PreSubmitViewState();
}

class _PreSubmitViewState extends State<PreSubmitView>
    with WidgetsBindingObserver {
  PresubmitState? _presubmitState;
  late Map<String, String> _currentQueryParams;

  @override
  void initState() {
    super.initState();
    _currentQueryParams = widget.queryParameters ?? {};
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newState = Provider.of<PresubmitState>(context);
    if (_presubmitState != newState) {
      _presubmitState?.removeListener(_onStateChanged);
      _presubmitState = newState;
      _presubmitState?.addListener(_onStateChanged);
    }
    final isMobile = widget.isMobile || MediaQuery.of(context).size.width < 600;
    _presubmitState?.setMobile(isMobile);
    _triggerUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _presubmitState?.removeListener(_onStateChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _presubmitState?.resume();
    } else {
      _presubmitState?.pause();
    }
  }

  @override
  void didUpdateWidget(PreSubmitView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.queryParameters != oldWidget.queryParameters) {
      _currentQueryParams = widget.queryParameters ?? {};
      _triggerUpdate();
    }
  }

  void _onStateChanged() {
    if (!mounted || !widget.syncNavigation) return;
    final state = _presubmitState!;

    if (!mapEquals(_currentQueryParams, state.queryParameters)) {
      _updateNavigation();
    }
  }

  void _updateNavigation() {
    final state = _presubmitState!;
    _currentQueryParams = Map<String, String>.from(state.queryParameters);

    final uri = Uri(
      path: PreSubmitView.routeName,
      queryParameters: _currentQueryParams.isEmpty ? null : _currentQueryParams,
    );

    // Update the URL without triggering a full navigation/rebuild cycle.
    SystemNavigator.routeInformationUpdated(uri: uri, replace: true);
  }

  void _triggerUpdate() {
    final params = widget.queryParameters ?? {};
    final state = Provider.of<PresubmitState>(context, listen: false);
    state.syncUpdate(params);

    // Schedule fetch outside of build phase to avoid notify-during-build
    Future.microtask(() {
      if (!mounted) return;
      state.fetchIfNeeded();
    });
  }

  Future<void> _showErrorDialog(String message) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final presubmitState = Provider.of<PresubmitState>(context);

    return AnimatedBuilder(
      animation: presubmitState,
      builder: (context, _) {
        final pr = presubmitState.pr;
        final sha = presubmitState.sha;
        final repo = presubmitState.repo;

        final guardResponse = presubmitState.guardResponse;
        final isLoading = presubmitState.isLoading;
        final selectedJob = presubmitState.selectedJob;

        var availableSummaries = presubmitState.availableSummaries;

        if (sha != null && !availableSummaries.any((s) => s.headSha == sha)) {
          availableSummaries = [
            PresubmitGuardSummary(
              headSha: sha,
              creationTime: 0,
              guardStatus: GuardStatus.waitingForBackfill,
            ),
            ...availableSummaries,
          ];
        }

        final shortSha = (sha != null && sha.length > 7)
            ? sha.substring(0, 7)
            : sha;
        final isMobile =
            widget.isMobile ||
            MediaQuery.of(context).size.width < 600;
        if (presubmitState.isMobile != isMobile) {
          Future.microtask(() {
            if (mounted) presubmitState.setMobile(isMobile);
          });
        }
        final title = guardResponse != null
            ? (isMobile
                  ? '${guardResponse.prNum}'
                  : 'PR #${guardResponse.prNum} by ${guardResponse.author} ($shortSha)')
            : (pr != null ? 'PR #$pr' : (sha != null ? '($shortSha)' : ''));

        var statusText = (pr != null ? 'Pending' : 'Loading...');
        if (guardResponse != null) {
          statusText = guardResponse.guardStatus.value;
        } else if (sha != null) {
          final summary = presubmitState.availableSummaries.firstWhere(
            (s) => s.headSha == sha,
            orElse: () => const PresubmitGuardSummary(
              headSha: '',
              creationTime: 0,
              guardStatus: GuardStatus.waitingForBackfill,
            ),
          );
          if (summary.headSha.isNotEmpty) {
            statusText = summary.guardStatus.value;
          }
        }

        final isLatestSha =
            pr != null &&
            presubmitState.availableSummaries.isNotEmpty &&
            sha == presubmitState.availableSummaries.first.headSha;

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
                if (!isMobile) ...[
                  const SizedBox(width: 16),
                  pw.GuardStatus(status: statusText),
                ],
              ],
            ),
            actions: [
              Center(
                child: SizedBox(
                  width: isMobile ? 120 : 300,
                  child: ShaSelector(
                    availableShas: availableSummaries,
                    selectedSha: sha,
                    isMobile: isMobile,
                    onShaSelected: (newSha) {
                      presubmitState.update(repo: repo, pr: pr, sha: newSha);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          drawer: const DashboardNavigationDrawer(),
          body: isLoading && guardResponse == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    const Divider(height: 1, thickness: 1),
                    Expanded(
                      child: SelectionArea(
                        child: isMobile
                            ? (selectedJob == null
                                  ? (guardResponse != null
                                        ? _buildJobsSidebarPane(
                                            presubmitState: presubmitState,
                                            isMobile: true,
                                            guardResponse: guardResponse,
                                            isLatestSha: isLatestSha,
                                            isDark: isDark,
                                            selectedJob: selectedJob,
                                          )
                                        : const Center(
                                            child: Text('No stages available.'),
                                          ))
                                  : _JobDetailsViewerPane(
                                      isMobile: true,
                                      onError: _showErrorDialog,
                                    ))
                            : Row(
                                children: [
                                  if (guardResponse != null)
                                    SizedBox(
                                      width: 350,
                                      child: _buildJobsSidebarPane(
                                        presubmitState: presubmitState,
                                        isMobile: false,
                                        guardResponse: guardResponse,
                                        isLatestSha: isLatestSha,
                                        isDark: isDark,
                                        selectedJob: selectedJob,
                                      ),
                                    ),
                                  const VerticalDivider(width: 1, thickness: 1),
                                  Expanded(
                                    child:
                                        (selectedJob == null ||
                                            guardResponse == null)
                                        ? const Center(
                                            child: Text(
                                              'Select a job to view execution details.',
                                            ),
                                          )
                                        : _JobDetailsViewerPane(
                                            isMobile: false,
                                            onError: _showErrorDialog,
                                          ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildJobsSidebarPane({
    required PresubmitState presubmitState,
    required bool isMobile,
    required PresubmitGuardResponse guardResponse,
    required bool isLatestSha,
    required bool isDark,
    required String? selectedJob,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              TextButton.icon(
                  icon: Icon(
                    presubmitState.isAnyFilterApplied
                        ? Icons.filter_alt
                        : Icons.filter_alt_outlined,
                  ),
                  label: const Text('Filter jobs', softWrap: false),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(64, 18),
                    foregroundColor: isDark ? Colors.white : Colors.black,
                  ),
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (context) => const FilterDialog(),
                    );
                  },
              ),
              const Spacer(),
              if (isLatestSha)
                TextButton.icon(
                  onPressed: (!presubmitState.canRerunAllFailedJobs)
                      ? null
                      : () async {
                          final error = await presubmitState
                              .rerunAllFailedJobs();
                          if (!mounted) return;
                          if (error != null) {
                            await _showErrorDialog(error);
                          }
                        },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Re-run failed', softWrap: false),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(64, 18),
                    foregroundColor: isDark
                        ? const Color(0xFF58A6FF)
                        : const Color(0xFF0969DA),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: _JobsSidebar(
            guardResponse:
                presubmitState.filteredGuardResponse ?? guardResponse,
            selectedJob: selectedJob,
            isLatestSha: isLatestSha,
            isMobile: isMobile,
            onJobSelected: presubmitState.selectJob,
            onError: _showErrorDialog,
          ),
        ),
      ],
    );
  }
}

class _JobDetailsViewerPane extends StatefulWidget {
  const _JobDetailsViewerPane({required this.onError, this.isMobile = false});

  final ValueChanged<String> onError;
  final bool isMobile;

  @override
  State<_JobDetailsViewerPane> createState() => _JobDetailsViewerPaneState();
}

class _JobDetailsViewerPaneState extends State<_JobDetailsViewerPane> {
  int _selectedAttemptIndex = 0;
  int _selectedDetailTabIndex = 0;
  String? _lastJobName;
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final presubmitState = Provider.of<PresubmitState>(context);
    final jobName = presubmitState.selectedJob;

    if (_lastJobName != jobName) {
      _lastJobName = jobName;
      _selectedAttemptIndex = 0;
      _selectedDetailTabIndex = 0;
    }

    return AnimatedBuilder(
      animation: presubmitState,
      builder: (context, _) {
        final repo = presubmitState.repo;
        final jobs = presubmitState.jobs;
        final isLoading = presubmitState.isLoading;

        final borderColor = isDark
            ? const Color(0xFF333333)
            : const Color(0xFFD1D5DB);

        if (isLoading && (jobs == null || jobs.isEmpty)) {
          return const Center(child: CircularProgressIndicator());
        }

        if (jobs == null || jobs.isEmpty) {
          return const Center(child: Text('No details found for this job'));
        }

        if (_selectedAttemptIndex >= jobs.length) {
          _selectedAttemptIndex = 0;
        }

        final selectedJob = jobs[_selectedAttemptIndex];
        final hasLogAnalysis =
            selectedJob.logAnalysis != null &&
            selectedJob.logAnalysis!.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isMobile) ...[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: () => presubmitState.selectJob(null),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back,
                            size: 18,
                            color: isDark
                                ? const Color(0xFF58A6FF)
                                : const Color(0xFF0969DA),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Back to jobs',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF58A6FF)
                                    : const Color(0xFF0969DA),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
            ],
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$repo / $jobName',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: ${selectedJob.status}',
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
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: jobs.asMap().entries.map((entry) {
                          final index = entry.key;
                          final job = entry.value;
                          final isSelected = _selectedAttemptIndex == index;
                          return InkWell(
                            onTap: () =>
                                setState(() => _selectedAttemptIndex = index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
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
                                '#${job.attemptNumber}',
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
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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

            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (hasLogAnalysis) ...[
                            _buildDetailTab('Log Analysis', 0, isDark),
                            _buildDetailTab('Execution Details', 1, isDark),
                          ] else
                            const Text(
                              'Execution Details',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Raw output',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            //const SizedBox(height: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8.0),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                width: double.infinity,
                child: SingleChildScrollView(
                  child: GptMarkdown(
                    hasLogAnalysis && _selectedDetailTabIndex == 0
                        ? selectedJob.logAnalysis!
                        : (selectedJob.summary?.trim().isEmpty ?? true
                              ? _getDefaultJobDetails(selectedJob)
                              : selectedJob.summary!),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: selectedJob.buildNumber == null
                        ? null
                        : () async => await launchUrl(
                            Uri.parse(
                              generatePreSubmitBuildLogUrl(
                                buildName: selectedJob.jobName,
                                buildNumber: selectedJob.buildNumber!,
                              ),
                            ),
                          ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.open_in_new,
                          size: 18,
                          color: selectedJob.buildNumber == null
                              ? Colors.grey
                              : (isDark
                                    ? const Color(0xFF58A6FF)
                                    : const Color(0xFF0969DA)),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'View more details on LUCI UI',
                            style: TextStyle(
                              color: selectedJob.buildNumber == null
                                  ? Colors.grey
                                  : (isDark
                                        ? const Color(0xFF58A6FF)
                                        : const Color(0xFF0969DA)),
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (presubmitState.canAnalyzeLog(selectedJob))
                    ElevatedButton(
                      onPressed: _isAnalyzing
                          ? null
                          : () async {
                              setState(() => _isAnalyzing = true);
                              try {
                                final error = await presubmitState.analyzeLogs(
                                  selectedJob,
                                );
                                if (error == null) {
                                  await presubmitState.fetchJobDetails();
                                } else {
                                  widget.onError(error);
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isAnalyzing = false);
                                }
                              }
                            },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isAnalyzing) ...[
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                          ],
                          const Flexible(
                            child: Text(
                              'Analyze Logs with Gemini',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailTab(String label, int index, bool isDark) {
    final isSelected = _selectedDetailTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedDetailTabIndex = index),
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
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? const Color(0xFF8B949E) : const Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }

  String _getDefaultJobDetails(PresubmitJobResponse job) {
    return switch (job.status) {
      .succeeded =>
        '${job.jobName} executed successfully.\nClick "View more details on LUCI UI" button below for more details.',
      .failed =>
        '${job.jobName} failed.\nClick "View more details on LUCI UI" button below for more details.',
      .infraFailure =>
        'Infrastructure failed during execution of ${job.jobName}.\nClick "View more details on LUCI UI" button below for more details.',
      .skipped => '${job.jobName} is skipped.',
      .neutral => '${job.jobName} is disabled.',
      .cancelled => '${job.jobName} is cancelled.',
      .inProgress =>
        '${job.jobName} is in progress.\nClick "View more details on LUCI UI" button below to see execution details.',
      .waitingForBackfill =>
        '${job.jobName} is not yet scheduled for execution.\n"View more details on LUCI UI" button will become enabled once the job is scheduled.',
    };
  }
}

class _JobsSidebar extends StatefulWidget {
  const _JobsSidebar({
    required this.guardResponse,
    this.selectedJob,
    this.isLatestSha = false,
    this.isMobile = false,
    required this.onJobSelected,
    required this.onError,
  });

  final PresubmitGuardResponse guardResponse;
  final String? selectedJob;
  final bool isLatestSha;
  final bool isMobile;
  final ValueChanged<String?> onJobSelected;
  final ValueChanged<String> onError;

  @override
  State<_JobsSidebar> createState() => _JobsSidebarState();
}

class _JobsSidebarState extends State<_JobsSidebar> {
  final ScrollController _scrollController = ScrollController();
  late List<List<MapEntry<String, TaskStatus>>> _sortedBuildsPerStage;

  @override
  void initState() {
    super.initState();
    _updateSortedBuilds();
    _selectFirstJob();
  }

  @override
  void didUpdateWidget(_JobsSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.guardResponse != oldWidget.guardResponse) {
      _updateSortedBuilds();
    }
    if (widget.selectedJob == null) {
      _selectFirstJob();
    }
  }

  void _selectFirstJob() {
    if (widget.isMobile || widget.selectedJob != null) return;
    for (final stage in _sortedBuildsPerStage) {
      if (stage.isNotEmpty) {
        final firstJob = stage.first.key;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.selectedJob == null) {
            widget.onJobSelected(firstJob);
          }
        });
        break;
      }
    }
  }

  void _updateSortedBuilds() {
    _sortedBuildsPerStage = widget.guardResponse.stages.map((stage) {
      return stage.builds.entries.toList()
        ..sort((a, b) => compareTasks(a.key, a.value, b.key, b.value));
    }).toList();
  }

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
      width: widget.isMobile ? double.infinity : 350,
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
                  final sortedBuilds = _sortedBuildsPerStage[stageIndex];
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
                      ...sortedBuilds.map((entry) {
                        final isSelected = widget.selectedJob == entry.key;
                        return _JobItem(
                          name: entry.key,
                          status: entry.value,
                          isSelected: isSelected,
                          isLatestSha: widget.isLatestSha,
                          isMobile: widget.isMobile,
                          onTap: () => widget.onJobSelected(entry.key),
                          onError: widget.onError,
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

class _JobItem extends StatelessWidget {
  const _JobItem({
    required this.name,
    required this.status,
    required this.isSelected,
    this.isLatestSha = false,
    this.isMobile = false,
    required this.onTap,
    required this.onError,
  });

  final String name;
  final TaskStatus status;
  final bool isSelected;
  final bool isLatestSha;
  final bool isMobile;
  final VoidCallback onTap;
  final ValueChanged<String> onError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final presubmitState = Provider.of<PresubmitState>(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: isSelected && !isDark ? const Color(0xFF1F2937) : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isLatestSha &&
                (status == TaskStatus.failed ||
                    status == TaskStatus.infraFailure))
              TextButton.icon(
                onPressed: (!presubmitState.canRerunFailedJob(name))
                    ? null
                    : () async {
                        final error = await presubmitState.rerunFailedJob(name);
                        if (error != null) {
                          onError(error);
                        }
                      },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Re-run'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(64, 8),
                  foregroundColor: isDark
                      ? const Color(0xFF58A6FF)
                      : const Color(0xFF0969DA),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _getStatusIcon(TaskStatus status) {
    switch (status) {
      case .succeeded:
        return Icon(
          Icons.check_circle_outline,
          color: TaskBox.statusColor[status],
          size: 18,
        );
      case .failed:
        return Icon(
          Icons.error_outline,
          color: TaskBox.statusColor[status],
          size: 18,
        );
      case .infraFailure:
        return Icon(
          Icons.error_outline,
          color: TaskBox.statusColor[status],
          size: 18,
        );
      case .waitingForBackfill:
        return Icon(
          Icons.not_started_outlined,
          color: TaskBox.statusColor[status],
          size: 18,
        );
      case .skipped:
        return Icon(
          Icons.do_not_disturb_on_outlined,
          color: TaskBox.statusColor[status],
          size: 18,
        );
      case .neutral:
        return Icon(Icons.flaky, color: TaskBox.statusColor[status], size: 18);
      case .cancelled:
        return Icon(
          Icons.block_outlined,
          color: TaskBox.statusColor[status],
          size: 18,
        );
      case .inProgress:
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
