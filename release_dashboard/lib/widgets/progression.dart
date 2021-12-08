// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../models/repositories.dart';
import 'cherrypicks_substeps.dart';
import 'conductor_status.dart';
import 'create_release_substeps.dart';
import 'merge_pr_substeps.dart';
import 'publish_tag_substeps.dart';
import 'push_release_substep.dart';
import 'release_completed.dart';

/// Displays the progression and each step of the release from the conductor.
///
// TODO(Yugue): Add documentation to explain
// each step of the release, https://github.com/flutter/flutter/issues/90981.
class MainProgression extends StatefulWidget {
  const MainProgression({
    Key? key,
    this.previousCompletedStep,
  }) : super(key: key);

  final int? previousCompletedStep;

  @override
  State<MainProgression> createState() => MainProgressionState();

  static const List<String> _stepTitles = <String>[
    'Initialize a New Flutter Release',
    'Apply Engine Cherrypicks',
    'Codesign Engine Binaries',
    'Apply Framework Cherrypicks',
    'Merge the Framework PR',
    'Publish the Version Tag',
    'Push and Verify the Release',
    'Release is Completed',
  ];
}

class MainProgressionState extends State<MainProgression> {
  int _completedStep = 0;

  @override
  void initState() {
    // Enables the stepper to resume from the step it was left on previously.
    if (widget.previousCompletedStep != null) {
      _completedStep = widget.previousCompletedStep!;
    }
    super.initState();
  }

  /// Move forward the stepper to the next step of the release.
  void nextStep() {
    if (_completedStep < MainProgression._stepTitles.length - 1) {
      setState(() {
        _completedStep += 1;
      });
    }
  }

  /// Change each step's state according to the current completed step.
  StepState handleStepState(int index) {
    if (_completedStep > index) {
      return StepState.complete;
    } else if (_completedStep == index) {
      return StepState.indexed;
    } else {
      return StepState.disabled;
    }
  }

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Scrollbar(
        isAlwaysShown: true,
        controller: _scrollController,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          physics: const ClampingScrollPhysics(),
          children: <Widget>[
            const ConductorStatus(),
            const SizedBox(height: 20.0),
            // TODO(Yugue):  render stepper content widget only if the release is at that step,
            // https://github.com/flutter/flutter/issues/94755.
            Stepper(
              controlsBuilder: (BuildContext context, ControlsDetails details) => Row(),
              physics: const ScrollPhysics(),
              currentStep: _completedStep,
              onStepContinue: nextStep,
              steps: <Step>[
                Step(
                  title: Text(MainProgression._stepTitles[0]),
                  content: CreateReleaseSubsteps(nextStep: nextStep),
                  isActive: _completedStep >= 0,
                  state: handleStepState(0),
                ),
                Step(
                  title: Text(MainProgression._stepTitles[1]),
                  content: CherrypicksSubsteps(nextStep: nextStep, repository: Repositories.engine),
                  isActive: _completedStep >= 1,
                  state: handleStepState(1),
                ),
                Step(
                  title: Text(MainProgression._stepTitles[2]),
                  content: MergePrSubsteps(
                    nextStep: nextStep,
                    repository: Repositories.engine,
                  ),
                  isActive: _completedStep >= 2,
                  state: handleStepState(2),
                ),
                Step(
                  title: Text(MainProgression._stepTitles[3]),
                  content: CherrypicksSubsteps(nextStep: nextStep, repository: Repositories.framework),
                  isActive: _completedStep >= 3,
                  state: handleStepState(3),
                ),
                Step(
                  title: Text(MainProgression._stepTitles[4]),
                  content: MergePrSubsteps(
                    nextStep: nextStep,
                    repository: Repositories.framework,
                  ),
                  isActive: _completedStep >= 4,
                  state: handleStepState(4),
                ),
                Step(
                  title: Text(MainProgression._stepTitles[5]),
                  content: PublishTagSubsteps(nextStep: nextStep),
                  isActive: _completedStep >= 5,
                  state: handleStepState(5),
                ),
                Step(
                  title: Text(MainProgression._stepTitles[6]),
                  content: PushReleaseSubsteps(nextStep: nextStep),
                  isActive: true,
                  state: handleStepState(6),
                ),
                Step(
                  title: Text(MainProgression._stepTitles[7]),
                  content: const ReleaseCompleted(),
                  isActive: true,
                  state: handleStepState(7),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
