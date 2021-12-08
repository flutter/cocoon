// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/repositories_name.dart';
import '../models/cherrypick.dart';
import '../models/conductor_status.dart';
import '../models/repositories.dart';
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

  static const Map<ConductorStatusEntry, String> headerElements = <ConductorStatusEntry, String>{
    ConductorStatusEntry.conductorVersion: 'Conductor Version',
    ConductorStatusEntry.releaseChannel: 'Release Channel',
    ConductorStatusEntry.releaseVersion: 'Release Version',
    ConductorStatusEntry.startedAt: 'Release Started at',
    ConductorStatusEntry.updatedAt: 'Release Updated at',
    ConductorStatusEntry.dartRevision: 'Dart SDK Revision',
  };

  static const Map<ConductorStatusEntry, String> engineRepoElements = <ConductorStatusEntry, String>{
    ConductorStatusEntry.engineCandidateBranch: 'Engine Candidate Branch',
    ConductorStatusEntry.engineStartingGitHead: 'Engine Starting Git HEAD',
    ConductorStatusEntry.engineCurrentGitHead: 'Engine Current Git HEAD',
    ConductorStatusEntry.engineCheckoutPath: 'Engine Path to Checkout',
    ConductorStatusEntry.engineLuciDashboard: 'Engine LUCI Dashboard',
  };

  static const Map<ConductorStatusEntry, String> frameworkRepoElements = <ConductorStatusEntry, String>{
    ConductorStatusEntry.frameworkCandidateBranch: 'Framework Candidate Branch',
    ConductorStatusEntry.frameworkStartingGitHead: 'Framework Starting Git HEAD',
    ConductorStatusEntry.frameworkCurrentGitHead: 'Framework Current Git HEAD',
    ConductorStatusEntry.frameworkCheckoutPath: 'Framework Path to Checkout',
    ConductorStatusEntry.frameworkLuciDashboard: 'Framework LUCI Dashboard',
  };
}

class ConductorStatusState extends State<ConductorStatus> {
  @override
  Widget build(BuildContext context) {
    final Map<ConductorStatusEntry, Object>? releaseStatus = context.watch<StatusState>().releaseStatus;
    if (releaseStatus == null) {
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
                  SelectableText(statusElementToString(releaseStatus[headerElement.key])),
                ],
              ),
          ],
        ),
        const SizedBox(height: 20.0),
        Wrap(
          children: <Widget>[
            Column(
              children: const <Widget>[
                RepoInfoExpansion(repository: Repositories.engine),
                SizedBox(height: 10.0),
                CherrypickTable(repository: Repositories.engine),
              ],
            ),
            const SizedBox(width: 20.0),
            Column(
              children: const <Widget>[
                RepoInfoExpansion(repository: Repositories.framework),
                SizedBox(height: 10.0),
                CherrypickTable(repository: Repositories.framework),
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
    required this.repository,
  }) : super(key: key);

  final Repositories repository;

  @override
  State<CherrypickTable> createState() => CherrypickTableState();
}

class CherrypickTableState extends State<CherrypickTable> {
  @override
  Widget build(BuildContext context) {
    final Map<ConductorStatusEntry, Object>? releaseStatus = context.watch<StatusState>().releaseStatus;

    final List<Map<Cherrypick, String>> cherrypicks = widget.repository == Repositories.engine
        ? releaseStatus![ConductorStatusEntry.engineCherrypicks]! as List<Map<Cherrypick, String>>
        : releaseStatus![ConductorStatusEntry.frameworkCherrypicks]! as List<Map<Cherrypick, String>>;

    return DataTable(
      dataRowHeight: 30.0,
      headingRowHeight: 30.0,
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      columns: <DataColumn>[
        DataColumn(label: Text('${repositoryName(widget.repository, true)} Cherrypicks')),
        DataColumn(
          label: Row(
            children: <Widget>[
              const Text('Status'),
              const SizedBox(width: 10.0),
              InfoTooltip(
                tooltipName: repositoryName(widget.repository, true),
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
      rows: cherrypicks.map((Map<Cherrypick, String> cherrypickMap) {
        return DataRow(
          cells: <DataCell>[
            DataCell(
              SelectableText(cherrypickMap[Cherrypick.trunkRevision]!),
            ),
            DataCell(
              SelectableText(cherrypickMap[Cherrypick.state]!),
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
    required this.repository,
  }) : super(key: key);

  final Repositories repository;

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
  bool isClickable(ConductorStatusEntry repoElement) {
    List<ConductorStatusEntry> clickableElements = <ConductorStatusEntry>[
      ConductorStatusEntry.engineLuciDashboard,
      ConductorStatusEntry.engineCheckoutPath,
      ConductorStatusEntry.frameworkLuciDashboard,
      ConductorStatusEntry.frameworkCheckoutPath,
    ];
    return (clickableElements.contains(repoElement));
  }

  @override
  Widget build(BuildContext context) {
    final Map<ConductorStatusEntry, Object>? releaseStatus = context.watch<StatusState>().releaseStatus;

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
                  key: Key('${repositoryName(widget.repository)}RepoInfoDropdown'),
                  title: Text('${repositoryName(widget.repository, true)} Repo Info'),
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
                  for (MapEntry repoElement in widget.repository == Repositories.engine
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
