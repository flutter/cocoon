// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:cocoon/benchmark/benchmark_card.dart';
import 'package:cocoon/benchmark/benchmark_history.dart';
import 'package:cocoon/http.dart';
import 'package:cocoon/models.dart';
import 'package:http/http.dart' as http;

/// Checks if benchmark [data] satisfies some condition.
typedef bool _BenchmarkPredicate(BenchmarkData data);

@Component(
  selector: 'benchmark-grid',
  templateUrl: 'benchmark_grid.html',
  directives: const [
    NgIf,
    NgFor,
    NgClass,
    BenchmarkCard,
    BenchmarkHistory,
    formDirectives,
  ],
)
class BenchmarkGrid implements OnInit, OnDestroy {
  BenchmarkGrid(this._httpClient);

  final http.Client _httpClient;
  bool isLoading = true;
  List<BenchmarkData> _benchmarks;
  List<BenchmarkData> visibleBenchmarks;
  Timer _reloadTimer;
  bool _isShowArchived = false;
  bool _userIsAuthenticated = false;

  String _taskTextFilter;
  String get taskTextFilter => _taskTextFilter;
  set taskTextFilter(String value) {
    applyTextFilter(value);
  }

  bool get isShowArchived => _isShowArchived;

  bool get userIsAuthenticated => _userIsAuthenticated;

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
    reloadData(initialLoad: true);
    _reloadTimer =
        new Timer.periodic(const Duration(seconds: 30), (_) => reloadData());
    getAuthenticationStatus('/').then((AuthenticationStatus status) {
      _userIsAuthenticated = status.isAuthenticated;
    });
  }

  @override
  void ngOnDestroy() {
    _reloadTimer?.cancel();
  }

  Future<Null> reloadData({bool initialLoad: false}) async {
    isLoading = true;
    Map<String, dynamic> statusJson =
        json.decode((await _httpClient.get('/api/public/get-benchmarks')).body);
    _benchmarks = new GetBenchmarksResult.fromJson(statusJson).benchmarks;
    // Only query uri parameters when page loads for the first time
    if (initialLoad) {
      Map<String, String> parameters =
          Uri.parse(window.location.href).queryParameters;
      _taskTextFilter = parameters != null ? parameters['filter'] : null;
    }
    applyTextFilter(_taskTextFilter);
    isLoading = false;
  }

  void applyTextFilter(String newFilter) {
    _taskTextFilter = newFilter?.trim()?.toLowerCase();
    _applyFilters();
  }

  void _applyFilters() {
    if (_benchmarks == null) {
      visibleBenchmarks = <BenchmarkData>[];
      return;
    }

    List<_BenchmarkPredicate> filters = <_BenchmarkPredicate>[];
    if (_taskTextFilter != null && _taskTextFilter.trim().isNotEmpty) {
      filters.add((BenchmarkData data) {
        bool labelMatches = data?.timeseries?.timeseries?.label
                ?.toLowerCase()
                ?.contains(_taskTextFilter) ==
            true;
        bool taskNameMatches = data?.timeseries?.timeseries?.taskName
                ?.toLowerCase()
                ?.contains(_taskTextFilter) ==
            true;
        return labelMatches || taskNameMatches;
      });
    }
    if (!_isShowArchived) {
      filters.add((BenchmarkData data) =>
          !(data?.timeseries?.timeseries?.isArchived ?? true));
    }
    visibleBenchmarks = _benchmarks;
    for (_BenchmarkPredicate filter in filters) {
      visibleBenchmarks = visibleBenchmarks.where(filter).toList();
    }
  }
}
