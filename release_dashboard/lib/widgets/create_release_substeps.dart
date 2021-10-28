// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import '../logic/regex.dart';
import 'package:flutter/material.dart';

import 'common/tooltip.dart';

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

  static const List<String> substepTitles = <String>[
    'Candidate Branch',
    'Release Channel',
    'Framework Mirror',
    'Engine Mirror',
    'Engine Cherrypicks (if necessary)',
    'Framework Cherrypicks (if necessary)',
    'Dart Revision (if necessary)',
    'Increment',
  ];
}

class CreateReleaseSubstepsState extends State<CreateReleaseSubsteps> {
  // Initialize a public state so it could be accessed in the test file.
  @visibleForTesting
  late Map<String, String?> releaseData = <String, String?>{};
  List<bool> isEachInputValid = List<bool>.filled(CreateReleaseSubsteps.substepTitles.length, false);

  @override
  void initState() {
    // engine cherrypicks, framework cherrypicks and dart revision are optional and valid with empty input at the beginning
    isEachInputValid[4] = true;
    isEachInputValid[5] = true;
    isEachInputValid[6] = true;
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

  // When isEachInputValid[0] is true, the first parameter is valid. If it false, it is unvalid.
  void changeIsEachInputValid(int index, bool isValid) {
    setState(() {
      isEachInputValid[index] = isValid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InputAsSubstep(
          index: 0,
          setReleaseData: setReleaseData,
          hintText: 'The candidate branch the release will be based on.',
          changeIsInputValid: changeIsEachInputValid,
        ),
        CheckboxListTileDropdown(
          index: 1,
          releaseData: releaseData,
          setReleaseData: setReleaseData,
          options: const <String>['dev', 'beta', 'stable'],
          changeIsDropdownValid: changeIsEachInputValid,
        ),
        InputAsSubstep(
          index: 2,
          setReleaseData: setReleaseData,
          hintText: "Git remote of the Conductor user's Framework repository mirror.",
          changeIsInputValid: changeIsEachInputValid,
        ),
        InputAsSubstep(
          index: 3,
          setReleaseData: setReleaseData,
          hintText: "Git remote of the Conductor user's Engine repository mirror.",
          changeIsInputValid: changeIsEachInputValid,
        ),
        InputAsSubstep(
          index: 4,
          setReleaseData: setReleaseData,
          hintText: 'Engine cherrypick hashes to be applied. Multiple hashes delimited by a comma, no spaces.',
          changeIsInputValid: changeIsEachInputValid,
        ),
        InputAsSubstep(
          index: 5,
          setReleaseData: setReleaseData,
          hintText: 'Framework cherrypick hashes to be applied. Multiple hashes delimited by a comma, no spaces.',
          changeIsInputValid: changeIsEachInputValid,
        ),
        InputAsSubstep(
          index: 6,
          setReleaseData: setReleaseData,
          hintText: 'New Dart revision to cherrypick.',
          changeIsInputValid: changeIsEachInputValid,
        ),
        CheckboxListTileDropdown(
          index: 7,
          releaseData: releaseData,
          setReleaseData: setReleaseData,
          options: const <String>['y', 'z', 'm', 'n'],
          changeIsDropdownValid: changeIsEachInputValid,
        ),
        const SizedBox(height: 20.0),
        Center(
          child: ElevatedButton(
            key: const Key('step1continue'),
            onPressed: isEachInputValid.contains(false) // Continue button is disabled if any of the inputs are invalid
                ? null
                : () {
                    widget.nextStep();
                  },
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }
}

typedef SetReleaseData = void Function(String name, String data);
typedef ChangeIsEachInputValid = void Function(int index, bool isValid);

/// Captures the input values and updates the corresponding field in [releaseData].
class InputAsSubstep extends StatelessWidget {
  InputAsSubstep({
    Key? key,
    required this.index,
    required this.setReleaseData,
    this.hintText,
    required this.changeIsInputValid,
  }) : super(key: key);

  final int index;
  final SetReleaseData setReleaseData;
  final String? hintText;
  final ChangeIsEachInputValid changeIsInputValid;

  @override
  Widget build(BuildContext context) {
    late RegExp formRegexValidator;
    switch (index) {
      case 0:
        // formRegexValidator = releaseCandidateBranchRegex;
        formRegexValidator = RegExp(r'^flutter-(\d+)\.(\d+)-candidate\.(\d+)$');
        break;
      case 2:
      case 3:
        formRegexValidator = githubRemotePattern;
        break;
      case 4:
      case 5:
        formRegexValidator = multiGitHashRegex;
        break;
      case 6:
        formRegexValidator = gitHashRegex;
        break;
      default:
        break;
    }

    return TextFormField(
      key: Key(CreateReleaseSubsteps.substepTitles[index]),
      autovalidateMode: AutovalidateMode.always,
      decoration: InputDecoration(
        labelText: CreateReleaseSubsteps.substepTitles[index],
        hintText: hintText,
      ),
      onChanged: (String data) {
        setReleaseData(CreateReleaseSubsteps.substepTitles[index], data);
        if (!formRegexValidator.hasMatch(data)) {
          changeIsInputValid(index, false);
        } else {
          changeIsInputValid(index, true);
        }
      },
      validator: (String? value) {
        if (!formRegexValidator.hasMatch(value ?? '')) {
          return '${CreateReleaseSubsteps.substepTitles[index].replaceAll(' (if necessary)', '')} not in a valid format!';
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
    required this.index,
    required this.releaseData,
    required this.setReleaseData,
    required this.options,
    required this.changeIsDropdownValid,
  }) : super(key: key);

  final int index;
  final Map<String, String?> releaseData;
  final SetReleaseData setReleaseData;
  final List<String> options;
  final ChangeIsEachInputValid changeIsDropdownValid;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          CreateReleaseSubsteps.substepTitles[index],
          style: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.grey[700]),
        ),
        // Only add a tooltip for the increment dropdown
        if (index == 7)
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
          key: Key(CreateReleaseSubsteps.substepTitles[index]),
          value: releaseData[CreateReleaseSubsteps.substepTitles[index]],
          icon: const Icon(Icons.arrow_downward),
          items: options.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            changeIsDropdownValid(index, true);
            setReleaseData(CreateReleaseSubsteps.substepTitles[index], newValue!);
          },
        ),
      ],
    );
  }
}
