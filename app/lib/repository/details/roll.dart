// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:intl/intl.dart';
import 'package:flutter_web/material.dart';

import '../models/providers.dart';
import '../models/roll_history.dart';

enum RollUnits { hour, day }

class RollDetails extends StatelessWidget {
  const RollDetails();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ModelBinding<RollHistory>(
          initialModel: RollHistory(),
          child: RefreshRollHistory(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: IconTheme(data: Theme.of(context).iconTheme.copyWith(size: 28.0), child: Icon(Icons.merge_type)),
                  title: const Text('Roll History'),
                ),
                const _DetailTitle(title: 'Skia → Engine'),
                _DetailItem(value: (RollHistory history) => history.lastSkiaAutoRoll, unit: RollUnits.hour),
                const _DetailTitle(title: 'Engine → Framework'),
                _DetailItem(value: (RollHistory history) => history.lastEngineRoll, unit: RollUnits.hour),
                const _DetailTitle(title: 'master → dev channel'),
                _DetailItem(value: (RollHistory history) => history.lastDevBranchRoll),
                const _DetailTitle(title: 'dev → beta channel'),
                _DetailItem(value: (RollHistory history) => history.lastBetaBranchRoll),
                const _DetailTitle(title: 'beta → stable channel'),
                _DetailItem(value: (RollHistory history) => history.lastStableBranchRoll),
              ]
            ),
          )
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

  final DateTime Function(RollHistory history) value;
  final RollUnits unit;

  @override
  Widget build(BuildContext context) {
    DateFormat dateFormat;
    String parenthesis;
    DateTime valueDate;
    RollHistory history = ModelBinding.of<RollHistory>(context);
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(5.0, 0.0, 5.0, 15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Text((valueDate != null) ? '${dateFormat.format(valueDate.toLocal())} ($parenthesis)' : 'Unknown', style: Theme.of(context).textTheme.subhead),
        ],
      )
    );
  }
}
