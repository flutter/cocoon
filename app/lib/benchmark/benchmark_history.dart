// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:cocoon/benchmark/benchmark_card.dart';
import 'package:cocoon/models.dart';
import 'package:http/http.dart' as http;

@Component(
  selector: 'benchmark-history',
  templateUrl: 'benchmark_history.html',
  directives: const [
    NgIf,
    BenchmarkCard,
    formDirectives,
  ],
)
class BenchmarkHistory {
  BenchmarkHistory(this._httpClient);

  final http.Client _httpClient;

  String _key;

  @Input()
  bool userIsAuthenticated = false;

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

  String _taskName = '';
  String get taskName => _taskName;
  set taskName(String value) {
    _taskName = value;
    _validateInputs();
  }

  String _label = '';
  String get label => _label;
  set label(String value) {
    _label = value;
    _validateInputs();
  }

  String _unit = '';
  String get unit => _unit;
  set unit(String value) {
    _unit = value;
    _validateInputs();
  }

  bool _archived;
  bool get archived => _archived;
  set archived(bool value) {
    _archived = value;
    _validateInputs();
  }

  bool _isInputValid = false;
  bool get isInputValid => _isInputValid;

  String _statusMessage;
  String get statusMessage => _statusMessage;

  void _validateInputs() {
    _isInputValid = true;
    if (double.tryParse(_goal) == null) _isInputValid = false;
    if (double.tryParse(_baseline) == null) _isInputValid = false;
    if (_taskName == null || _taskName.trim().isEmpty) {
      _isInputValid = false;
    }
    if (_label == null || _label.trim().isEmpty) {
      _isInputValid = false;
    }
    if (_unit == null || _unit.trim().isEmpty) {
      _isInputValid = false;
    }
    if (archived == null) {
      _isInputValid = false;
    }
  }

  void autoUpdateTargets() {
    if (_autoUpdateGoal == null) return;

    goal = _autoUpdateGoal;
    baseline = _autoUpdateBaseline;
  }

  Future<Null> update() async {
    _validateInputs();

    if (!_isInputValid) {
      window.alert('Invalid input.');
      return;
    }

    Map<String, dynamic> request = <String, dynamic>{
      'TimeSeriesKey': _key,
      'Goal': double.tryParse(_goal),
      'Baseline': double.tryParse(_baseline),
      'TaskName': _taskName.trim(),
      'Label': _label.trim(),
      'Unit': _unit.trim(),
      'Archived': _archived,
    };

    http.Response response = await _httpClient.post('/api/update-timeseries', body: json.encode(request));
    if (response.statusCode == 200) {
      _statusMessage = 'New targets saved.';
      await _loadData();
    } else {
      _statusMessage = 'Server responded with an error saving new targets (HTTP ${response.statusCode})';
    }
  }

  @Input()
  set timeseriesKey(String key) {
    if (key == null) {
      throw 'Timeseries key must not be null';
    }
    _key = key;
    _loadData();
  }

  BenchmarkData data;
  String lastPosition;

  Future<Null> _loadData() async {
    Map<String, dynamic> request = <String, dynamic>{
      'TimeSeriesKey': _key,
    };

    if (lastPosition != null && lastPosition != '{}') {
      request['StartFrom'] = lastPosition;
    }

    http.Response response = await _httpClient.post('/api/public/get-timeseries-history', body: json.encode(request));
    GetTimeseriesHistoryResult result = GetTimeseriesHistoryResult.fromJson(json.decode(response.body));

    data = null;
    Timer.run(() {
      // force Angular to rerender
      final double secondHighest = computeSecondHighest(result.benchmarkData.values.map((t) => t.value));
      _autoUpdateGoal = (1.005 * secondHighest).toStringAsFixed(1);
      _autoUpdateBaseline = (1.05 * secondHighest).toStringAsFixed(1);
      _autoUpdateTitle = 'Autoupdate to ${_autoUpdateGoal} goal/${_autoUpdateBaseline} baseline';

      data = result.benchmarkData;
      final Timeseries timeseries = result.benchmarkData.timeseries.timeseries;
      _goal = timeseries.goal.toString();
      _baseline = timeseries.baseline.toString();
      _taskName = timeseries.taskName;
      _label = timeseries.label;
      _unit = timeseries.unit;
      _archived = timeseries.isArchived;
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
