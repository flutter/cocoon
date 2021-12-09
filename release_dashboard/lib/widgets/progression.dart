// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/proto.dart' as pb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/conductor_status.dart';
import '../models/repositories.dart';
import '../state/status_state.dart';
import 'cherrypicks_substeps.dart';
import 'conductor_status.dart';
import 'create_release_substeps.dart';
import 'merge_pr_substeps.dart';
import 'publish_release_substeps.dart';
import 'release_completed.dart';
import 'verify_release_substep.dart';

/// First step of the release.
///
/// [ReleasePhase] from conductor core does not contain initialize release as a phase.
/// But the release dashboard's first step is to initialize a release.
/// This enum fills this missing step.
// TODO(Yugue): [condcutor] Add InitializeRelease as the first phase to ReleasePhase,
// https://github.com/flutter/flutter/issues/94765.
enum ReleaseSteps {
  initializeRelease,
}

/// Displays the progression and each step of the release.
///
/// The steps in the release dashboard correspond to the release phases in the conductor core.
///
/// Below are high-level explanations of each step:
///
/// 1st step: Initialize a release with parameters such as the candidate branch,
/// release channel, etc.
///
/// 2nd step: Apply engine cherrypicks if there are any, and resolve any conflict manually.
///
/// 3rd step: Merge the engine PR if required, and codesign the engine binaries.
///
/// 4th step: Apply framework cherrypicks if there are any, and resolve any conflict manually.
///
/// 5th step: Merge the framework PR if required, and verify the release tag creation.
///
/// 6th step: Publish the release to the release channel branch.
///
/// 7th step: Verify the release packaging builds.
///
/// 8th step: Release is done.
class MainProgression extends StatefulWidget {
  const MainProgression({
    Key? key,
  }) : super(key: key);

  @override
  State<MainProgression> createState() => MainProgressionState();

  static const Map<Object, String> stepTitles = <Object, String>{
    ReleaseSteps.initializeRelease: 'Initialize a New Flutter Release',
    pb.ReleasePhase.APPLY_ENGINE_CHERRYPICKS: 'Apply Engine Cherrypicks',
    pb.ReleasePhase.CODESIGN_ENGINE_BINARIES: 'Codesign Engine Binaries',
    pb.ReleasePhase.APPLY_FRAMEWORK_CHERRYPICKS: 'Apply Framework Cherrypicks',
    pb.ReleasePhase.PUBLISH_VERSION: 'Merge the Framework PR',
    pb.ReleasePhase.PUBLISH_CHANNEL: 'Publish the Release',
    pb.ReleasePhase.VERIFY_RELEASE: 'Verify the Release',
    pb.ReleasePhase.RELEASE_COMPLETED: 'Release is Completed',
  };

  /// The order of the map's entry determines the rendering order of each step.
  /// Not the step position.
  ///
  /// The step position values represent which step they are. For example, [initializeRelease]'s value
  /// is 0 and is the 1st release step, [APPLY_FRAMEWORK_CHERRYPICKS]'s value is 3 and is the 4th step.
  static Map<Object, int> stepPosition = <Object, int>{
    ReleaseSteps.initializeRelease: 0,
    pb.ReleasePhase.APPLY_ENGINE_CHERRYPICKS: pb.ReleasePhase.APPLY_ENGINE_CHERRYPICKS.value + 1,
    pb.ReleasePhase.CODESIGN_ENGINE_BINARIES: pb.ReleasePhase.CODESIGN_ENGINE_BINARIES.value + 1,
    pb.ReleasePhase.APPLY_FRAMEWORK_CHERRYPICKS: pb.ReleasePhase.APPLY_FRAMEWORK_CHERRYPICKS.value + 1,
    pb.ReleasePhase.PUBLISH_VERSION: pb.ReleasePhase.PUBLISH_VERSION.value + 1,
    pb.ReleasePhase.PUBLISH_CHANNEL: pb.ReleasePhase.PUBLISH_CHANNEL.value + 1,
    pb.ReleasePhase.VERIFY_RELEASE: pb.ReleasePhase.VERIFY_RELEASE.value + 1,
    pb.ReleasePhase.RELEASE_COMPLETED: pb.ReleasePhase.RELEASE_COMPLETED.value + 1,
  };
}

class MainProgressionState extends State<MainProgression> {
  final ScrollController _scrollController = ScrollController();

  /// Change each step's state according to the current completed step.
  StepState handleStepState(int currentStep, int index) {
    if (currentStep > index) {
      return StepState.complete;
    } else if (currentStep == index) {
      return StepState.indexed;
    } else {
      return StepState.disabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<ConductorStatusEntry, Object>? releaseStatus = context.watch<StatusState>().releaseStatus;

    // If there is no test state, start from the first step: creating a release.
    final int currentStep =
        releaseStatus == null ? 0 : MainProgression.stepPosition[releaseStatus[ConductorStatusEntry.currentPhase]]!;

    // The values of the map are widgets that each [Step] renders as its content.
    const Map<Object, Widget> stepWidgetMapping = <Object, Widget>{
      ReleaseSteps.initializeRelease: CreateReleaseSubsteps(),
      pb.ReleasePhase.APPLY_ENGINE_CHERRYPICKS: CherrypicksSubsteps(repository: Repositories.engine),
      pb.ReleasePhase.CODESIGN_ENGINE_BINARIES: MergePrSubsteps(repository: Repositories.engine),
      pb.ReleasePhase.APPLY_FRAMEWORK_CHERRYPICKS: CherrypicksSubsteps(repository: Repositories.framework),
      pb.ReleasePhase.PUBLISH_VERSION: MergePrSubsteps(repository: Repositories.framework),
      pb.ReleasePhase.PUBLISH_CHANNEL: PublishReleaseSubsteps(),
      pb.ReleasePhase.VERIFY_RELEASE: VerifyReleaseSubsteps(),
      pb.ReleasePhase.RELEASE_COMPLETED: ReleaseCompleted(),
    };

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
            Stepper(
              controlsBuilder: (BuildContext context, ControlsDetails details) => Row(),
              physics: const ScrollPhysics(),
              currentStep: currentStep,
              steps: <Step>[
                for (MapEntry step in MainProgression.stepPosition.entries)
                  Step(
                    title: Text(MainProgression.stepTitles[step.key]!),
                    // Only renders the current step's content.
                    content: currentStep == step.value ? stepWidgetMapping[step.key]! : Container(),
                    // All previously completed steps and the current steps are active.
                    isActive: currentStep >= step.value,
                    state: handleStepState(currentStep, step.value),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
