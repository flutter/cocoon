// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../state/status_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:conductor_core/proto.dart' as pb;

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
    EngineCherrypicksSubstep.applyCherrypicks: 'Apply cherrypicks that are in conflict',
  };

  static Map<pb.CherrypickState, String> cherrypickStates = <pb.CherrypickState, String>{
    pb.CherrypickState.PENDING: 'PENDING',
    pb.CherrypickState.PENDING_WITH_CONFLICT: 'PENDING_WITH_CONFLICT',
    pb.CherrypickState.COMPLETED: 'COMPLETED',
    pb.CherrypickState.ABANDONED: 'ABANDONED',
  };

  static const String releaseSDKURL = 'https://flutter.dev/docs/development/tools/sdk/releases';
  static const String cherrypickHelpURL = 'https://github.com/flutter/flutter/wiki/Flutter-Cherrypick-Process';
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
    List<String> engineCherrypicksInConflict = <String>[];
    if (context.watch<StatusState>().releaseStatus != null &&
        context.watch<StatusState>().releaseStatus?['Engine Cherrypicks'] != null) {
      for (Map<String, String> engineCherrypick
          in context.watch<StatusState>().releaseStatus?['Engine Cherrypicks'] as List<Map<String, String>>) {
        if (engineCherrypick['state'] ==
            EngineCherrypicksSubsteps.cherrypickStates[pb.CherrypickState.PENDING_WITH_CONFLICT]) {
          engineCherrypicksInConflict.add(engineCherrypick['trunkRevision']!);
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
                  'Verify if the release number: ${context.watch<StatusState>().releaseStatus?['Release Version']}'
                  ' is correct based on existing published releases here: '),
              const UrlButton(
                textToDisplay: EngineCherrypicksSubsteps.releaseSDKURL,
                urlOrUri: EngineCherrypicksSubsteps.releaseSDKURL,
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
                        "You must manually apply the following engine cherrypicks that are in conflict "
                        "by doing 'git cherrypick [hash]' with the following hashes: "),
                    SelectableText('${engineCherrypicksInConflict.join('\n')}\n'),
                    const SelectableText(
                        'to the engine checkout at the following location and resolve any conflicts: '),
                    UrlButton(
                      textToDisplay:
                          '${context.watch<StatusState>().conductor.rootDirectory.path}/flutter_conductor_checkouts/engine',
                      urlOrUri:
                          '${context.watch<StatusState>().conductor.rootDirectory.path}/flutter_conductor_checkouts/engine',
                    ),
                    const SelectableText('See more information at: '),
                    const UrlButton(
                      textToDisplay: EngineCherrypicksSubsteps.cherrypickHelpURL,
                      urlOrUri: EngineCherrypicksSubsteps.cherrypickHelpURL,
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
