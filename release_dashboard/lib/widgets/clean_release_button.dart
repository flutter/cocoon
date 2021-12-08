// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/error_to_string.dart';
import '../services/conductor.dart';
import '../state/status_state.dart';
import 'common/dialog_prompt.dart';
import 'common/snackbar_prompt.dart';

/// Button to clean the current release.
///
/// When the button is clicked, a dialogue prompt will open for confirmation.
/// Clicking on 'Yes' will clean the release, 'No' will close the dialogue prompt.
class CleanReleaseButton extends StatefulWidget {
  const CleanReleaseButton({
    Key? key,
  }) : super(key: key);

  @override
  State<CleanReleaseButton> createState() => _CleanReleaseButtonState();

  static const String requiredConfirmationString = 'clean release';
}

class _CleanReleaseButtonState extends State<CleanReleaseButton> {
  String? _errorMsg;

  void _updateErrorMsg(String? errorMsg) {
    setState(() {
      _errorMsg = errorMsg;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ConductorService conductor = context.watch<StatusState>().conductor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 40, 0),
      child: IconButton(
        key: const Key('conductorClean'),
        icon: const Icon(Icons.delete),
        onPressed: () => showDialog(
          context: context,
          builder: (_) => DialogPromptConfirmInput(
            confirmationString: CleanReleaseButton.requiredConfirmationString,
            title: Text(
              'Are you sure you want to clean up the current release',
              style: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.red),
            ),
            content: const Text('This will abort and delete a release in progress. This process is irreversible!'),
            leftButtonTitle: 'No',
            rightButtonTitle: 'Yes',
            rightButtonCallback: () async {
              try {
                await conductor.cleanRelease(context);
              } catch (error, stackTrace) {
                _updateErrorMsg(errorToString(error, stackTrace));
              }
              if (_errorMsg != null) {
                snackbarPrompt(context: context, msg: _errorMsg!);
              }
            },
          ),
        ),
        tooltip: 'Clean up the current release.',
      ),
    );
  }
}
