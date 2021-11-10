// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'common/checkbox_substep.dart';

enum EngineCherrypicksSubstep {
  substep1,
  substep2,
  substep3,
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

  static Map<EngineCherrypicksSubstep, String> substepTitles = <EngineCherrypicksSubstep, String>{
    EngineCherrypicksSubstep.substep1: 'Substep 1',
    EngineCherrypicksSubstep.substep2: 'Substep 2',
    EngineCherrypicksSubstep.substep3: 'Substep 3',
  };

  static Map<EngineCherrypicksSubstep, String> substepSubtitles = <EngineCherrypicksSubstep, String>{
    EngineCherrypicksSubstep.substep1: 'Substep subtitle 1',
    EngineCherrypicksSubstep.substep2: 'Substep subtitle 2',
    EngineCherrypicksSubstep.substep3: 'Substep subtitle 3',
  };
}

class ConductorSubstepsState extends State<EngineCherrypicksSubsteps> {
  Map<String, bool> _isEachSubstepChecked = <String, bool>{};

  @override
  void initState() {
    /// If [substep] in [_isEachSubstepChecked] is false, that [substep] is unchecked, otherwise, it is checked.
    ///
    /// All substeps are unchecked at the beginning.
    for (final String substep in EngineCherrypicksSubsteps.substepTitles.values) {
      _isEachSubstepChecked = <String, bool>{
        ..._isEachSubstepChecked,
        substep: false,
      };
    }
    super.initState();
  }

  /// Toggle the boolean value of [substepName] in [_isEachSubstepChecked].
  void substepPressed(String substepName) {
    setState(() {
      _isEachSubstepChecked[substepName] = !_isEachSubstepChecked[substepName]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        CheckboxAsSubstep(
          substepName: EngineCherrypicksSubsteps.substepTitles[EngineCherrypicksSubstep.substep1]!,
          subtitle: SelectableText(EngineCherrypicksSubsteps.substepSubtitles[EngineCherrypicksSubstep.substep1]!),
          isEachSubstepChecked: _isEachSubstepChecked,
          clickCallback: substepPressed,
        ),
        CheckboxAsSubstep(
          substepName: EngineCherrypicksSubsteps.substepTitles[EngineCherrypicksSubstep.substep2]!,
          subtitle: SelectableText(EngineCherrypicksSubsteps.substepSubtitles[EngineCherrypicksSubstep.substep1]!),
          isEachSubstepChecked: _isEachSubstepChecked,
          clickCallback: substepPressed,
        ),
        CheckboxAsSubstep(
          substepName: EngineCherrypicksSubsteps.substepTitles[EngineCherrypicksSubstep.substep3]!,
          subtitle: SelectableText(EngineCherrypicksSubsteps.substepSubtitles[EngineCherrypicksSubstep.substep1]!),
          isEachSubstepChecked: _isEachSubstepChecked,
          clickCallback: substepPressed,
        ),
        if (!_isEachSubstepChecked.containsValue(false))
          ElevatedButton(
            key: const Key('applyEngineCherrypicksContinue'),
            onPressed: () {
              widget.nextStep();
            },
            child: const Text('Continue'),
          ),
      ],
    );
  }
}
