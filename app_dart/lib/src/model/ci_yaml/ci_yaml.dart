// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';

import '../proto/internal/scheduler.pb.dart' as pb;
import 'target.dart';

///
///
/// This is a wrapper class around the underlying protos.
///
/// See //CI_YAML.md for high level documentation.
class CiYaml {
  CiYaml(this.config, this.slug);

  final pb.SchedulerConfig config;

  final RepositorySlug slug;

  List<Target> getPresubmitTargets() {
    
  }

  List<Target> get _targets => config.targets
      .map((pb.Target target) => Target(
            schedulerConfig: config,
            value: target,
            slug: slug,
          ))
      .toList();
}
