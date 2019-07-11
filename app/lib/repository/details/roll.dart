// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';

import 'package:intl/intl.dart';
import 'package:flutter_web/material.dart';

import '../models/providers.dart';
import '../models/roll_history.dart';

enum RollUnits { hour, day }

class RollDetails extends StatelessWidget {
  const RollDetails();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontSizeFactor: 1.3),
      ),
      child: ModelBinding<RollHistory>(
        initialModel: RollHistory(),
        child: RefreshRollHistory(
          child: Column(
            children: <Widget>[
              ListTile(
                title: const Text('Skia → Engine'),
                subtitle: _DetailItem(value: (RollHistory history) => history.lastSkiaAutoRoll, unit: RollUnits.hour),
                onTap: () => window.open('https://autoroll.skia.org/r/skia-flutter-autoroll', '_blank')
              ),
              ListTile(
                title: const Text('Engine → Framework'),
                subtitle: _DetailItem(value: (RollHistory history) => history.lastEngineRoll, unit: RollUnits.hour),
                onTap: () => window.open('https://autoroll.skia.org/r/flutter-engine-flutter-autoroll', '_blank')
              ),
              ListTile(
                title: const Text('master → dev channel'),
                subtitle: _DetailItem(value: (RollHistory history) => history.lastDevBranchRoll),
                onTap: () => window.open('https://github.com/flutter/flutter/commits/dev', '_blank')
              ),
              ListTile(
                title: const Text('dev → beta channel'),
                subtitle: _DetailItem(value: (RollHistory history) => history.lastBetaBranchRoll),
                onTap: () => window.open('https://github.com/flutter/flutter/commits/beta', '_blank')
              ),
              ListTile(
                title: const Text('beta → stable channel'),
                subtitle: _DetailItem(value: (RollHistory history) => history.lastStableBranchRoll),
                onTap: () => window.open('https://github.com/flutter/flutter/commits/stable', '_blank')
              ),
              ListTile(
                title: const Text('flutter_web'),
                subtitle: _DetailItem(value: (RollHistory history) => history.lastFlutterWebCommit),
                onTap: () => window.open('https://github.com/flutter/flutter_web/commits/master', '_blank')
              ),
            ]
          ),
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({@required this.value, this.unit = RollUnits.day});

  final DateTime Function(RollHistory history) value;
  final RollUnits unit;

  @override
  Widget build(BuildContext context) {
    DateFormat dateFormat;
    String parenthesis;
    DateTime valueDate;
    final RollHistory history = ModelBinding.of<RollHistory>(context);
    if (value != null) {
      valueDate = value(history);
      if (valueDate != null) {
        if (unit == RollUnits.hour) {
          final int hours = DateTime.now().difference(valueDate).inHours;
          // Ignoring Russian, etc pluralization problems.
          parenthesis = Intl.plural(hours, zero: '<1 hour ago', one: '1 hour ago', other: '$hours hours ago');
          dateFormat = DateFormat.jm();
        } else {
          // RollUnits.day
          final int days = DateTime.now().difference(valueDate).inDays;
          parenthesis = Intl.plural(days, zero: 'today', one: '1 day ago', other: '$days days ago');
          dateFormat = DateFormat.MMMMd();
        }
      }
    }
    return Text(
      (valueDate != null) ? '${dateFormat.format(valueDate.toLocal())} ($parenthesis)' : 'Unknown',
      style: Theme.of(context).textTheme.body1
    );
  }
}
