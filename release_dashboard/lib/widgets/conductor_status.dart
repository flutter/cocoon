// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../state/status_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

import 'common/tooltip.dart';

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

  static final List<String> engineRepoElements = <String>[
    'Engine Candidate Branch',
    'Engine Starting Git HEAD',
    'Engine Current Git HEAD',
    'Engine Path to Checkout',
    'Engine LUCI Dashboard',
  ];

  static final List<String> frameworkRepoElements = <String>[
    'Framework Candidate Branch',
    'Framework Starting Git HEAD',
    'Framework Current Git HEAD',
    'Framework Path to Checkout',
    'Framework LUCI Dashboard',
  ];
}

class ConductorStatusState extends State<ConductorStatus> {
  @override
  Widget build(BuildContext context) {
    final Map<String, Object>? releaseStatus = context.watch<StatusState>().releaseStatus;
    if (context.watch<StatusState>().releaseStatus == null) {
      return SelectableText('No persistent state file. Try starting a release.');
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
                  SelectableText((currentStatus[headerElement] == null || currentStatus[headerElement] == '')
                      ? 'Unknown'
                      : currentStatus[headerElement]! as String),
                ],
              ),
          ],
        ),
        const SizedBox(height: 20.0),
        Wrap(
          children: <Widget>[
            Column(
              children: <Widget>[
                RepoInfoExpansion(engineOrFramework: 'engine', currentStatus: currentStatus),
                const SizedBox(height: 10.0),
                CherrypickTable(engineOrFramework: 'engine', currentStatus: currentStatus),
              ],
            ),
            const SizedBox(width: 20.0),
            Column(
              children: <Widget>[
                RepoInfoExpansion(engineOrFramework: 'framework', currentStatus: currentStatus),
                const SizedBox(height: 10.0),
                CherrypickTable(engineOrFramework: 'framework', currentStatus: currentStatus),
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
                      ? ConductorStatus.engineRepoElements
                      : ConductorStatus.frameworkRepoElements)
                    TableRow(
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.grey))),
                      children: <Widget>[
                        Text('$repoElement:'),
                        SelectableText(
                            (widget.releaseStatus[repoElement] == null || widget.releaseStatus[repoElement] == '')
                                ? 'Unknown'
                                : widget.releaseStatus[repoElement]! as String),
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
