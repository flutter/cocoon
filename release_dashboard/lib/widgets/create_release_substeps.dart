// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../logic/git.dart';
import 'common/tooltip.dart';

enum CreateReleaseSubstep {
  candidateBranch,
  releaseChannel,
  frameworkMirror,
  engineMirror,
  engineCherrypicks,
  frameworkCherrypicks,
  dartRevision,
  increment,
}

/// Displays all substeps related to the 1st step.
///
/// Uses input fields and dropdowns to capture all the parameters of the conductor start command.
class CreateReleaseSubsteps extends StatefulWidget {
  const CreateReleaseSubsteps({
    Key? key,
    required this.nextStep,
  }) : super(key: key);

  final VoidCallback nextStep;

  @override
  State<CreateReleaseSubsteps> createState() => CreateReleaseSubstepsState();

  static const Map<CreateReleaseSubstep, String> substepTitles = <CreateReleaseSubstep, String>{
    CreateReleaseSubstep.candidateBranch: 'Candidate Branch',
    CreateReleaseSubstep.releaseChannel: 'Release Channel',
    CreateReleaseSubstep.frameworkMirror: 'Framework Mirror',
    CreateReleaseSubstep.engineMirror: 'Engine Mirror',
    CreateReleaseSubstep.engineCherrypicks: 'Engine Cherrypicks (if necessary)',
    CreateReleaseSubstep.frameworkCherrypicks: 'Framework Cherrypicks (if necessary)',
    CreateReleaseSubstep.dartRevision: 'Dart Revision (if necessary)',
    CreateReleaseSubstep.increment: 'Increment',
  };

  static const List<String> releaseChannels = <String>['dev', 'beta', 'stable'];
  static const List<String> releaseIncrements = <String>['y', 'z', 'm', 'n'];
}

class CreateReleaseSubstepsState extends State<CreateReleaseSubsteps> {
  /// Initialize a public state so it could be accessed in the test file.
  @visibleForTesting
  late Map<String, String?> releaseData = <String, String?>{};

  /// When [substep] in [isEachInputValid] is true, [substep] is valid. Otherwise, it is invalid.
  @visibleForTesting
  Map<String, bool> isEachInputValid = <String, bool>{};

  @override
  void initState() {
    List<String> kOptionalInput = <String>[
      CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.engineCherrypicks]!,
      CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.frameworkCherrypicks]!,
      CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.dartRevision]!,
    ];
    // engine cherrypicks, framework cherrypicks and dart revision are optional and valid with empty input at the beginning
    for (final String substep in CreateReleaseSubsteps.substepTitles.values) {
      isEachInputValid = <String, bool>{
        ...isEachInputValid,
        substep: kOptionalInput.contains(substep),
      };
    }
    super.initState();
  }

  /// Updates the corresponding [field] in [releaseData] with [data].
  void setReleaseData(String field, String data) {
    setState(() {
      releaseData = <String, String?>{
        ...releaseData,
        field: data,
      };
    });
  }

  /// Modifies [name] in [isEachInputValid] with [isValid].
  void changeIsEachInputValid(String name, bool isValid) {
    setState(() {
      isEachInputValid = <String, bool>{
        ...isEachInputValid,
        name: isValid,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final GitValidation candidateBranch = CandidateBranch();
    final GitValidation gitRemote = GitRemote();
    final GitValidation multiGitHash = MultiGitHash();
    final GitValidation gitHash = GitHash();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InputAsSubstep(
          substepName: CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.candidateBranch]!,
          setReleaseData: setReleaseData,
          hintText: 'The candidate branch the release will be based on.',
          changeIsInputValid: changeIsEachInputValid,
          validationClass: candidateBranch,
        ),
        CheckboxListTileDropdown(
          substepName: CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.releaseChannel]!,
          releaseData: releaseData,
          setReleaseData: setReleaseData,
          options: CreateReleaseSubsteps.releaseChannels,
          changeIsDropdownValid: changeIsEachInputValid,
        ),
        InputAsSubstep(
          substepName: CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.frameworkMirror]!,
          setReleaseData: setReleaseData,
          hintText: "Git remote of the Conductor user's Framework repository mirror.",
          changeIsInputValid: changeIsEachInputValid,
          validationClass: gitRemote,
        ),
        InputAsSubstep(
          substepName: CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.engineMirror]!,
          setReleaseData: setReleaseData,
          hintText: "Git remote of the Conductor user's Engine repository mirror.",
          changeIsInputValid: changeIsEachInputValid,
          validationClass: gitRemote,
        ),
        InputAsSubstep(
          substepName: CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.engineCherrypicks]!,
          setReleaseData: setReleaseData,
          hintText: 'Engine cherrypick hashes to be applied. Multiple hashes delimited by a comma.',
          changeIsInputValid: changeIsEachInputValid,
          validationClass: multiGitHash,
        ),
        InputAsSubstep(
          substepName: CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.frameworkCherrypicks]!,
          setReleaseData: setReleaseData,
          hintText: 'Framework cherrypick hashes to be applied. Multiple hashes delimited by a comma.',
          changeIsInputValid: changeIsEachInputValid,
          validationClass: multiGitHash,
        ),
        InputAsSubstep(
          substepName: CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.dartRevision]!,
          setReleaseData: setReleaseData,
          hintText: 'New Dart revision to cherrypick.',
          changeIsInputValid: changeIsEachInputValid,
          validationClass: gitHash,
        ),
        CheckboxListTileDropdown(
          substepName: CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.increment]!,
          releaseData: releaseData,
          setReleaseData: setReleaseData,
          options: CreateReleaseSubsteps.releaseIncrements,
          changeIsDropdownValid: changeIsEachInputValid,
        ),
        const SizedBox(height: 20.0),
        Center(
          child: ElevatedButton(
            key: const Key('step1continue'),
            onPressed: isEachInputValid.containsValue(false) ? null : widget.nextStep,
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }
}

typedef SetReleaseData = void Function(String name, String data);
typedef ChangeIsEachInputValid = void Function(String name, bool isValid);

/// Captures the input values and updates the corresponding field in [releaseData].
class InputAsSubstep extends StatelessWidget {
  const InputAsSubstep({
    Key? key,
    required this.substepName,
    required this.setReleaseData,
    this.hintText,
    required this.changeIsInputValid,
    required this.validationClass,
  }) : super(key: key);

  final String substepName;
  final SetReleaseData setReleaseData;
  final String? hintText;
  final ChangeIsEachInputValid changeIsInputValid;
  final GitValidation validationClass;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: Key(substepName),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: substepName,
        hintText: hintText,
      ),
      onChanged: (String? data) {
        setReleaseData(substepName, validationClass.sanitize(data));
        if (!validationClass.isValid(data)) {
          changeIsInputValid(substepName, false);
        } else {
          changeIsInputValid(substepName, true);
        }
      },
      validator: (String? value) {
        if (!validationClass.isValid(value)) {
          return validationClass.errorMsg;
        } else {
          return null;
        }
      },
    );
  }
}

/// Captures the chosen option and updates the corresponding field in [releaseData].
class CheckboxListTileDropdown extends StatelessWidget {
  const CheckboxListTileDropdown({
    Key? key,
    required this.substepName,
    required this.releaseData,
    required this.setReleaseData,
    required this.options,
    required this.changeIsDropdownValid,
  }) : super(key: key);

  final String substepName;
  final Map<String, String?> releaseData;
  final SetReleaseData setReleaseData;
  final List<String> options;
  final ChangeIsEachInputValid changeIsDropdownValid;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          substepName,
          style: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.grey[700]),
        ),
        // Only add a tooltip for the increment dropdown
        if (substepName == CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.increment]!)
          const Padding(
            padding: EdgeInsets.fromLTRB(10.0, 0, 0, 0),
            child: InfoTooltip(
              tooltipName: 'ReleaseIncrement',
              // m: has one less space than the other lines, because otherwise,
              // it would display on the app one more space than the other lines
              tooltipMessage: '''
m:   Indicates a standard dev release.
n:    Indicates a hotfix to a dev or beta release.
y:    Indicates the first dev release after a beta release.
z:    Indicates a hotfix to a stable release.''',
            ),
          ),
        const SizedBox(width: 20.0),
        DropdownButton<String>(
          hint: const Text('-'), // Dropdown initially displays the hint when no option is selected.
          key: Key(substepName),
          value: releaseData[substepName],
          icon: const Icon(Icons.arrow_downward),
          items: options.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            changeIsDropdownValid(substepName, true);
            setReleaseData(substepName, newValue!);
          },
        ),
      ],
    );
  }
}
