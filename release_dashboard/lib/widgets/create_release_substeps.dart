// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/cherrypicks.dart';
import '../logic/error_to_string.dart';
import '../logic/git.dart';
import '../services/conductor.dart';
import '../state/status_state.dart';
import 'common/tooltip.dart';

/// The order of this enum decides which order the widgets in [CreateReleaseSubsteps] get rendered.
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

/// Displays all substeps related to create a release.
///
/// Uses input fields and dropdowns to capture all the parameters of the conductor start command.
///
/// Validates each input value. Displays an error message if it is not valid.
///
/// The continue button becomes enabled when all inputs are valid. Disabled otherwise.
///
/// When the continue button is pressed, a release starts to initialize based on all inputs provided.
/// While it is being initialized, the continue button becomes disabled, and a loading
/// animation will display.
///
/// When the release is successfully initialized, proceed to the next step. Otherwise, display
/// a red error message. The continue button will become enabled again.
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
<<<<<<< HEAD

  static const Map<CreateReleaseSubstep, String> inputHintText = <CreateReleaseSubstep, String>{
    CreateReleaseSubstep.candidateBranch: 'The candidate branch the release will be based on.',
    CreateReleaseSubstep.engineMirror: "Git remote of the Conductor user's Engine repository mirror.",
    CreateReleaseSubstep.frameworkMirror: "Git remote of the Conductor user's Framework repository mirror.",
    CreateReleaseSubstep.engineCherrypicks:
        'Engine cherrypick hashes to be applied. Multiple hashes delimited by a comma.',
    CreateReleaseSubstep.frameworkCherrypicks:
        'Framework cherrypick hashes to be applied. Multiple hashes delimited by a comma.',
    CreateReleaseSubstep.dartRevision: 'New Dart revision to cherrypick.',
  };

  static const List<CreateReleaseSubstep> dropdownElements = <CreateReleaseSubstep>[
    CreateReleaseSubstep.releaseChannel,
    CreateReleaseSubstep.increment,
  ];

  static const List<String> releaseChannels = <String>['dev', 'beta', 'stable'];
  static const List<String> releaseIncrements = <String>['y', 'z', 'm', 'n'];
=======
>>>>>>> 5b99b40 (updated the rest of the constants)
}

class CreateReleaseSubstepsState extends State<CreateReleaseSubsteps> {
  /// Initialize a public state so it could be accessed in the test file.
  @visibleForTesting
  late Map<CreateReleaseSubstep, String?> releaseData = <CreateReleaseSubstep, String?>{};
  String? _error;
  bool _isLoading = false;

  /// When [substep] in [isEachInputValid] is true, [substep] is valid. Otherwise, it is invalid.
  @visibleForTesting
  Map<CreateReleaseSubstep, bool> isEachInputValid = <CreateReleaseSubstep, bool>{};

  @override
  void initState() {
    List<CreateReleaseSubstep> kOptionalInput = <CreateReleaseSubstep>[
      CreateReleaseSubstep.engineCherrypicks,
      CreateReleaseSubstep.frameworkCherrypicks,
      CreateReleaseSubstep.dartRevision,
    ];
    // Engine cherrypicks, framework cherrypicks and dart revision are optional
    // and valid with empty input at the beginning.
    for (final CreateReleaseSubstep substep in CreateReleaseSubstep.values) {
      isEachInputValid = <CreateReleaseSubstep, bool>{
        ...isEachInputValid,
        substep: kOptionalInput.contains(substep),
      };
    }
    super.initState();
  }

  /// Updates the corresponding [field] in [releaseData] with [data].
  void setReleaseData(CreateReleaseSubstep substep, String data) {
    setState(() {
      releaseData = <CreateReleaseSubstep, String?>{
        ...releaseData,
        substep: data,
      };
    });
  }

  /// Modifies [substep] in [isEachInputValid] with [isValid].
  void changeIsEachInputValid(CreateReleaseSubstep substep, bool isValid) {
    setState(() {
      isEachInputValid = <CreateReleaseSubstep, bool>{
        ...isEachInputValid,
        substep: isValid,
      };
    });
  }

  /// Updates the error object with what the conductor throws.
  void setError(String? errorThrown) {
    setState(() {
      _error = errorThrown;
    });
  }

  /// Toggle if the widget is being loaded or not.
  void setIsLoading(bool result) {
    setState(() {
      _isLoading = result;
    });
  }

  /// Initialize a [StartContext] and execute the [run] function to start a release using the conductor.
  Future<void> runCreateRelease(ConductorService conductor) {
    // Data captured by the input forms and dropdowns are transformed to conform the formats of StartContext.
    return conductor.createRelease(
      candidateBranch: releaseData[CreateReleaseSubstep.candidateBranch] ?? '',
      releaseChannel: releaseData[CreateReleaseSubstep.releaseChannel] ?? '',
      frameworkMirror: releaseData[CreateReleaseSubstep.frameworkMirror] ?? '',
      engineMirror: releaseData[CreateReleaseSubstep.engineMirror] ?? '',
      engineCherrypickRevisions: cherrypickStringtoArray(releaseData[CreateReleaseSubstep.engineCherrypicks]),
      frameworkCherrypickRevisions: cherrypickStringtoArray(releaseData[CreateReleaseSubstep.frameworkCherrypicks]),
      dartRevision:
          releaseData[CreateReleaseSubstep.dartRevision] == '' ? null : releaseData[CreateReleaseSubstep.dartRevision],
      incrementLetter: releaseData[CreateReleaseSubstep.increment] ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final GitValidation candidateBranch = CandidateBranch();
    final GitValidation gitRemote = GitRemote();
    final GitValidation multiGitHash = MultiGitHash();
    final GitValidation gitHash = GitHash();

    final Map<CreateReleaseSubstep, GitValidation> gitValidatonMapping = <CreateReleaseSubstep, GitValidation>{
      CreateReleaseSubstep.candidateBranch: candidateBranch,
      CreateReleaseSubstep.frameworkMirror: gitRemote,
      CreateReleaseSubstep.engineMirror: gitRemote,
      CreateReleaseSubstep.engineCherrypicks: multiGitHash,
      CreateReleaseSubstep.frameworkCherrypicks: multiGitHash,
      CreateReleaseSubstep.dartRevision: gitHash,
    };

    final ConductorService conductor = context.watch<StatusState>().conductor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
<<<<<<< HEAD
        for (final CreateReleaseSubstep substep in CreateReleaseSubstep.values)
          if (CreateReleaseSubsteps.dropdownElements.contains(substep)) ...[
            DropdownAsSubstep(
              substep: substep,
              releaseData: releaseData[substep],
              setReleaseData: setReleaseData,
              options: substep == CreateReleaseSubstep.releaseChannel
                  ? CreateReleaseSubsteps.releaseChannels
                  : CreateReleaseSubsteps.releaseIncrements,
              changeIsDropdownValid: changeIsEachInputValid,
              isLoading: _isLoading,
            )
          ] else ...[
            InputAsSubstep(
              substep: substep,
              setReleaseData: setReleaseData,
              hintText: CreateReleaseSubsteps.inputHintText[substep],
              changeIsInputValid: changeIsEachInputValid,
              validationClass: gitValidatonMapping[substep]!,
              isLoading: _isLoading,
            )
          ],
=======
        InputAsSubstep(
          substepName: CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.candidateBranch]!,
          setReleaseData: setReleaseData,
          hintText: 'The candidate branch the release will be based on.',
          changeIsInputValid: changeIsEachInputValid,
          validationClass: candidateBranch,
        ),
        DropdownAsSubstep(
          substepName: CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.releaseChannel]!,
          releaseData: releaseData,
          setReleaseData: setReleaseData,
          options: kBaseReleaseChannels,
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
        DropdownAsSubstep(
          substepName: CreateReleaseSubsteps.substepTitles[CreateReleaseSubstep.increment]!,
          releaseData: releaseData,
          setReleaseData: setReleaseData,
          options: KReleaseIncrements,
          changeIsDropdownValid: changeIsEachInputValid,
        ),
>>>>>>> 5b99b40 (updated the rest of the constants)
        const SizedBox(height: 20.0),
        if (_error != null)
          Center(
            child: SelectableText(
              _error!,
              style: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.red),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              key: const Key('createReleaseContinue'),
              // If the release initialization is loading or any substeps is unchecked, disable this button.
              onPressed: isEachInputValid.containsValue(false) || _isLoading
                  ? null
                  : () async {
                      setError(null);
                      try {
                        setIsLoading(true);
                        await runCreateRelease(conductor);
                        // ignore: avoid_catches_without_on_clauses
                      } catch (error, stacktrace) {
                        setError(errorToString(error, stacktrace));
                      } finally {
                        setIsLoading(false);
                      }
                      if (_error == null) {
                        widget.nextStep();
                      }
                    },
              child: const Text('Continue'),
            ),
            const SizedBox(width: 30.0),
            if (_isLoading)
              const CircularProgressIndicator(
                semanticsLabel: 'Linear progress indicator',
              ),
          ],
        ),
      ],
    );
  }
}

typedef SetReleaseData = void Function(CreateReleaseSubstep name, String data);
typedef ChangeIsEachInputValid = void Function(CreateReleaseSubstep name, bool isValid);

/// Captures and validates the input values and updates the corresponding field in [releaseData].
///
/// [substep] is a [CreateReleaseSubstep] that represents the current substep
/// this widget renders.
///
/// [setReleaseData] is the method for modifying the state that stores all release
/// data needed for initialization.
///
/// [hintText] is the optional hintText of [TextFormField]. If it is not provided,
/// no hintText will be displayed.
///
/// [changeIsInputValid] is the method for modifying the state that tracks if
/// the current input field is valid.
///
/// [validationClass] is the Git class used to validate the current input, and display
/// corresponding error messages if the validation fails.
///
/// [isLoading] keeps track if a current release is currently initializing.
/// If it is true, [TextFormField] is disabled, not allowing users to modify the current input
/// during a loading phase. Else, [TextFormField] is enabled, allowing editing.
class InputAsSubstep extends StatelessWidget {
  const InputAsSubstep({
    Key? key,
    required this.substep,
    required this.setReleaseData,
    this.hintText,
    required this.changeIsInputValid,
    required this.validationClass,
    required this.isLoading,
  }) : super(key: key);

  final CreateReleaseSubstep substep;
  final SetReleaseData setReleaseData;
  final String? hintText;
  final ChangeIsEachInputValid changeIsInputValid;
  final GitValidation validationClass;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: Key(CreateReleaseSubsteps.substepTitles[substep]!),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: !isLoading,
      decoration: InputDecoration(
        labelText: CreateReleaseSubsteps.substepTitles[substep]!,
        hintText: hintText,
      ),
      onChanged: (String? data) {
        setReleaseData(substep, validationClass.sanitize(data));
        if (!validationClass.isValid(data)) {
          changeIsInputValid(substep, false);
        } else {
          changeIsInputValid(substep, true);
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

/// Captures the chosen option in a dropdown and updates the corresponding field in [releaseData].
///
/// [substep] is a [CreateReleaseSubstep] that represents the current substep
/// this widget renders.
///
/// [releaseData] is current dropdown's value stored in the state that stores all release
/// data needed for initialization.
///
/// [setReleaseData] is the method for modifying the state that stores all release
/// data needed for initialization.
///
/// [options] is a list of all the choices of the dropdown.
///
/// [changeIsDropdownValid] is the method for modifying the state that tracks if
/// each dropdown value is valid.
///
/// [isLoading] keeps track if a current release is currently initializing.
/// If true, [DropdownButton] is disabled, not allowing users to modify the current dropdown during
/// a loading phase. Else, [DropdownButton] is enabled, allowing editing.
class DropdownAsSubstep extends StatelessWidget {
  const DropdownAsSubstep({
    Key? key,
    required this.substep,
    required this.releaseData,
    required this.setReleaseData,
    required this.options,
    required this.changeIsDropdownValid,
    required this.isLoading,
  }) : super(key: key);

  final CreateReleaseSubstep substep;
  final String? releaseData;
  final SetReleaseData setReleaseData;
  final List<String> options;
  final ChangeIsEachInputValid changeIsDropdownValid;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          CreateReleaseSubsteps.substepTitles[substep]!,
          style: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.grey[700]),
        ),
        // Only add a tooltip for the increment dropdown
        if (substep == CreateReleaseSubstep.increment)
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
          key: Key(CreateReleaseSubsteps.substepTitles[substep]!),
          value: releaseData,
          icon: const Icon(Icons.arrow_downward),
          items: options.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: isLoading == true
              ? null
              : (String? newValue) {
                  changeIsDropdownValid(substep, true);
                  setReleaseData(substep, newValue!);
                },
        ),
      ],
    );
  }
}
