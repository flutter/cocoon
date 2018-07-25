// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'dart:math' as math;

import 'package:angular/angular.dart';
import 'package:cocoon/models.dart';

@Component(
  selector: 'benchmark-card',
  templateUrl: 'benchmark_card.html',
  directives: const [
    NgIf,
    NgFor,
    NgStyle,
  ],
)
class BenchmarkCard implements AfterViewInit, OnDestroy {
  /// The total height of the chart. This value must be in sync with the height
  /// specified for benchmark-card in benchmarks.css.
  static const int _kChartHeight = 100;
  final StreamController<void> _onZoomIn = new StreamController<void>();

  BenchmarkData _data;
  DivElement _tooltip;

  @ViewChild('chartContainer')
  DivElement chartContainer;

  @Input()
  String barWidth = 'medium';

  @Input()
  set data(BenchmarkData newData) {
    chartContainer.children.clear();
    _data = newData;
  }

  /// Emits an event when the user clicks on the zoom in button.
  @Output()
  Stream<void> get onZoomIn => _onZoomIn.stream;

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
    if (_data.values == null || _data.values.isEmpty)
      return null;

    TimeseriesValue timeseriesValue = _data.values.firstWhere(
      (TimeseriesValue value) => !value.isDataMissing,
      orElse: () => null,
    );

    if (timeseriesValue == null)
      return null;

    num value = timeseriesValue.value;
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

    chartContainer.children.add(
        new DivElement()
          ..classes.add('metric-goal')
          ..style.height = '${goalHeight}px'
    );

    chartContainer.children.add(
        new DivElement()
          ..classes.add('metric-baseline')
          ..style.height = '${baselineHeight}px'
    );

    for (TimeseriesValue value in _data.values.reversed) {
      // For missing values create a greyed out bar that takes the full height
      // of the chart.
      final double valueHeight = !value.isDataMissing
        ? _kChartHeight * value.value / maxValue
        : _kChartHeight;

      DivElement bar = new DivElement()
        ..classes.add('metric-value-bar')
        ..style.height = '${_kChartHeight - valueHeight}px'
        ..style.borderWidth = '0 0 ${valueHeight}px 0';

      if (barWidth == 'narrow')
        bar.classes.add('metric-value-bar-narrow');

      if (value.isDataMissing) {
        bar.classes.add('metric-value-bar-missing');
      } else if (value.value > baseline) {
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
        final String formattedValue = !value.isDataMissing
          ? '${value.value}$unit'
          : 'Value missing';

        tooltip.setInnerHtml(
          '${formattedValue}\n'
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

      chartContainer.children.add(bar);
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
