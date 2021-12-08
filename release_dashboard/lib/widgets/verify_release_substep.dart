// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/error_to_string.dart';
import '../models/conductor_status.dart';
import '../state/status_state.dart';
import 'common/checkbox_substep.dart';
import 'common/continue_button.dart';
import 'common/url_button.dart';

enum VerifyReleaseSubstep {
  pushRelease,
  verifyRelease,
}

/// Group and display all substeps related to verify the release step.
///
/// This is the last step of the release.
///
/// The continue button becomes enabled when all required substeps are checked. Disabled otherwise.
/// When the continue button is pressed, proceed to the next step. Any errors will be displayed
/// above the continue button in red..
class VerifyReleaseSubsteps extends StatefulWidget {
  const VerifyReleaseSubsteps({
    Key? key,
  }) : super(key: key);

  @override
  State<VerifyReleaseSubsteps> createState() => VerifyReleaseSubstepsState();

  static const Map<VerifyReleaseSubstep, String> substepTitles = <VerifyReleaseSubstep, String>{
    VerifyReleaseSubstep.pushRelease: 'Push to the remote channel branch',
    VerifyReleaseSubstep.verifyRelease: 'Verify the release',
  };
  static const Map<VerifyReleaseSubstep, String> substepSubtitles = <VerifyReleaseSubstep, String>{
    VerifyReleaseSubstep.pushRelease: 'A special access might be needed to push to the',
    VerifyReleaseSubstep.verifyRelease:
        'After the push, please make sure the release passes all packaging builds here: ',
  };
}

class VerifyReleaseSubstepsState extends State<VerifyReleaseSubsteps> {
  final Map<VerifyReleaseSubstep, bool> _isEachSubstepChecked = <VerifyReleaseSubstep, bool>{};
  String? _error;
  bool _isLoading = false;

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

  @override
  void initState() {
    /// If [substep] is false, that substep is unchecked, otherwise, it is checked.
    ///
    /// All substeps are unchecked at the beginning.
    for (final VerifyReleaseSubstep substep in VerifyReleaseSubstep.values) {
      _isEachSubstepChecked[substep] = false;
    }
    super.initState();
  }

  /// Toggle the boolean value [substepName].
  void substepPressed(VerifyReleaseSubstep substep) {
    setState(() {
      _isEachSubstepChecked[substep] = !_isEachSubstepChecked[substep]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final StatusState statusState = context.watch<StatusState>();
    final Map<ConductorStatusEntry, Object>? releaseStatus = statusState.releaseStatus;
    final String postMonitorLuci = luciConsoleLink(
      releaseStatus![ConductorStatusEntry.releaseChannel] as String,
      'packaging',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        CheckboxAsSubstep(
          substepName: VerifyReleaseSubsteps.substepTitles[VerifyReleaseSubstep.pushRelease]!,
          subtitle: SelectableText('${VerifyReleaseSubsteps.substepSubtitles[VerifyReleaseSubstep.pushRelease]!} '
              '${releaseStatus[ConductorStatusEntry.releaseChannel]} branch directly. '
              'Please request for the authorized access if necessary, and push the release to the channel.'),
          isChecked: _isEachSubstepChecked[VerifyReleaseSubstep.pushRelease]!,
          clickCallback: () {
            substepPressed(VerifyReleaseSubstep.pushRelease);
          },
        ),
        CheckboxAsSubstep(
          substepName: VerifyReleaseSubsteps.substepTitles[VerifyReleaseSubstep.verifyRelease]!,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(VerifyReleaseSubsteps.substepSubtitles[VerifyReleaseSubstep.verifyRelease]!),
              UrlButton(textToDisplay: postMonitorLuci, urlOrUri: postMonitorLuci),
            ],
          ),
          isChecked: _isEachSubstepChecked[VerifyReleaseSubstep.verifyRelease]!,
          clickCallback: () {
            substepPressed(VerifyReleaseSubstep.verifyRelease);
          },
        ),
        const SizedBox(height: 20.0),
        ContinueButton(
          elevatedButtonKey: const Key('verifyReleaseContinue'),
          enabled: !_isEachSubstepChecked.containsValue(false),
          error: _error,
          onPressedCallback: () async {
            setError(null);
            setIsLoading(true);
            try {
              await statusState.conductor.conductorNext(context);
            } catch (error, stacktrace) {
              setError(errorToString(error, stacktrace));
            } finally {
              setIsLoading(false);
            }
          },
          isLoading: _isLoading,
        ),
      ],
    );
  }
}
