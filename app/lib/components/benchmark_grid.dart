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

/// Checks if benchmark [data] satisfies some condition.
typedef bool _BenchmarkPredicate(BenchmarkData data);

@Component(
  selector: 'benchmark-grid',
  template: r'''
  <div *ngIf="isLoading" style="position: fixed; top: 0; left: 0; z-index: 1000; background-color: #AAFFAA;">Loading...</div>
  <div style="margin: 5px;">
    <button id="toggleArchived" (click)="toggleArchived()">{{isShowArchived ? "Hide" : "Show"}} Archived</button>
    <input type="text" placeholder="Filter visible benchmarks" (keyup)="applyTextFilter($event.target.value)">
  </div>
  <div *ngIf="visibleBenchmarks != null" class="card-container">
    <benchmark-card
      *ngFor="let benchmark of visibleBenchmarks"
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
  List<BenchmarkData> _benchmarks;
  List<BenchmarkData> visibleBenchmarks;
  Timer _reloadTimer;
  bool _isShowArchived = false;

  String _taskTextFilter;
  bool get isShowArchived => _isShowArchived;

  void toggleArchived() {
    _isShowArchived = !_isShowArchived;
    _applyFilters();
  }

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
    _benchmarks = GetBenchmarksResult.fromJson(statusJson).benchmarks;
    _applyFilters();
    isLoading = false;
  }

  void applyTextFilter(String newFilter) {
    _taskTextFilter = newFilter?.trim()?.toLowerCase();
    _applyFilters();
  }

  void _applyFilters() {
    if (_benchmarks == null) {
      visibleBenchmarks = [];
      return;
    }

    List<_BenchmarkPredicate> filters = <_BenchmarkPredicate>[];

    if (_taskTextFilter != null && _taskTextFilter.trim().isNotEmpty) {
      filters.add((BenchmarkData data) {
        bool labelMatches = data.timeseries.timeseries.label?.toLowerCase()?.contains(_taskTextFilter) == true;
        bool taskNameMatches = data.timeseries.timeseries.taskName?.toLowerCase()?.contains(_taskTextFilter) == true;
        return labelMatches || taskNameMatches;
      });
    }

    if (!_isShowArchived) {
      filters.add((BenchmarkData data) => !data.timeseries.timeseries.isArchived);
    }

    visibleBenchmarks = _benchmarks;
    for (_BenchmarkPredicate filter in filters) {
      visibleBenchmarks = visibleBenchmarks.where(filter).toList();
    }
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
<div class="metric-chart-container" #chartContainer></div>
  ''',
  directives: const [NgIf, NgFor, NgStyle],
)
class BenchmarkCard implements AfterViewInit, OnDestroy {
  /// The total height of the chart. This value must be in sync with the height
  /// specified for benchmark-card in benchmarks.css.
  static const int _kChartHeight = 100;

  BenchmarkData _data;
  DivElement _tooltip;

  @ViewChild('chartContainer') ElementRef chartContainer;

  @Input() set data(BenchmarkData newData) {
    chartContainer.nativeElement.children.clear();
    _data = newData;
  }

  double get goal => _data.timeseries.timeseries.goal;

  /// The baseline value for this metric.
  ///
  /// We must perform better than the baseline. Otherwise, we consider it a
  /// regression, paint it in red and must work to fix as soon as possible.
  double get baseline => _data.timeseries.timeseries.baseline > goal
    ? _data.timeseries.timeseries.baseline
    : goal;

  String get id => _data.timeseries.timeseries.id;
  String get taskName => _data.timeseries.timeseries.taskName;
  String get label => _data.timeseries.timeseries.label;
  String get unit => _data.timeseries.timeseries.unit;
  String get latestValue {
    if (_data.values == null || _data.values.isEmpty) return null;
    num value = _data.values.first.value;
    if (value < 10) {
      value.toStringAsPrecision(2);
      return value.toStringAsFixed(2);
    } else if (value < 100) {
      return value.toStringAsFixed(1);
    } else if (value < 100000) {
      return value.toStringAsFixed(0);
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
      .fold(goal, math.max);

    // Leave a bit of room so bars don't fill the height of the card
    maxValue = maxValue > 0.0
      ? maxValue * 1.1
      : 1.0;  // if everything is 0.0, use an artificial chart height

    int goalHeight = (_kChartHeight * goal) ~/ maxValue;
    int baselineHeight = (_kChartHeight * baseline) ~/ maxValue;

    if (baselineHeight == goalHeight) {
      // Just so the two lines are not on top of each other
      baselineHeight += 1;
    }

    chartContainer.nativeElement.children.add(
        new DivElement()
          ..classes.add('metric-goal')
          ..style.height = '${goalHeight}px'
    );

    chartContainer.nativeElement.children.add(
        new DivElement()
          ..classes.add('metric-baseline')
          ..style.height = '${baselineHeight}px'
    );

    for (TimeseriesValue value in _data.values.reversed) {
      DivElement bar = new DivElement()
        ..classes.add('metric-value-bar')
        ..style.height = '${_kChartHeight * value.value / maxValue}px';

      if (value.value > baseline) {
        bar.classes.add('metric-value-bar-underperformed');
      } else if (value.value > goal) {
        bar.classes.add('metric-value-bar-needs-work');
      }

      bar.onMouseOver.listen((_) {
        _tooltip = new DivElement()
          ..text = '${value.value}$unit\n'
            'Flutter revision: ${value.revision}\n'
            'Recorded on: ${new DateTime.fromMillisecondsSinceEpoch(value.createTimestamp)}\n'
            'Goal: $goal$unit\n'
            'Baseline: $baseline$unit'
          ..classes.add('metric-value-tooltip')
          ..style.top = '${bar.getBoundingClientRect().top}px'
          ..style.left = '${bar.getBoundingClientRect().right + 5}px';
        bar.style.backgroundColor = '#11CC11';
        document.body.append(_tooltip);
      });
      bar.onMouseOut.listen((_) {
        bar.style.backgroundColor = '';
        _tooltip?.remove();
      });

      chartContainer.nativeElement.children.add(bar);
    }
  }

  @override
  void ngOnDestroy() {
    _tooltip?.remove();
  }
}
