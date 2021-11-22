// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../enums/cherrypick.dart';
import '../enums/conductor_status.dart';
import '../state/status_state.dart';
import 'common/tooltip.dart';
import 'common/url_button.dart';

/// Widget that displays the current conductor state.
///
/// Engine and framework repo info such as the candidate branch, GIT heads, etc. are
/// displayed in a dropdown widget, and they are collapsed by default.
class ConductorStatus extends StatefulWidget {
  const ConductorStatus({Key? key}) : super(key: key);

  @override
  State<ConductorStatus> createState() => ConductorStatusState();

  static const Map<conductorStatus, String> headerElements = <conductorStatus, String>{
    conductorStatus.conductorVersion: 'Conductor Version',
    conductorStatus.releaseChannel: 'Release Channel',
    conductorStatus.releaseVersion: 'Release Version',
    conductorStatus.startedAt: 'Release Started at',
    conductorStatus.updatedAt: 'Release Updated at',
    conductorStatus.dartRevision: 'Dart SDK Revision',
  };

  static const Map<conductorStatus, String> engineRepoElements = <conductorStatus, String>{
    conductorStatus.engineCandidateBranch: 'Engine Candidate Branch',
    conductorStatus.engineStartingGitHead: 'Engine Starting Git HEAD',
    conductorStatus.engineCurrentGitHead: 'Engine Current Git HEAD',
    conductorStatus.engineCheckoutPath: 'Engine Path to Checkout',
    conductorStatus.engineLUCIDashboard: 'Engine LUCI Dashboard',
  };

  static const Map<conductorStatus, String> frameworkRepoElements = <conductorStatus, String>{
    conductorStatus.frameworkCandidateBranch: 'Framework Candidate Branch',
    conductorStatus.frameworkStartingGitHead: 'Framework Starting Git HEAD',
    conductorStatus.frameworkCurrentGitHead: 'Framework Current Git HEAD',
    conductorStatus.frameworkCheckoutPath: 'Framework Path to Checkout',
    conductorStatus.frameworkLUCIDashboard: 'Framework LUCI Dashboard',
  };
}

class ConductorStatusState extends State<ConductorStatus> {
  @override
  Widget build(BuildContext context) {
    final Map<conductorStatus, Object>? releaseStatus = context.watch<StatusState>().releaseStatus;
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
            for (MapEntry headerElement in ConductorStatus.headerElements.entries)
              TableRow(
                children: <Widget>[
                  Text('${headerElement.value}:'),
                  SelectableText(statusElementToString(releaseStatus![headerElement.key])),
                ],
              ),
          ],
        ),
        const SizedBox(height: 20.0),
        Wrap(
          children: <Widget>[
            Column(
              children: const <Widget>[
                RepoInfoExpansion(engineOrFramework: 'engine'),
                SizedBox(height: 10.0),
                CherrypickTable(engineOrFramework: 'engine'),
              ],
            ),
            const SizedBox(width: 20.0),
            Column(
              children: const <Widget>[
                RepoInfoExpansion(engineOrFramework: 'framework'),
                SizedBox(height: 10.0),
                CherrypickTable(engineOrFramework: 'framework'),
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
  }) : super(key: key);

  final String engineOrFramework;

  @override
  State<CherrypickTable> createState() => CherrypickTableState();
}

class CherrypickTableState extends State<CherrypickTable> {
  @override
  Widget build(BuildContext context) {
    final Map<conductorStatus, Object>? releaseStatus = context.watch<StatusState>().releaseStatus;

    final List<Map<cherrypick, String>> cherrypicks = widget.engineOrFramework == 'engine'
        ? releaseStatus![conductorStatus.engineCherrypicks]! as List<Map<cherrypick, String>>
        : releaseStatus![conductorStatus.frameworkCherrypicks]! as List<Map<cherrypick, String>>;

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
      rows: cherrypicks.map((Map<cherrypick, String> cherrypickMap) {
        return DataRow(
          cells: <DataCell>[
            DataCell(
              SelectableText(cherrypickMap[cherrypick.trunkRevision]!),
            ),
            DataCell(
              SelectableText(cherrypickMap[cherrypick.state]!),
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
  }) : super(key: key);

  final String engineOrFramework;

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
  bool isClickable(conductorStatus repoElement) {
    List<conductorStatus> clickableElements = <conductorStatus>[
      conductorStatus.engineLUCIDashboard,
      conductorStatus.engineCheckoutPath,
      conductorStatus.frameworkLUCIDashboard,
      conductorStatus.frameworkCheckoutPath,
    ];
    return (clickableElements.contains(repoElement));
  }

  @override
  Widget build(BuildContext context) {
    final Map<conductorStatus, Object>? releaseStatus = context.watch<StatusState>().releaseStatus;

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
                  // to do, navigate the map with enums

                  for (MapEntry repoElement in widget.engineOrFramework == 'engine'
                      ? ConductorStatus.engineRepoElements.entries
                      : ConductorStatus.frameworkRepoElements.entries)
                    TableRow(
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.grey))),
                      children: <Widget>[
                        Text('${repoElement.value}:'),
                        isClickable(repoElement.key)
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: UrlButton(
                                  textToDisplay: statusElementToString(releaseStatus![repoElement.key]),
                                  urlOrUri: statusElementToString(releaseStatus[repoElement.key]),
                                ),
                              )
                            : SelectableText(statusElementToString(releaseStatus![repoElement.key])),
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
