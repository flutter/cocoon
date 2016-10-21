// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:html';
import 'dart:math' as math;

import 'package:angular2/angular2.dart';
import 'package:cocoon/model.dart';
import 'package:http/http.dart' as http;

@Component(
  selector: 'benchmark-grid',
  template: r'''
  <div *ngIf="isLoading">Loading...</div>
  <div *ngIf="!isLoading" class="card-container">
    <benchmark-card
      *ngFor="let benchmark of benchmarks"
      [data]="benchmark">
    </benchmark-card>
  </div>
''',
  directives: const [NgIf, NgFor, NgClass, BenchmarkCard],
)
class BenchmarkGrid implements OnInit, OnDestroy {
  BenchmarkGrid(this._httpClient);

  final http.Client _httpClient;
  bool isLoading = true;
  List<BenchmarkData> benchmarks;
  Timer _reloadTimer;

  @override
  void ngOnInit() {
    reloadData();
    _reloadTimer = new Timer.periodic(const Duration(seconds: 30), (_) => reloadData());
  }

  @override
  void ngOnDestroy() {
    _reloadTimer?.cancel();
  }

  Future<Null> reloadData() async {
    isLoading = true;
    Map<String, dynamic> statusJson = JSON.decode((await _httpClient.get('/api/get-benchmarks')).body);
    GetBenchmarksResult result = GetBenchmarksResult.fromJson(statusJson);
    benchmarks = result.benchmarks;
    isLoading = false;
  }
}

@Component(
  selector: 'benchmark-card',
  template: r'''
<span class="metric-task-name">{{taskName}}</span>
<div class="metric" *ngIf="latestValue != null">
  <span class="metric-value">{{latestValue}}</span>
  <span class="metric-unit">{{unit}}</span>
</div>
<div class="metric-label">{{label}}</div>
<div #chartContainer></div>
  ''',
  directives: const [NgIf, NgFor, NgStyle],
)
class BenchmarkCard implements AfterViewInit {
  BenchmarkData _data;

  @ViewChild('chartContainer') ElementRef chartContainer;

  @Input() set data(BenchmarkData newData) {
    chartContainer.nativeElement.children.clear();
    _data = newData;
  }

  String get id => _data.timeseries.timeseries.id;
  String get taskName => _data.timeseries.timeseries.taskName;
  String get label => _data.timeseries.timeseries.label;
  String get unit => _data.timeseries.timeseries.unit;
  String get latestValue {
    if (_data.values.isEmpty) return null;
    num value = _data.values.first.value;
    if (value > 100) {
      // Ignore fractions in large values.
      value = value.round();
    }
    if (value < 100000) {
      return value.toString();
    } else {
      // The value is too big to fit on the card; switch to thousands.
      return '${value ~/ 1000}K';
    }
  }

  @override
  void ngAfterViewInit() {
    if (_data.values.isEmpty) return;
    double maxValue = _data.values
      .map((TimeseriesValue v) => v.value)
      .reduce(math.max);

    for (TimeseriesValue value in _data.values.reversed) {
      DivElement bar = new DivElement()
        ..classes.add('metric-value-bar')
        ..style.height = '${100 * value.value / maxValue}px';

      DivElement tooltip;
      bar.onMouseOver.listen((_) {
        tooltip = new DivElement()
          ..text = '${value.value}$unit\n'
            'Flutter revision: ${value.revision}\n'
            'Recorded on: ${new DateTime.fromMillisecondsSinceEpoch(value.createTimestamp)}'
          ..classes.add('metric-value-tooltip')
          ..style.top = '${bar.getBoundingClientRect().top}px'
          ..style.left = '${bar.getBoundingClientRect().right + 5}px';
        bar.style.backgroundColor = '#11CC11';
        document.body.append(tooltip);
      });
      bar.onMouseOut.listen((_) {
        bar.style.backgroundColor = '#AAFFAA';
        tooltip?.remove();
      });

      chartContainer.nativeElement.children.add(bar);
    }
  }
}
