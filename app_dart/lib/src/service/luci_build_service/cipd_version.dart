// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Which LUCI Executable (e.g. recipe) to use.
///
/// See also: `exe_cipd_version` in [`class BuildbucketApi(RecipeApi`)](https://chromium.googlesource.com/infra/luci/recipes-py/+/HEAD/README.recipes.md#class-buildbucketapi_recipeapi).
@immutable
final class CipdVersion {
  const CipdVersion({required String branch}) : version = 'refs/heads/$branch';

  /// The default recipe to use
  static const defaultRecipe = CipdVersion(branch: 'main');

  /// The version string, in the format, `refs/head/{{branch}}`.
  final String version;

  @override
  int get hashCode => version.hashCode;

  @override
  bool operator ==(Object other) {
    return other is CipdVersion && other.version == version;
  }

  @override
  String toString() {
    return 'CipdVersion <$version>';
  }
}
