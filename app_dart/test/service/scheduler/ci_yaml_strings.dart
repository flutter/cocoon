// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

const String otherBranchCiYaml = r'''
enabled_branches:
  - ios-experimental
targets:
  - name: Linux A
''';

const String singleCiYaml = r'''
enabled_branches:
  - master
  - main
  - flutter-\d+\.\d+-candidate\.\d+
targets:
  - name: Linux A
    properties:
      custom: abc
  - name: Linux B
    enabled_branches:
      - stable
    scheduler: luci
  - name: Linux runIf
    runIf:
      - .ci.yaml
      - DEPS
      - dev/**
      - engine/**
  - name: Google Internal Roll
    postsubmit: true
    presubmit: false
    scheduler: google_internal
''';

const String singleCiYamlWithLinuxAnalyze = r'''
enabled_branches:
  - master
  - main
  - flutter-\d+\.\d+-candidate\.\d+
targets:
  - name: Linux A
    properties:
      custom: abc
  - name: Linux B
    enabled_branches:
      - stable
    scheduler: luci
  - name: Linux runIf
    runIf:
      - .ci.yaml
      - DEPS
      - dev/**
      - engine/**
  - name: Linux analyze
''';

const String fusionCiYaml = r'''
enabled_branches:
  - master
  - main
  - codefu
  - flutter-\d+\.\d+-candidate\.\d+
targets:
  - name: Linux Z
    properties:
      custom: abc
  - name: Linux Y
    enabled_branches:
      - stable
    scheduler: luci
  - name: Linux engine_presubmit
  - name: Linux engine_build
    scheduler: luci
    properties:
      release_build: "true"
  - name: Linux runIf engine
    runIf:
      - DEPS
      - engine/src/flutter/.ci.yaml
      - engine/src/flutter/dev/**
''';

const String fusionDualCiYaml = r'''
enabled_branches:
  - master
  - main
  - codefu
  - flutter-\d+\.\d+-candidate\.\d+
targets:
  - name: Linux Z
    properties:
      custom: abc
  - name: Linux Y
    enabled_branches:
      - stable
    scheduler: luci
  - name: Linux engine_build
    scheduler: luci
    properties:
      release_build: "true"
  - name: Mac engine_build
    scheduler: luci
    properties:
      release_build: "true"
  - name: Linux runIf engine
    runIf:
      - DEPS
      - engine/src/flutter/.ci.yaml
      - engine/src/flutter/dev/**
''';
