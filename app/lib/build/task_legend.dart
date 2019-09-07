// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:angular/angular.dart';

/// A legend for the status table component.
@Component(
  selector: 'task-legend',
  templateUrl: 'task_legend.html',
  styleUrls: ['task_legend.css'],
  directives: [NgIf],
)
class TaskLegend extends ComponentState {
  bool legendVisible = false;

  void toggleVisibility() {
    legendVisible = !legendVisible;
  }
}
