// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../state/status_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'common/tooltip.dart';
import 'common/url_button.dart';

enum StatusSubstepType {
  candidateBranch,
  startingGitHead,
  currentGitHead,
  checkoutPath,
  dashboardLink,
}

/// Displays the current conductor state.
class ConductorStatus extends StatefulWidget {
  const ConductorStatus({Key? key}) : super(key: key);

  @override
  State<ConductorStatus> createState() => ConductorStatusState();

  static final List<String> headerElements = <String>[
    'Conductor Version',
    'Release Channel',
    'Release Version',
    'Release Started at',
    'Release Updated at',
    'Dart SDK Revision',
  ];

  static final Map<StatusSubstepType, String> engineRepoElements = <StatusSubstepType, String>{
    StatusSubstepType.candidateBranch: 'Engine Candidate Branch',
    StatusSubstepType.startingGitHead: 'Engine Starting Git HEAD',
    StatusSubstepType.currentGitHead: 'Engine Current Git HEAD',
    StatusSubstepType.checkoutPath: 'Engine Path to Checkout',
    StatusSubstepType.dashboardLink: 'Engine LUCI Dashboard',
  };

  static final Map<StatusSubstepType, String> frameworkRepoElements = <StatusSubstepType, String>{
    StatusSubstepType.candidateBranch: 'Framework Candidate Branch',
    StatusSubstepType.startingGitHead: 'Framework Starting Git HEAD',
    StatusSubstepType.currentGitHead: 'Framework Current Git HEAD',
    StatusSubstepType.checkoutPath: 'Framework Path to Checkout',
    StatusSubstepType.dashboardLink: 'Framework LUCI Dashboard',
  };
}

class ConductorStatusState extends State<ConductorStatus> {
  @override
  Widget build(BuildContext context) {
    final Map<String, Object>? releaseStatus = context.watch<StatusState>().releaseStatus;
    if (context.watch<StatusState>().releaseStatus == null) {
      return const SelectableText('No persistent state file. Try starting a release.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Table(
          columnWidths: const <int, TableColumnWidth>{
            0: FixedColumnWidth(200.0),
          },
          children: <TableRow>[
            for (String headerElement in ConductorStatus.headerElements)
              TableRow(
                children: <Widget>[
                  Text('$headerElement:'),
                  SelectableText(statusElementToString(releaseStatus![headerElement])),
                ],
              ),
          ],
        ),
        const SizedBox(height: 20.0),
        Wrap(
          children: <Widget>[
            Column(
              children: <Widget>[
                RepoInfoExpansion(engineOrFramework: 'engine', releaseStatus: releaseStatus!),
                const SizedBox(height: 10.0),
                CherrypickTable(engineOrFramework: 'engine', releaseStatus: releaseStatus),
              ],
            ),
            const SizedBox(width: 20.0),
            Column(
              children: <Widget>[
                RepoInfoExpansion(engineOrFramework: 'framework', releaseStatus: releaseStatus),
                const SizedBox(height: 10.0),
                CherrypickTable(engineOrFramework: 'framework', releaseStatus: releaseStatus),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Widget for showing the engine and framework cherrypicks applied to the current release.
///
/// Shows the cherrypicks' SHA and status in two separate table DataRow cells.
class CherrypickTable extends StatefulWidget {
  const CherrypickTable({
    Key? key,
    required this.engineOrFramework,
    required this.releaseStatus,
  }) : super(key: key);

  final String engineOrFramework;
  final Map<String, Object> releaseStatus;

  @override
  State<CherrypickTable> createState() => CherrypickTableState();
}

class CherrypickTableState extends State<CherrypickTable> {
  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> cherrypicks = widget.engineOrFramework == 'engine'
        ? widget.releaseStatus['Engine Cherrypicks']! as List<Map<String, String>>
        : widget.releaseStatus['Framework Cherrypicks']! as List<Map<String, String>>;

    return DataTable(
      dataRowHeight: 30.0,
      headingRowHeight: 30.0,
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      columns: <DataColumn>[
        DataColumn(label: Text('${widget.engineOrFramework == 'engine' ? 'Engine' : 'Framework'} Cherrypicks')),
        DataColumn(
          label: Row(
            children: <Widget>[
              const Text('Status'),
              const SizedBox(width: 10.0),
              InfoTooltip(
                tooltipName: widget.engineOrFramework,
                tooltipMessage: '''
PENDING:   The cherrypick has not yet been applied.
PENDING_WITH_CONFLICT:   The cherrypick has not been applied and will require manual resolution.
COMPLETED:   The cherrypick has been successfully applied to the local checkout.
ABANDONED:   The cherrypick will NOT be applied in this release.''',
              ),
            ],
          ),
        ),
      ],
      rows: cherrypicks.map((Map<String, String> cherrypick) {
        return DataRow(
          cells: <DataCell>[
            DataCell(
              SelectableText(cherrypick['trunkRevision']!),
            ),
            DataCell(
              SelectableText(cherrypick['state']!),
            ),
          ],
        );
      }).toList(),
    );
  }
}

/// Widget to display repo info related to the engine and framework.
///
/// Click to show/hide the repo info in a dropdown fashion. By default the section is hidden.
class RepoInfoExpansion extends StatefulWidget {
  const RepoInfoExpansion({
    Key? key,
    required this.engineOrFramework,
    required this.releaseStatus,
  }) : super(key: key);

  final String engineOrFramework;
  final Map<String, Object> releaseStatus;

  @override
  State<RepoInfoExpansion> createState() => RepoInfoExpansionState();
}

class RepoInfoExpansionState extends State<RepoInfoExpansion> {
  bool _isExpanded = false;

  /// Show/hide [ExpansionPanel].
  void showHide() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  /// Helper function to determine if a clickable [UrlButton] should be rendered instead of a [SelectableText].
  bool isClickable(String repoElement) {
    List<String> clickableElements = <String>[
      ConductorStatus.engineRepoElements[StatusSubstepType.dashboardLink]!,
      ConductorStatus.engineRepoElements[StatusSubstepType.checkoutPath]!,
      ConductorStatus.frameworkRepoElements[StatusSubstepType.dashboardLink]!,
      ConductorStatus.frameworkRepoElements[StatusSubstepType.checkoutPath]!
    ];
    return (clickableElements.contains(repoElement));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500.0,
      child: ExpansionPanelList(
        expandedHeaderPadding: EdgeInsets.zero,
        expansionCallback: (int index, bool isExpanded) {
          showHide();
        },
        children: <ExpansionPanel>[
          ExpansionPanel(
            isExpanded: _isExpanded,
            headerBuilder: (BuildContext context, bool isExpanded) {
              return ListTile(
                  key: Key('${widget.engineOrFramework}RepoInfoDropdown'),
                  title: Text('${widget.engineOrFramework == 'engine' ? 'Engine' : 'Framework'} Repo Info'),
                  onTap: () {
                    showHide();
                  });
            },
            body: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Table(
                columnWidths: const <int, TableColumnWidth>{
                  0: FixedColumnWidth(240.0),
                },
                children: <TableRow>[
                  for (String repoElement in widget.engineOrFramework == 'engine'
                      ? ConductorStatus.engineRepoElements.values
                      : ConductorStatus.frameworkRepoElements.values)
                    TableRow(
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.grey))),
                      children: <Widget>[
                        Text('$repoElement:'),
                        isClickable(repoElement)
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: UrlButton(
                                  textToDisplay: statusElementToString(widget.releaseStatus[repoElement]),
                                  urlOrUri: statusElementToString(widget.releaseStatus[repoElement]),
                                ),
                              )
                            : SelectableText(statusElementToString(widget.releaseStatus[repoElement])),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Converts each status element from an Object to a String.
///
/// Returns [Unknown] string if the element is empty.
String statusElementToString(Object? statusElement) {
  return ((statusElement == null || statusElement == '') ? 'Unknown' : statusElement as String);
}
