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
  <div *ngIf="zoomInto != null" class="benchmark-history-container">
    <benchmark-history [timeseriesKey]="zoomInto.timeseries.key"></benchmark-history>
    <button (click)="zoomInto = null">Close History</button>
  </div>
  <div *ngIf="visibleBenchmarks != null" class="card-container">
    <benchmark-card
      class="short-benchmark-card"
      *ngFor="let benchmark of visibleBenchmarks"
      [data]="benchmark"
      (onZoomIn)="zoomInto = benchmark">
    </benchmark-card>
  </div>
''',
  directives: const [NgIf, NgFor, NgClass, BenchmarkCard, BenchmarkHistory],
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

  /// If not `null` the benchmark whose history is shown on screen.
  BenchmarkData _zoomInto;
  BenchmarkData get zoomInto => _zoomInto;
  set zoomInto(BenchmarkData newData) {
    // Force angular to destroy old card and create a new one.
    _zoomInto = null;
    if (newData != null) {
      Timer.run(() {
        _zoomInto = newData;
      });
    }
  }

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
  selector: 'benchmark-history',
  template: r'''
    <benchmark-card *ngIf="data != null" [barWidth]="'narrow'" [data]="data"></benchmark-card>
    <div>{{statusMessage}}</div>
    <div style="margin: 20px">
      <span>Goal:</span>
      <input type="text" [(ngModel)]="goal">
      <span>Baseline:</span>
      <input type="text" [(ngModel)]="baseline">
      <button [disabled]="!isInputValid" (click)="updateTargets()">Update</button>
      <button (click)="autoUpdateTargets()">{{autoUpdateTitle}}</button>
    </div>
  ''',
  directives: const [NgIf, NgModel, BenchmarkCard],
)
class BenchmarkHistory {
  BenchmarkHistory(this._httpClient);

  final http.Client _httpClient;

  Key _key;

  String _autoUpdateGoal;
  String _autoUpdateBaseline;
  String _autoUpdateTitle = 'Calculating autoupdate...';
  String get autoUpdateTitle => _autoUpdateTitle;

  String _goal = '';
  String get goal => _goal;
  set goal(String textValue) {
    _goal = textValue.trim();
    _validateInputs();
  }

  String _baseline = '';
  String get baseline => _baseline;
  set baseline(String textValue) {
    _baseline = textValue.trim();
    _validateInputs();
  }

  bool _isInputValid = false;
  bool get isInputValid => _isInputValid;

  String _statusMessage;
  String get statusMessage => _statusMessage;

  void _validateInputs() {
    _isInputValid = true;
    double.parse(_goal, (_) {
      _isInputValid = false;
    });
    double.parse(_baseline, (_) {
      _isInputValid = false;
    });
  }

  void autoUpdateTargets() {
    if (_autoUpdateGoal == null)
      return;

    goal = _autoUpdateGoal;
    baseline = _autoUpdateBaseline;
  }

  Future<Null> updateTargets() async {
    _validateInputs();

    if (!_isInputValid) {
      window.alert('Invalid input.');
      return;
    }

    Map<String, dynamic> request = <String, dynamic>{
      'TimeSeriesKey': _key.value,
      'Goal': double.parse(_goal),
      'Baseline': double.parse(_baseline),
    };

    http.Response response = await _httpClient.post('/api/update-benchmark-targets', body: JSON.encode(request));
    if (response.statusCode == 200) {
      goal = '';
      baseline = '';
      _statusMessage = 'New targets saved.';
      await _loadData();
    } else {
      _statusMessage = 'Server responded with and error saving new targets (HTTP ${response.statusCode})';
    }
  }

  @Input() set timeseriesKey(Key key) {
    if (key == null) {
      throw 'Timeseries key must not be null';
    }
    _key = key;
    _loadData();
  }

  BenchmarkData data;
  Cursor lastPosition;

  Future<Null> _loadData() async {
    Map<String, dynamic> request = <String, dynamic>{
      'TimeSeriesKey': _key.value,
    };

    if (lastPosition != null) {
      request['StartFrom'] = lastPosition.value;
    }

    http.Response response = await _httpClient.post('/api/get-timeseries-history', body: JSON.encode(request));
    GetTimeseriesHistoryResult result = GetTimeseriesHistoryResult.fromJson(JSON.decode(response.body));

    data = null;
    Timer.run(() {  // force Angular to rerender
      final double secondHighest = computeSecondHighest(result.benchmarkData.values.map((t) => t.value));
      _autoUpdateGoal = (1.005 * secondHighest).toStringAsFixed(1);
      _autoUpdateBaseline = (1.05 * secondHighest).toStringAsFixed(1);
      _autoUpdateTitle = 'Autoupdate to ${_autoUpdateGoal} goal/${_autoUpdateBaseline} baseline';

      data = result.benchmarkData;
      _goal = result.benchmarkData.timeseries.timeseries.goal.toString();
      _baseline = result.benchmarkData.timeseries.timeseries.baseline.toString();
      lastPosition = result.lastPosition;
    });
  }
}

double computeSecondHighest(Iterable<double> values) {
  double highest = 0.0;
  double secondHighest = 0.0;

  int count = 0;
  for (double value in values.take(20)) {
    count++;

    if (value > secondHighest) {
      if (value > highest) {
        secondHighest = highest;
        highest = value;
      } else {
        secondHighest = value;
      }
    }
  }

  return count > 1 ? secondHighest : highest;
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
<div class="zoom-button" (click)="zoomIn()">&#x1f50d;</div>
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

  @Input() String barWidth = 'medium';

  @Input() set data(BenchmarkData newData) {
    chartContainer.nativeElement.children.clear();
    _data = newData;
  }

  final StreamController<Null> _onZoomIn = new StreamController<Null>();

  /// Emits an event when the user clicks on the zoom in button.
  @Output() Stream<Null> get onZoomIn => _onZoomIn.stream;

  void zoomIn() {
    _onZoomIn.add(null);
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
      final double valueHeight = _kChartHeight * value.value / maxValue;

      DivElement bar = new DivElement()
        ..classes.add('metric-value-bar')
        ..style.height = '${_kChartHeight - valueHeight}px'
        ..style.borderWidth = '0 0 ${valueHeight}px 0';

      if (barWidth == 'narrow')
        bar.classes.add('metric-value-bar-narrow');

      if (value.value > baseline) {
        bar.classes.add('metric-value-bar-underperformed');
      } else if (value.value > goal) {
        bar.classes.add('metric-value-bar-needs-work');
      }

      bar.onMouseOver.listen((_) {
        DivElement tooltip;
        // Used to distinguish between clicks and drags.
        bool dragHappened = false;
        tooltip = new DivElement()
          ..classes.add('metric-value-tooltip')
          ..style.top = '${bar.getBoundingClientRect().top}px'
          ..onMouseDown.listen((_) {
            dragHappened = false;
          })
          ..onMouseMove.listen((_) {
            dragHappened = true;
          })
          ..onClick.listen((_) {
              if (!dragHappened)
                tooltip.remove();
            });

        final String revisionLink = 'https://github.com/flutter/flutter/commit/${value.revision}';

        tooltip.setInnerHtml(
          '${value.value}$unit\n'
          'Flutter revision: <a href="$revisionLink" target="_blank">${value.revision}</a>\n'
          'Recorded on: ${new DateTime.fromMillisecondsSinceEpoch(value.createTimestamp)}\n'
          'Goal: $goal$unit\n'
          'Baseline: $baseline$unit',
          validator: const _NullValidator(),
        );

        final double left = bar.getBoundingClientRect().left;
        if (left < window.innerWidth / 2.0) {
          tooltip.style.left = '${bar.getBoundingClientRect().right + 5}px';
        } else {
          tooltip.style.right = '${window.innerWidth - left + 5}px';
        }
        bar.style.opacity = '0.5';
        bar.style.backgroundColor = '#FFC400'; // Amber Accent 400
        document.body.append(tooltip);
        _tooltip = tooltip;
      });
      bar.onMouseOut.listen((_) {
        bar.style.opacity = '1.0';
        bar.style.backgroundColor = '';
        _tooltip?.remove();
      });
      bar.onClick.listen((_) {
        _tooltip = null;
      });

      chartContainer.nativeElement.children.add(bar);
    }
  }

  @override
  void ngOnDestroy() {
    _tooltip?.remove();
  }
}

class _NullValidator implements NodeValidator {
  const _NullValidator();

  @override
  bool allowsElement(Element element) => true;

  @override
  bool allowsAttribute(Element element, String attributeName, String value) => true;
}
