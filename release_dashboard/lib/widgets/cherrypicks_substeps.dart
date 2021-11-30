// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/repositories_str.dart';
import '../models/cherrypick.dart';
import '../models/conductor_status.dart';
import '../models/repositories.dart';
import '../state/status_state.dart';
import 'common/checkbox_substep.dart';
import 'common/url_button.dart';

enum CherrypicksSubstep {
  verifyRelease,
  applyCherrypicks,
}

/// Group and display all substeps related to Apply Engine/Framework Cherrypicks step into a widget.
///
/// When all substeps are completed, [nextStep] can be executed to proceed to the next step.
class CherrypicksSubsteps extends StatefulWidget {
  const CherrypicksSubsteps({
    Key? key,
    required this.nextStep,
    required this.repository,
  }) : super(key: key);

  final VoidCallback nextStep;
  final Repositories repository;

  @override
  State<CherrypicksSubsteps> createState() => CherrypicksSubstepsState();

  static const Map<CherrypicksSubstep, String> substepTitles = <CherrypicksSubstep, String>{
    CherrypicksSubstep.verifyRelease: 'Verify the Release Number',
    CherrypicksSubstep.applyCherrypicks: 'Apply cherrypicks and resolve conflicts',
  };

  // TODO(Yugue): [conductor] add extension method that returns the cherrypick state string,
  // https://github.com/flutter/flutter/issues/94387.
  static Map<pb.CherrypickState, String> cherrypickStates = <pb.CherrypickState, String>{
    pb.CherrypickState.PENDING: 'PENDING',
    pb.CherrypickState.PENDING_WITH_CONFLICT: 'PENDING_WITH_CONFLICT',
    pb.CherrypickState.COMPLETED: 'COMPLETED',
    pb.CherrypickState.ABANDONED: 'ABANDONED',
  };

  static const String kReleaseSDKURL = 'https://flutter.dev/docs/development/tools/sdk/releases';
}

class CherrypicksSubstepsState extends State<CherrypicksSubsteps> {
  final Map<CherrypicksSubstep, bool> _isEachSubstepChecked = <CherrypicksSubstep, bool>{};

  @override
  void initState() {
    /// If [substep] is false, that [substep] is unchecked, otherwise, it is checked.
    ///
    /// All substeps are unchecked at the beginning.
    for (final CherrypicksSubstep substep in CherrypicksSubstep.values) {
      /// Verify the release number is not required for the framework.
      if (widget.repository == Repositories.framework && substep == CherrypicksSubstep.verifyRelease) {
        continue;
      }
      _isEachSubstepChecked[substep] = false;
    }
    super.initState();
  }

  /// Toggle the boolean value of [substepName].
  void substepPressed(CherrypicksSubstep substep) {
    setState(() {
      _isEachSubstepChecked[substep] = !_isEachSubstepChecked[substep]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final StatusState statusState = context.watch<StatusState>();
    final StringBuffer cherrypicksInConflict = StringBuffer();
    final ConductorStatusEntry repositoryCherrypick = widget.repository == Repositories.engine
        ? ConductorStatusEntry.engineCherrypicks
        : ConductorStatusEntry.frameworkCherrypicks;

    if (statusState.releaseStatus != null && statusState.releaseStatus?[repositoryCherrypick] != null) {
      for (Map<Cherrypick, String> cherrypick
          in statusState.releaseStatus?[repositoryCherrypick] as List<Map<Cherrypick, String>>) {
        if (cherrypick[Cherrypick.state] ==
            CherrypicksSubsteps.cherrypickStates[pb.CherrypickState.PENDING_WITH_CONFLICT]) {
          cherrypicksInConflict.writeln('git cherry-pick ${cherrypick[Cherrypick.trunkRevision]!}');
        }
      }
    }

    return Column(
      children: <Widget>[
        if (widget.repository == Repositories.engine)
          CheckboxAsSubstep(
            substepName: CherrypicksSubsteps.substepTitles[CherrypicksSubstep.verifyRelease]!,
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                    'Verify if the release number: ${statusState.releaseStatus?[ConductorStatusEntry.releaseVersion]}'
                    ' is correct based on existing published releases here: '),
                const UrlButton(
                  textToDisplay: CherrypicksSubsteps.kReleaseSDKURL,
                  urlOrUri: CherrypicksSubsteps.kReleaseSDKURL,
                ),
              ],
            ),
            isChecked: _isEachSubstepChecked[CherrypicksSubstep.verifyRelease]!,
            clickCallback: () {
              substepPressed(CherrypicksSubstep.verifyRelease);
            },
          ),
        CheckboxAsSubstep(
          substepName: CherrypicksSubsteps.substepTitles[CherrypicksSubstep.applyCherrypicks]!,
          subtitle: cherrypicksInConflict.isEmpty
              ? SelectableText('No ${repositoryName(widget.repository)} cherrypick conflicts, just check this substep.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText('Navigate to the ${repositoryName(widget.repository)} checkout directory '
                        'by pasting the code below to your terminal: '),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 5, 0, 10),
                      child:
                          SelectableText('cd ${statusState.conductor.rootDirectory.path}/flutter_conductor_checkouts/'
                              '${repositoryName(widget.repository)}'),
                    ),
                    SelectableText(
                        'At that location, apply the following ${repositoryName(widget.repository)} cherrypicks '
                        'that are in conflict by pasting the code below to your terminal and manually resolve any merge conflicts.'
                        ' Then commit the changes without pushing.'),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 5, 0, 10),
                      child: SelectableText(cherrypicksInConflict.toString()),
                    ),
                    const SelectableText('See more information about Flutter Cherrypick Process at: '),
                    const UrlButton(
                      textToDisplay: kReleaseDocumentationUrl,
                      urlOrUri: kReleaseDocumentationUrl,
                    ),
                  ],
                ),
          isChecked: _isEachSubstepChecked[CherrypicksSubstep.applyCherrypicks]!,
          clickCallback: () {
            substepPressed(CherrypicksSubstep.applyCherrypicks);
          },
        ),
        if (!_isEachSubstepChecked.containsValue(false))
          Padding(
            padding: const EdgeInsets.only(top: 30.0),
            child: ElevatedButton(
              key: Key('apply${repositoryName(widget.repository, true)}CherrypicksContinue'),
              onPressed: () {
                widget.nextStep();
              },
              child: const Text('Continue'),
            ),
          ),
      ],
    );
  }
}
