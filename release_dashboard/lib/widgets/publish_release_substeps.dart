// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/error_to_string.dart';
import '../models/conductor_status.dart';
import '../state/status_state.dart';
import 'common/continue_button.dart';

/// Group and display all widgets related to push release to channel step.
///
/// Clicking on the continue button will push the release changes to the release
/// channel branch.
class PublishReleaseSubsteps extends StatefulWidget {
  const PublishReleaseSubsteps({
    Key? key,
  }) : super(key: key);

  @override
  State<PublishReleaseSubsteps> createState() => PublishReleaseSubstepsState();
}

class PublishReleaseSubstepsState extends State<PublishReleaseSubsteps> {
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
  Widget build(BuildContext context) {
    final StatusState statusState = context.watch<StatusState>();
    final Map<ConductorStatusEntry, Object>? releaseStatus = statusState.releaseStatus;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                  'Release ${releaseStatus![ConductorStatusEntry.releaseVersion]} is ready '
                  'to be pushed to the remote ${releaseStatus[ConductorStatusEntry.releaseChannel]} repository.',
                  style: Theme.of(context).textTheme.subtitle1),
              const SizedBox(height: 20.0),
              Text(
                '*** Very Important ***',
                style: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.red),
              ),
              // TODO(Yugue): Add DialoguePrompt to confirm tag creation,
              // https://github.com/flutter/flutter/issues/94222.
              Text(
                'Please verify if the release number and the channel are correct. The action below is disruptive and irreversible',
                style: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20.0),
        ContinueButton(
          elevatedButtonKey: const Key('publishReleaseContinue'),
          enabled: true,
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
