// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/conductor_status.dart';
import '../state/status_state.dart';

/// Group and display all substeps of the release to channel step.
///
/// [nextStep] can be executed to proceed to the next step.
/// Clicking on the publish releaes button will open a dialogue prompt
/// to confirm if the release tag is correct.
class PublishTagSubsteps extends StatefulWidget {
  const PublishTagSubsteps({
    Key? key,
    required this.nextStep,
  }) : super(key: key);

  final VoidCallback nextStep;

  @override
  State<PublishTagSubsteps> createState() => PublishTagSubstepsState();
}

class PublishTagSubstepsState extends State<PublishTagSubsteps> {
  @override
  Widget build(BuildContext context) {
    Map<ConductorStatusEntry, Object>? releaseStatus = context.watch<StatusState>().releaseStatus;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                  'Release tag ${releaseStatus?[ConductorStatusEntry.releaseVersion]} is ready '
                  'to be pushed to the remote repository.',
                  style: Theme.of(context).textTheme.subtitle1),
              const SizedBox(height: 20.0),
              Text(
                '*** Very Important ***',
                style: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.red),
              ),
              Text(
                'Please verify if the tag and the channel are correct. The action below is disruptive and irreversible',
                style: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        ElevatedButton(
          key: const Key('publishTagContinue'),
          onPressed: () {
            widget.nextStep();
          },
          child: const Text('Publish release tag'),
        ),
      ],
    );
  }
}
