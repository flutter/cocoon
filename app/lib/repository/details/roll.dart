// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:intl/intl.dart';
import 'package:flutter_web/material.dart';

import '../models/roll_history.dart';
import '../models/providers.dart';

enum RollUnits { hour, day }

class RollDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final RollHistory rollHistory = ModelBinding.of<RollHistory>(context);
    return RefreshRollHistory(
        child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                  children: <Widget>[
                    const ListTile(
                      leading: Icon(Icons.merge_type),
                      title: Text('Roll History'),
                    ),
                    const _DetailTitle(title: 'Skia → Engine'),
                    _DetailItem(value: rollHistory.lastSkiaAutoRoll, unit: RollUnits.hour),
                    const _DetailTitle(title: 'Engine → Framework'),
                    _DetailItem(value: rollHistory.lastEngineRoll, unit: RollUnits.hour),
                    const _DetailTitle(title: 'master → dev channel'),
                    _DetailItem(value: rollHistory.lastDevBranchRoll),
                    const _DetailTitle(title: 'dev → beta channel'),
                    _DetailItem(value: rollHistory.lastBetaBranchRoll),
                    const _DetailTitle(title: 'beta → stable channel'),
                    _DetailItem(value: rollHistory.lastStableBranchRoll),
                  ]
              ),
            )
        )
    );
  }
}

class _DetailTitle extends StatelessWidget {
  const _DetailTitle({@required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Semantics(
        header: true,
        label: title,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 3.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text(title, style: textTheme.subtitle.copyWith(fontSize: textTheme.subhead.fontSize)),
              ],
            )
        )
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({@required this.value, this.unit = RollUnits.day});

  final DateTime value;
  final RollUnits unit;

  @override
  Widget build(BuildContext context) {
    DateFormat dateFormat;
    final TextTheme textTheme = Theme.of(context).textTheme;
    String parenthesis;
    if (value != null) {
      switch (unit) {
      // Ignoring Russian, etc pluralization problems.
        case RollUnits.hour:
          int hours = DateTime.now().difference(value).inHours;
          parenthesis = Intl.plural(hours, zero: '<1 hour ago', one: '1 hour ago', other: '$hours hours ago');
          dateFormat = DateFormat.jm();
          break;
        default:
          int days = DateTime.now().difference(value).inDays;
          parenthesis = Intl.plural(days, zero: 'today', one: '1 day ago', other: '$days days ago');
          dateFormat = DateFormat.MMMMd();
          break;
      }
    }
    return Padding(
        padding: const EdgeInsets.fromLTRB(5.0, 0.0, 5.0, 15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text((value != null) ? '${dateFormat.format(value.toLocal())} ($parenthesis)' : 'Unknown', style: textTheme.subhead),
          ],
        )
    );
  }
}
