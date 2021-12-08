// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/conductor_status.dart';
import '../state/status_state.dart';

/// Displays a message that the release is successfully released!
class ReleaseCompleted extends StatefulWidget {
  const ReleaseCompleted({
    Key? key,
  }) : super(key: key);

  @override
  State<ReleaseCompleted> createState() => ReleaseCompletedState();
}

class ReleaseCompletedState extends State<ReleaseCompleted> {
  @override
  Widget build(BuildContext context) {
    Map<ConductorStatusEntry, Object>? releaseStatus = context.watch<StatusState>().releaseStatus;

    return Text(
        'Congratulations! The release ${releaseStatus![ConductorStatusEntry.releaseVersion]} '
        'has been successfully released to the ${releaseStatus[ConductorStatusEntry.releaseChannel]} channel!',
        style: Theme.of(context).textTheme.subtitle1);
  }
}
