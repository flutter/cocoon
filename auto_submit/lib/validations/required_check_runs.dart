// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Note that we need this file because Github does not expose a field within the
// checks that states whether or not a particular check is required or not.

const String ciyamlValidation = 'ci.yaml validation';

/// flutter, engine, cocoon, plugins, packages, buildroot and tests
const Map<String, List<String>> requiredCheckRunsMapping = {
  'flutter': [ciyamlValidation],
  'engine': [ciyamlValidation],
  'cocoon': [ciyamlValidation],
  'plugins': [ciyamlValidation],
  'packages': [ciyamlValidation],
  'buildroot': [ciyamlValidation],
  'tests': [ciyamlValidation],
};
