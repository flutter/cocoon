// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/status_state.dart';
import 'common/checkbox_substep.dart';
import 'common/url_button.dart';

enum CodesignEngineSubstep {
  updateLicenseHash,
  preSubmitCI,
  postSubmitCI,
  codesign,
}

/// Group and display all substeps related to the 'Apply Engine Cherrypicks' step into a widget.
///
/// When all substeps are completed, [nextStep] can be executed to proceed to the next step.
class CodesignEngineSubsteps extends StatefulWidget {
  const CodesignEngineSubsteps({
    Key? key,
    required this.nextStep,
  }) : super(key: key);

  final VoidCallback nextStep;

  @override
  State<CodesignEngineSubsteps> createState() => ConductorSubstepsState();

  static const Map<CodesignEngineSubstep, String> substepTitles = <CodesignEngineSubstep, String>{
    CodesignEngineSubstep.updateLicenseHash: 'Update the license hash number',
    CodesignEngineSubstep.preSubmitCI: 'Validate pre-submit CI, have the engine PR reviewed, approved and merged',
    CodesignEngineSubstep.postSubmitCI: 'Validate post-submit CI',
    CodesignEngineSubstep.codesign: 'Codesign the engine binaries',
  };

  static const Map<CodesignEngineSubstep, String> substepSubtitles = <CodesignEngineSubstep, String>{
    CodesignEngineSubstep.updateLicenseHash:
        'There might be a license failure under the Linux Unopt test for the engine PR. '
            "Visit the test's stdout, and there should be instructions on how to update the license hash number"
            ' in the local checkout directory. After the update, please push the changes to the engine PR.\n\n'
            'Just check this substep if there is no Linux Unopt test failure.',
    CodesignEngineSubstep.preSubmitCI:
        'Make sure all tests on Github pass for the engine PR. Fix any test failures first. \n'
            'Get the engine PR reviewed, approved and merged.',
    CodesignEngineSubstep.postSubmitCI: 'Make sure all engine binaries post-submit CI tests pass here: ',
    CodesignEngineSubstep.codesign: 'An authorized person has to codesign the engine binaries.',
  };

  static const releaseChannelMissingErr = 'Error: Release Channel cannot be found';
}

class ConductorSubstepsState extends State<CodesignEngineSubsteps> {
  final Map<CodesignEngineSubstep, bool> _isEachSubstepChecked = <CodesignEngineSubstep, bool>{};

  @override
  void initState() {
    /// If [substep] is false, that [substep] is unchecked, otherwise, it is checked.
    ///
    /// All substeps are unchecked at the beginning.
    for (final CodesignEngineSubstep substep in CodesignEngineSubstep.values) {
      _isEachSubstepChecked[substep] = false;
    }
    super.initState();
  }

  /// Toggle the boolean value of [substepName].
  void substepPressed(CodesignEngineSubstep substep) {
    setState(() {
      _isEachSubstepChecked[substep] = !_isEachSubstepChecked[substep]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, Object>? releaseStatus = context.watch<StatusState>().releaseStatus;

    return Column(
      children: <Widget>[
        CheckboxAsSubstep(
          substepName: CodesignEngineSubsteps.substepTitles[CodesignEngineSubstep.updateLicenseHash]!,
          subtitle: SelectableText(CodesignEngineSubsteps.substepSubtitles[CodesignEngineSubstep.updateLicenseHash]!),
          isChecked: _isEachSubstepChecked[CodesignEngineSubstep.updateLicenseHash]!,
          clickCallback: () {
            substepPressed(CodesignEngineSubstep.updateLicenseHash);
          },
        ),
        CheckboxAsSubstep(
          substepName: CodesignEngineSubsteps.substepTitles[CodesignEngineSubstep.preSubmitCI]!,
          subtitle: SelectableText(CodesignEngineSubsteps.substepSubtitles[CodesignEngineSubstep.preSubmitCI]!),
          isChecked: _isEachSubstepChecked[CodesignEngineSubstep.preSubmitCI]!,
          clickCallback: () {
            substepPressed(CodesignEngineSubstep.preSubmitCI);
          },
        ),
        CheckboxAsSubstep(
          substepName: CodesignEngineSubsteps.substepTitles[CodesignEngineSubstep.postSubmitCI]!,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(CodesignEngineSubsteps.substepSubtitles[CodesignEngineSubstep.postSubmitCI]!),
              releaseStatus == null || releaseStatus['Release Channel'] == null
                  ? Text(
                      CodesignEngineSubsteps.releaseChannelMissingErr,
                      style: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.red),
                    )
                  : UrlButton(
                      textToDisplay: luciConsoleLink(releaseStatus['Release Channel'] as String, 'engine'),
                      urlOrUri: luciConsoleLink(releaseStatus['Release Channel'] as String, 'engine'),
                    ),
            ],
          ),
          isChecked: _isEachSubstepChecked[CodesignEngineSubstep.postSubmitCI]!,
          clickCallback: () {
            substepPressed(CodesignEngineSubstep.postSubmitCI);
          },
        ),
        CheckboxAsSubstep(
          substepName: CodesignEngineSubsteps.substepTitles[CodesignEngineSubstep.codesign]!,
          subtitle: SelectableText(CodesignEngineSubsteps.substepSubtitles[CodesignEngineSubstep.codesign]!),
          isChecked: _isEachSubstepChecked[CodesignEngineSubstep.codesign]!,
          clickCallback: () {
            substepPressed(CodesignEngineSubstep.codesign);
          },
        ),
        if (!_isEachSubstepChecked.containsValue(false))
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 25, 0, 0),
            child: ElevatedButton(
              key: const Key('CodesignEngineSubstepsContinue'),
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
