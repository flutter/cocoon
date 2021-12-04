// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/repositories_name.dart';
import '../models/conductor_status.dart';
import '../models/repositories.dart';
import '../services/conductor.dart';
import '../state/status_state.dart';
import 'common/checkbox_substep.dart';
import 'common/url_button.dart';

enum MergePrSubstep {
  openPr,
  updateLicenseHash,
  preSubmitCi,
  postSubmitCi,
  codesign,
}

/// Group and display all substeps related to merging the engine/framework PR.
///
/// When all substeps are completed, [nextStep] can be executed to proceed to the next step.
///
/// [repository] parameters makes it possible to toggle the widget to accommodate for an engine
/// PR or framework PR.
///
/// When an engine PR is required, every substep in [MergePrSubstep] are displayed.
///
/// When an engine PR is not required, only the [codesign] substep is displayed.
///
/// When a framework PR is required, every substep in [MergePrSubstep] except
/// [updateLicenseHash] and [codesign] are displayed.
///
/// When a framework PR is not required, no substep is displayed. User can directly click
/// on the continue button to proceed to the next step.
///
/// The widget leverages [requiresEnginePR] or [requiresFrameworkPR] from the core to
/// determine if a PR is needed.
///
/// If a PR is needed, [getNewPrLink] is called to retrieve the PR creation link.
class MergePrSubsteps extends StatefulWidget {
  const MergePrSubsteps({
    Key? key,
    required this.nextStep,
    required this.repository,
  }) : super(key: key);

  final VoidCallback nextStep;
  final Repositories repository;

  @override
  State<MergePrSubsteps> createState() => MergePrSubstepsState();

  static const Map<MergePrSubstep, String> substepTitles = <MergePrSubstep, String>{
    MergePrSubstep.openPr: 'Open a pull request',
    MergePrSubstep.updateLicenseHash: 'Update the license hash number',
    MergePrSubstep.preSubmitCi: 'Validate pre-submit CI, have the PR reviewed, approved and merged',
    MergePrSubstep.postSubmitCi: 'Validate post-submit CI',
    MergePrSubstep.codesign: 'Codesign the engine binaries',
  };

  static const Map<MergePrSubstep, String> substepSubtitles = <MergePrSubstep, String>{
    MergePrSubstep.openPr: 'You must now open a pull request by clicking on the following link: ',
    MergePrSubstep.updateLicenseHash: 'There might be a license failure under the Linux Unopt test for this PR. '
        "Visit the test's stdout, and there should be instructions on how to update the license hash number"
        ' in the local checkout directory. After the update, please push the changes to the feature branch on your mirror.\n\n'
        'This box can be checked if Linux Unopt passes the pre-submit CI.',
    MergePrSubstep.preSubmitCi:
        'Make sure all pre-submit tests on Github pass for this PR. Fix any test failures first. \n'
            'Get the PR reviewed, approved and merged.',
    MergePrSubstep.postSubmitCi: 'Make sure all post-submit CI tests pass here: ',
    MergePrSubstep.codesign: 'An authorized person has to codesign the engine binaries.',
  };

  static const String releaseChannelInvalidErr = 'Error: Release Channel is invalid';

  static const String noPrMsg = 'Since there are no code changes in this release, no PR is necessary.';
}

class MergePrSubstepsState extends State<MergePrSubsteps> {
  final Map<MergePrSubstep, bool> _isEachSubstepChecked = <MergePrSubstep, bool>{};

  @override
  void initState() {
    // If [substep] is false, that [substep] is unchecked, otherwise, it is checked.
    // All substeps are unchecked at the beginning.
    for (final MergePrSubstep substep in MergePrSubstep.values) {
      _isEachSubstepChecked[substep] = false;
    }
    super.initState();
  }

  /// Toggle the boolean value of [substepName].
  void substepPressed(MergePrSubstep substep) {
    setState(() {
      _isEachSubstepChecked[substep] = !_isEachSubstepChecked[substep]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Map<ConductorStatusEntry, Object>? releaseStatus = context.watch<StatusState>().releaseStatus;
    final ConductorService conductor = context.watch<StatusState>().conductor;
    late bool isPrRequired;
    late String newPrLink;

    if (releaseStatus == null) {
      isPrRequired = true;
      newPrLink = 'Could not create a PR pink.';
    } else {
      isPrRequired = widget.repository == Repositories.engine
          ? requiresEnginePR(conductor.state!)
          : requiresFrameworkPR(conductor.state!);

      newPrLink = getNewPrLink(
        userName: githubAccount(widget.repository == Repositories.engine
            ? conductor.state!.engine.mirror.url
            : conductor.state!.framework.mirror.url),
        repoName: repositoryNameAlt(widget.repository),
        state: conductor.state!,
      );
    }

    // Construct a list to keep track of the substeps required based on if a PR is needed
    // and the type of repository.
    List<MergePrSubstep> substepsRequired = <MergePrSubstep>[];
    if (isPrRequired) {
      substepsRequired = [
        MergePrSubstep.openPr,
        if (widget.repository == Repositories.engine) MergePrSubstep.updateLicenseHash,
        MergePrSubstep.preSubmitCi,
        MergePrSubstep.postSubmitCi
      ];
    }
    if (widget.repository == Repositories.engine) {
      substepsRequired.add(MergePrSubstep.codesign);
    }

    // Filter a map that tracks the check status of only the required substeps.
    Map<MergePrSubstep, bool> isRequiredSubstepChecked = Map.from(_isEachSubstepChecked)
      ..removeWhere((key, value) => !substepsRequired.contains(key));

    // The values of the map are widgets that each substep renders
    // as the subtitle of a CheckboxAsSubstep widget.
    final Map<MergePrSubstep, Widget> substepsContent = <MergePrSubstep, Widget>{
      MergePrSubstep.openPr: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(MergePrSubsteps.substepSubtitles[MergePrSubstep.openPr]!),
          const SizedBox(height: 10.0),
          UrlButton(
            textToDisplay: newPrLink,
            urlOrUri: newPrLink,
          ),
        ],
      ),
      MergePrSubstep.updateLicenseHash:
          SelectableText(MergePrSubsteps.substepSubtitles[MergePrSubstep.updateLicenseHash]!),
      MergePrSubstep.preSubmitCi: SelectableText(MergePrSubsteps.substepSubtitles[MergePrSubstep.preSubmitCi]!),
      MergePrSubstep.postSubmitCi: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(MergePrSubsteps.substepSubtitles[MergePrSubstep.postSubmitCi]!),
          releaseStatus == null || !kBaseReleaseChannels.contains(releaseStatus[ConductorStatusEntry.releaseChannel])
              ? Text(
                  MergePrSubsteps.releaseChannelInvalidErr,
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.red),
                )
              : UrlButton(
                  textToDisplay: luciConsoleLink(
                    releaseStatus[ConductorStatusEntry.releaseChannel] as String,
                    repositoryNameAlt(widget.repository),
                  ),
                  urlOrUri: luciConsoleLink(
                    releaseStatus[ConductorStatusEntry.releaseChannel] as String,
                    repositoryNameAlt(widget.repository),
                  ),
                ),
        ],
      ),
      MergePrSubstep.codesign: SelectableText(MergePrSubsteps.substepSubtitles[MergePrSubstep.codesign]!),
    };

    return Column(
      children: <Widget>[
        if (!isPrRequired)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(MergePrSubsteps.noPrMsg, style: Theme.of(context).textTheme.subtitle1),
          ),
        // Render only required substeps.
        for (MergePrSubstep substep in substepsRequired)
          CheckboxAsSubstep(
            substepName: MergePrSubsteps.substepTitles[substep]!,
            subtitle: substepsContent[substep],
            isChecked: _isEachSubstepChecked[substep]!,
            clickCallback: () {
              substepPressed(substep);
            },
          ),
        // Only if all required substeps are checked, render the continue button.
        if (!isRequiredSubstepChecked.containsValue(false))
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 25, 0, 0),
            child: ElevatedButton(
              key: Key('merge${repositoryName(widget.repository, true)}CherrypicksSubstepsContinue'),
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
