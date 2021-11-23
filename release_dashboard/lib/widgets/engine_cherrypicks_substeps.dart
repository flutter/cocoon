// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cherrypick.dart';
import '../models/conductor_status.dart';
import '../state/status_state.dart';
import 'common/checkbox_substep.dart';
import 'common/url_button.dart';

enum EngineCherrypicksSubstep {
  verifyRelease,
  applyCherrypicks,
}

/// Group and display all substeps related to the 'Apply Engine Cherrypicks' step into a widget.
///
/// When all substeps are completed, [nextStep] can be executed to proceed to the next step.
class EngineCherrypicksSubsteps extends StatefulWidget {
  const EngineCherrypicksSubsteps({
    Key? key,
    required this.nextStep,
  }) : super(key: key);

  final VoidCallback nextStep;

  @override
  State<EngineCherrypicksSubsteps> createState() => ConductorSubstepsState();

  static const Map<EngineCherrypicksSubstep, String> substepTitles = <EngineCherrypicksSubstep, String>{
    EngineCherrypicksSubstep.verifyRelease: 'Verify the Release Number',
    EngineCherrypicksSubstep.applyCherrypicks: 'Apply cherrypicks and resolve conflicts',
  };

  static Map<pb.CherrypickState, String> cherrypickStates = <pb.CherrypickState, String>{
    pb.CherrypickState.PENDING: 'PENDING',
    pb.CherrypickState.PENDING_WITH_CONFLICT: 'PENDING_WITH_CONFLICT',
    pb.CherrypickState.COMPLETED: 'COMPLETED',
    pb.CherrypickState.ABANDONED: 'ABANDONED',
  };

  static const String kReleaseSDKURL = 'https://flutter.dev/docs/development/tools/sdk/releases';
}

class ConductorSubstepsState extends State<EngineCherrypicksSubsteps> {
  final Map<EngineCherrypicksSubstep, bool> _isEachSubstepChecked = <EngineCherrypicksSubstep, bool>{};

  @override
  void initState() {
    /// If [substep] in [_isEachSubstepChecked] is false, that [substep] is unchecked, otherwise, it is checked.
    ///
    /// All substeps are unchecked at the beginning.
    for (final EngineCherrypicksSubstep substep in EngineCherrypicksSubstep.values) {
      _isEachSubstepChecked[substep] = false;
    }
    super.initState();
  }

  /// Toggle the boolean value of [substepName] in [_isEachSubstepChecked].
  void substepPressed(EngineCherrypicksSubstep substep) {
    setState(() {
      _isEachSubstepChecked[substep] = !_isEachSubstepChecked[substep]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final StatusState statusState = context.watch<StatusState>();
    final StringBuffer engineCherrypicksInConflict = StringBuffer();

    if (statusState.releaseStatus != null &&
        statusState.releaseStatus?[ConductorStatusEntry.engineCherrypicks] != null) {
      for (Map<Cherrypick, String> engineCherrypick
          in statusState.releaseStatus?[ConductorStatusEntry.engineCherrypicks] as List<Map<Cherrypick, String>>) {
        if (engineCherrypick[Cherrypick.state] ==
            EngineCherrypicksSubsteps.cherrypickStates[pb.CherrypickState.PENDING_WITH_CONFLICT]) {
          engineCherrypicksInConflict.writeln('git cherry-pick ${engineCherrypick[Cherrypick.trunkRevision]!}');
        }
      }
    }

    return Column(
      children: <Widget>[
        CheckboxAsSubstep(
          substepName: EngineCherrypicksSubsteps.substepTitles[EngineCherrypicksSubstep.verifyRelease]!,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                  'Verify if the release number: ${statusState.releaseStatus?[ConductorStatusEntry.releaseVersion]}'
                  ' is correct based on existing published releases here: '),
              const UrlButton(
                textToDisplay: EngineCherrypicksSubsteps.kReleaseSDKURL,
                urlOrUri: EngineCherrypicksSubsteps.kReleaseSDKURL,
              ),
            ],
          ),
          isChecked: _isEachSubstepChecked[EngineCherrypicksSubstep.verifyRelease]!,
          clickCallback: () {
            substepPressed(EngineCherrypicksSubstep.verifyRelease);
          },
        ),
        CheckboxAsSubstep(
          substepName: EngineCherrypicksSubsteps.substepTitles[EngineCherrypicksSubstep.applyCherrypicks]!,
          subtitle: engineCherrypicksInConflict.isEmpty
              ? const SelectableText('No cherrypick conflicts, just check this substep.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SelectableText(
                        'Navigate to the engine checkout by pasting the code below to your terminal: '),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 5, 0, 10),
                      child: SelectableText(
                          'cd ${statusState.conductor.rootDirectory.path}/flutter_conductor_checkouts/engine'),
                    ),
                    const SelectableText(
                        "At that location, apply the following engine cherrypicks that are in conflict "
                        "by pasting the code below to your terminal in order and manually resolve any merge conflicts."),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 5, 0, 10),
                      child: SelectableText(engineCherrypicksInConflict.toString()),
                    ),
                    const SelectableText('See more information about Flutter Cherrypick Process at: '),
                    const UrlButton(
                      textToDisplay: kReleaseDocumentationUrl,
                      urlOrUri: kReleaseDocumentationUrl,
                    ),
                  ],
                ),
          isChecked: _isEachSubstepChecked[EngineCherrypicksSubstep.applyCherrypicks]!,
          clickCallback: () {
            substepPressed(EngineCherrypicksSubstep.applyCherrypicks);
          },
        ),
        if (!_isEachSubstepChecked.containsValue(false))
          Padding(
            padding: const EdgeInsets.only(top: 30.0),
            child: ElevatedButton(
              key: const Key('applyEngineCherrypicksContinue'),
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
