// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' hide Event;

import 'package:charted/charts/charts.dart';
import 'package:firebase/firebase.dart';

Firebase firebase;
CartesianArea analysisChartArea;
CartesianArea dartdocChartArea;
CartesianArea refreshChartArea;

Map<int, Measurement> repoMeasurements = {};
Map<int, Measurement> galleryMeasurements = {};
Map<int, Measurement> refreshMeasurements = {};

void main() {
  _updateAnalysisChart();
  _updateDartdocChart();
  _updateRefreshChart();

  firebase = new Firebase("https://purple-butterfly-3000.firebaseio.com/");
  firebase.onAuth().listen((context) {
    _listenForChartChanges();
  });
}

void _listenForChartChanges() {
  Firebase repoAnalysis = firebase.child("measurements/analyzer_cli__analysis_time/history");
  Firebase galleryAnalysis = firebase.child("measurements/analyzer_server__analysis_time/history");
  Firebase refreshTimes = firebase.child("measurements/mega_gallery__refresh_time/history");

  DateTime startDate = new DateTime.now().subtract(new Duration(days: 90));

  Query repoQuery = repoAnalysis
    .orderByChild('timestamp')
    .startAt(key: 'timestamp', value: startDate.millisecondsSinceEpoch)
    .limitToLast(2000);
  Query galleryQuery = galleryAnalysis
    .orderByChild('timestamp')
    .startAt(key: 'timestamp', value: startDate.millisecondsSinceEpoch)
    .limitToLast(2000);
  Query refreshQuery = refreshTimes
    .orderByChild('timestamp')
    .startAt(key: 'timestamp', value: startDate.millisecondsSinceEpoch)
    .limitToLast(2000);

  repoQuery.onValue.listen((Event event) {
    repoMeasurements = {};
    event.snapshot.forEach((DataSnapshot snapshot) {
      Measurement measurement = new Measurement(snapshot.val());
      if (measurement.timestampMillis != null) {
        repoMeasurements[measurement.timestampMillis] = measurement;
      }
    });
    _updateCharts();
  });
  galleryQuery.onValue.listen((Event event) {
    galleryMeasurements = {};
    event.snapshot.forEach((DataSnapshot snapshot) {
      Measurement measurement = new Measurement(snapshot.val());
      if (measurement.timestampMillis != null) {
        galleryMeasurements[measurement.timestampMillis] = measurement;
      }
    });
    _updateCharts();
  });
  refreshQuery.onValue.listen((Event event) {
    refreshMeasurements = {};
    event.snapshot.forEach((DataSnapshot snapshot) {
      Measurement measurement = new Measurement(snapshot.val());
      if (measurement.timestampMillis != null) {
        refreshMeasurements[measurement.timestampMillis] = measurement;
      }
    });
    _updateCharts();
  });
}

void _updateCharts() {
  List<int> times = new List.from(new Set<int>()
    ..addAll(repoMeasurements.keys)
    ..addAll(galleryMeasurements.keys)
  )..sort();
  List analysisData = times.map((int time) {
    return [time, repoMeasurements[time]?.time, galleryMeasurements[time]?.time];
  }).toList();
  _updateAnalysisChart(analysisData);

  times = repoMeasurements.keys.toList()..sort();
  List dartdocData = times
    .map((int time) => [time, repoMeasurements[time].missingDartDocs])
    .where((List tuple) => tuple[1] != null)
    .toList();
  _updateDartdocChart(dartdocData);

  times = refreshMeasurements.keys.toList()..sort();
  List refreshData = times
    .map((int time) => [time, refreshMeasurements[time].time])
    .toList();
  _updateRefreshChart(refreshData);
}

class Measurement {
  Measurement(this.map);

  final Map map;

  num get expected => map['expected'];
  num get issues => map['issues'];
  String get sdk => map['sdk'];
  num get time => map['time'];
  num get missingDartDocs => map['missingDartDocs'];
  num get timestampMillis => map['timestamp'];

  String get commit => map['commit'] is String ? map['commit'] : null;

  DateTime get date => new DateTime.fromMillisecondsSinceEpoch(timestampMillis);

  String get dateString {
    DateTime d = date;
    return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  }

  String toString() => '${time}s (${dateString})';
}

final List _analysisColumnSpecs = [
  new ChartColumnSpec(label: 'Time', type: ChartColumnSpec.TYPE_TIMESTAMP),
  new ChartColumnSpec(label: 'flutter_repo', type: ChartColumnSpec.TYPE_NUMBER, formatter: _printDurationValSeconds),
  new ChartColumnSpec(label: 'mega_gallery', type: ChartColumnSpec.TYPE_NUMBER, formatter: _printDurationValSeconds)
];

void _updateAnalysisChart([List data = const []]) {
  if (data == null || data.length < 2)
    data = _createPlaceholderData(<double>[0.0, 0.0]);

  if (analysisChartArea == null) {
    DivElement chartElement = document.querySelector('#analysis-perf-chart');
    DivElement legendHost = chartElement.querySelector('.chart-legend-host');
    ChartSeries series = new ChartSeries("Flutter Analysis Times", [1, 2], new LineChartRenderer());

    analysisChartArea = new CartesianArea(
      chartElement.querySelector('.chart-host'),
      null,
      _createChartConfig(legendHost, series)
    );
    analysisChartArea.addChartBehavior(new Hovercard(builder: (int columnIndex, int rowIndex) {
      List<int> data = analysisChartArea.data.rows.elementAt(rowIndex);
      ChartColumnSpec spec = analysisChartArea.data.columns.elementAt(columnIndex);
      Measurement measurement = (columnIndex == 1 ? repoMeasurements : galleryMeasurements)[data[0]];
      return _createTooltip(spec, measurement, unitsLabel: 's');
    }));
    analysisChartArea.addChartBehavior(new AxisLabelTooltip());
  }

  analysisChartArea.data = new ChartData(_analysisColumnSpecs, data);
  analysisChartArea.draw();
}

final List _dartdocColumnSpecs = [
  new ChartColumnSpec(label: 'Time', type: ChartColumnSpec.TYPE_TIMESTAMP),
  new ChartColumnSpec(label: 'Burndown', type: ChartColumnSpec.TYPE_NUMBER)
];

void _updateDartdocChart([List data]) {
  if (data == null || data.length < 2)
    data = _createPlaceholderData(<int>[0]);

  if (dartdocChartArea == null) {
    DivElement chartElement = document.querySelector('#documentation-chart');
    DivElement legendHost = chartElement.querySelector('.chart-legend-host');
    ChartSeries series = new ChartSeries('Dartdoc Burndown', [1], new LineChartRenderer());

    dartdocChartArea = new CartesianArea(
      chartElement.querySelector('.chart-host'),
      null,
      _createChartConfig(legendHost, series)
    );
    dartdocChartArea.addChartBehavior(new Hovercard(builder: (int columnIndex, int rowIndex) {
      List<int> data = dartdocChartArea.data.rows.elementAt(rowIndex);
      ChartColumnSpec spec = dartdocChartArea.data.columns.elementAt(columnIndex);
      Measurement measurement = repoMeasurements[data[0]];
      return _createTooltip(spec, measurement, value: measurement.missingDartDocs);
    }));
    dartdocChartArea.addChartBehavior(new AxisLabelTooltip());
  }

  dartdocChartArea.data = new ChartData(_dartdocColumnSpecs, data);
  dartdocChartArea.draw();
}

final List _refreshColumnSpecs = [
  new ChartColumnSpec(label: 'Time', type: ChartColumnSpec.TYPE_TIMESTAMP),
  new ChartColumnSpec(label: 'Refresh', type: ChartColumnSpec.TYPE_NUMBER, formatter: _printDurationValMillis)
];

void _updateRefreshChart([List data = const []]) {
  if (data == null || data.length < 2)
    data = _createPlaceholderData(<int>[0]);

  if (refreshChartArea == null) {
    DivElement chartElement = document.querySelector('#refresh-perf-chart');
    DivElement legendHost = chartElement.querySelector('.chart-legend-host');
    ChartSeries series = new ChartSeries("Edit Refresh Times", [1], new LineChartRenderer());

    refreshChartArea = new CartesianArea(
      chartElement.querySelector('.chart-host'),
      null,
      _createChartConfig(legendHost, series)
    );
    refreshChartArea.addChartBehavior(new Hovercard(builder: (int columnIndex, int rowIndex) {
      List<int> data = refreshChartArea.data.rows.elementAt(rowIndex);
      ChartColumnSpec spec = refreshChartArea.data.columns.elementAt(columnIndex);
      Measurement measurement = refreshMeasurements[data[0]];
      return _createTooltip(spec, measurement, unitsLabel: 'ms');
    }));
    refreshChartArea.addChartBehavior(new AxisLabelTooltip());
  }

  refreshChartArea.data = new ChartData(_refreshColumnSpecs, data);
  refreshChartArea.draw();
}

List<dynamic> _createPlaceholderData(List<dynamic> templateItems) {
  DateTime now = new DateTime.now();
  return [
    [now.subtract(new Duration(days: 30)).millisecondsSinceEpoch]..addAll(templateItems),
    [now.millisecondsSinceEpoch]..addAll(templateItems),
  ];
}

ChartConfig _createChartConfig(DivElement legendHost, ChartSeries series) {
  ChartConfig config = new ChartConfig([series], [0]);
  config.legend = new ChartLegend(legendHost);
  return config;
}

String _printDurationValSeconds(num val) {
  if (val == null) return '';
  return val.toStringAsFixed(1) + 's';
}

String _printDurationValMillis(num val) {
  if (val == null) return '';
  return _formatWithThousandsSeparator(val.toInt()) + 'ms';
}

Element _createTooltip(ChartColumnSpec spec, Measurement measurement, {
  dynamic value,
  String unitsLabel: ''
}) {
  Element element = div('', className: 'hovercard-single');

  if (measurement == null) {
    element.text = 'No data';
  } else {
    if (value == null)
      value = measurement.time;
    element.children.add(div(spec.label, className: 'hovercard-title'));
    element.children.add(div('$value$unitsLabel', className: 'hovercard-value'));
    element.children.add(div('${measurement.date}', className: 'hovercard-value'));
    if (measurement.commit != null)
      element.children.add(div('(commit ${measurement.commit.substring(0, 10)})', className: 'hovercard-value'));
  }

  return element;
}

DivElement div(String text, { String className }) {
  DivElement element = new DivElement()..text = text;
  if (className != null)
    element.className = className;
  return element;
}

String _formatWithThousandsSeparator(int value) {
  String str = value.toString();
  if (str.length > 3)
    str = str.substring(0, str.length - 3) + ',' + str.substring(str.length - 3);
  return str;
}
