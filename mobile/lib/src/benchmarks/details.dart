// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../entities.dart';

import 'chart.dart';

class BenchmarkDetailsPage extends StatefulWidget {
  const BenchmarkDetailsPage({
    @required this.data,
  });

  final BenchmarkData data;

  @override
  _BenchmarkDetailsPageState createState() => _BenchmarkDetailsPageState();
}

class _BenchmarkDetailsPageState extends State<BenchmarkDetailsPage> {
  int _visibleIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Benchmark Details'),
            floating: true,
          ),
          SliverPersistentHeader(
            delegate: BenchmarkHeaderDelegate(
              title: widget.data.timeseries.timeseries.taskName,
              subtitle: widget.data.timeseries.timeseries.label,
            ),
            pinned: false,
            floating: false,
          ),
          SliverToBoxAdapter(
            child: Hero(
              child: BenchmarkChart(
                data: widget.data,
                rounded: false,
                onBarChanged: (int newIndex) {
                  setState(() {
                    _visibleIndex = newIndex;
                  });
                },
              ),
              tag: widget.data,
            ),
          ),
          SliverToBoxAdapter(
            child: BenchmarkRevisionDetails(
              data: widget.data.values[_visibleIndex],
              timeseries: widget.data.timeseries.timeseries,
            ),
          ),
        ],
      ),
    );
  }
}

class BenchmarkUpdateForm extends StatefulWidget {
  @override
  _BenchmarkUpdateFormState createState() => _BenchmarkUpdateFormState();
}

class _BenchmarkUpdateFormState extends State<BenchmarkUpdateForm> {
  bool _isArchived = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Form(
        autovalidate: true,
        child: ListBody(
          children: [
            TextFormField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Goal'),
            ),
            TextFormField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Baseline'),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Task name'),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Unit'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Row(
                children: [
                  const Text('Archived'),
                  Checkbox(
                    value: _isArchived,
                    onChanged: (bool newValue) {
                      setState(() {
                        _isArchived = newValue;
                      });
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BenchmarkRevisionDetails extends StatelessWidget {
  const BenchmarkRevisionDetails({this.data, this.timeseries});

  final TimeseriesValue data;
  final Timeseries timeseries;

  @override
  Widget build(BuildContext context) {
    var titles = [
      'Value',
      'Revision',
      'Date',
      'Goal',
      'Revision',
    ];
    var values = [
      '${data.value.round()} ${timeseries.unit}',
      'flutter/${data.revision.substring(0, 6)}',
      DateTime.fromMillisecondsSinceEpoch(data.createTimestamp).toString(),
      '${timeseries.goal} ${timeseries.unit}',
      '${timeseries.baseline} ${timeseries.unit}'
    ];
    var rows = <TableRow>[];
    for (var i = 0; i < values.length; i++) {
      rows.add(TableRow(children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              titles[i],
              style: const TextStyle(inherit: true, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              values[i],
            ),
          ),
        )
      ]));
    }
    return DefaultTextStyle(
      style: const TextStyle(fontSize: 16, color: Colors.black87, inherit: true),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black12,
          ),
        ),
        child: Table(
          children: rows,
        ),
      ),
    );
  }
}

/// The build status shown as a shrinking header.
class BenchmarkHeaderDelegate extends SliverPersistentHeaderDelegate {
  const BenchmarkHeaderDelegate({
    @required this.title,
    @required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    var theme = Theme.of(context);
    return Material(
      elevation: overlapsContent ? 4 : 0,
      color: theme.primaryColorDark,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            alignment: Alignment.centerLeft,
            child: Text(title, style: theme.textTheme.title.copyWith(color: Colors.white)),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            alignment: Alignment.centerLeft,
            child: Text(subtitle, style: theme.textTheme.subhead.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 80;

  @override
  double get minExtent => 80;

  @override
  bool shouldRebuild(covariant BenchmarkHeaderDelegate oldDelegate) {
    return oldDelegate.title != title || oldDelegate.subtitle != subtitle;
  }
}
