// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon/models.dart';

class HeaderRow {
  List<StageHeader> stageHeaders = <StageHeader>[];

  void addStage(Stage stage) {
    StageHeader header = stageHeaders
        .firstWhere((StageHeader h) => h.stageName == stage.name, orElse: () {
      StageHeader newHeader = new StageHeader(stage.name);
      stageHeaders.add(newHeader);
      return newHeader;
    });
    for (TaskEntity taskEntity in stage.tasks) {
      header.addMetaTask(taskEntity);
    }
    stageHeaders.sort((StageHeader a, StageHeader b) {
      const stagePrecedence = const <String>[
        "cirrus",
        "chromebot",
        "devicelab",
        "devicelab_win",
        "devicelab_ios",
        "appveyor", // deprecated.
        "travis", // deprecated.
      ];

      int aIdx = stagePrecedence.indexOf(a.stageName);
      aIdx = aIdx == -1 ? 1000000 : aIdx;
      int bIdx = stagePrecedence.indexOf(b.stageName);
      bIdx = bIdx == -1 ? 1000000 : bIdx;
      return aIdx.compareTo(bIdx);
    });
  }

  List<MetaTask> get allMetaTasks =>
      stageHeaders.fold(<MetaTask>[], (List<MetaTask> prev, StageHeader h) {
        return prev..addAll(h.metaTasks);
      });
}

class StageHeader {
  StageHeader(this.stageName);

  final String stageName;
  final List<MetaTask> metaTasks = <MetaTask>[];

  void addMetaTask(TaskEntity taskEntity) {
    Task task = taskEntity.task;
    if (metaTasks.any((MetaTask m) => m.name == task.name)) return;
    metaTasks.add(new MetaTask(taskEntity.key, task.name, task.stageName));
    metaTasks.sort((MetaTask m1, MetaTask m2) {
      return m1.name.compareTo(m2.name);
    });
  }
}

/// Information about a task without a result.
class MetaTask {
  MetaTask(this.key, this.name, String stageName)
      : this.stageName = stageName,
        iconUrl = _iconForStageName(stageName);

  final String key;
  final String name;
  final String stageName;
  final String iconUrl;
}

String _iconForStageName(String stageName) {
  const Map<String, String> iconMap = const <String, String>{
    'cirrus': 'assets/cirrus.svg',
    'travis': 'assets/travis.svg',
    'appveyor': 'assets/appveyor.png',
    'chromebot': 'assets/chromium.svg',
    'devicelab': 'assets/android.svg',
    'devicelab_ios': 'assets/apple.svg',
    'devicelab_win': 'assets/windows.svg',
  };
  return iconMap[stageName];
}

class Color {
  const Color(this.r, this.g, this.b);

  final int r, g, b;

  /// A 6-digit hex CSS string representation of the color.
  String get cssHex => '#${_cHex(r)}${_cHex(g)}${_cHex(b)}';

  /// Prints a single color [component] to a 2-digit hex string.
  static String _cHex(int component) =>
      component.toRadixString(16).padLeft(2, '0');

  /// Linear interpolation between two colors [from] and [to] with coefficient
  /// [c].
  static Color lerp(Color from, Color to, double c) => new Color(
        (from.r + (to.r - from.r) * c).toInt(),
        (from.g + (to.g - from.g) * c).toInt(),
        (from.b + (to.b - from.b) * c).toInt(),
      );
}
