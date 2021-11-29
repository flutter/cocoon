// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/conductor_status.dart';
import '../state/status_state.dart';
import 'common/checkbox_substep.dart';
import 'common/url_button.dart';

enum PushReleaseSubstep {
  pushRelease,
  verifyRelease,
}

/// Group and display all substeps of the push release step.
///
/// This is the last step of the release.
class PushReleaseSubsteps extends StatefulWidget {
  const PushReleaseSubsteps({
    Key? key,
    required this.nextStep,
  }) : super(key: key);

  final VoidCallback nextStep;

  @override
  State<PushReleaseSubsteps> createState() => PushReleaseSubstepsState();

  static const Map<PushReleaseSubstep, String> substepTitles = <PushReleaseSubstep, String>{
    PushReleaseSubstep.pushRelease: 'Push to the release channel branch',
    PushReleaseSubstep.verifyRelease: 'Verify the release',
  };
  static const Map<PushReleaseSubstep, String> substepSubtitles = <PushReleaseSubstep, String>{
    PushReleaseSubstep.pushRelease: 'A special access is needed to push to the',
    PushReleaseSubstep.verifyRelease: 'After the push, please make sure the release passes all packaging builds here: ',
  };
}

class PushReleaseSubstepsState extends State<PushReleaseSubsteps> {
  final Map<PushReleaseSubstep, bool> _isEachSubstepChecked = <PushReleaseSubstep, bool>{};

  @override
  void initState() {
    /// If [substep] is false, that substep is unchecked, otherwise, it is checked.
    ///
    /// All substeps are unchecked at the beginning.
    for (final PushReleaseSubstep substep in PushReleaseSubstep.values) {
      _isEachSubstepChecked[substep] = false;
    }
    super.initState();
  }

  /// Toggle the boolean value [substepName].
  void substepPressed(PushReleaseSubstep substep) {
    setState(() {
      _isEachSubstepChecked[substep] = !_isEachSubstepChecked[substep]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<ConductorStatusEntry, Object>? releaseStatus = context.watch<StatusState>().releaseStatus;
    final String postMonitorLuci = luciConsoleLink(
      releaseStatus?[ConductorStatusEntry.releaseChannel] as String? ?? 'master',
      'packaging',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        CheckboxAsSubstep(
          substepName: PushReleaseSubsteps.substepTitles[PushReleaseSubstep.pushRelease]!,
          subtitle: SelectableText('${PushReleaseSubsteps.substepSubtitles[PushReleaseSubstep.pushRelease]!} '
              '${releaseStatus?[ConductorStatusEntry.releaseChannel]} branch directly. '
              'Please request for the authorized access, and push the release to the channel.'),
          isChecked: _isEachSubstepChecked[PushReleaseSubstep.pushRelease]!,
          clickCallback: () {
            substepPressed(PushReleaseSubstep.pushRelease);
          },
        ),
        CheckboxAsSubstep(
          substepName: PushReleaseSubsteps.substepTitles[PushReleaseSubstep.verifyRelease]!,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(PushReleaseSubsteps.substepSubtitles[PushReleaseSubstep.verifyRelease]!),
              UrlButton(textToDisplay: postMonitorLuci, urlOrUri: postMonitorLuci),
            ],
          ),
          isChecked: _isEachSubstepChecked[PushReleaseSubstep.verifyRelease]!,
          clickCallback: () {
            substepPressed(PushReleaseSubstep.verifyRelease);
          },
        ),
        if (!_isEachSubstepChecked.containsValue(false))
          Padding(
            padding: const EdgeInsets.only(top: 30.0),
            child: ElevatedButton(
              key: const Key('pushReleaseContinue'),
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
