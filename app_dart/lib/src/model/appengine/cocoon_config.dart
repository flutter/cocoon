// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';

@Kind(name: 'CocoonConfig', idType: IdType.String)
class CocoonConfig extends Model<String> {
  CocoonConfig();

  /// Helper function only for local and test environments.
  CocoonConfig.fake(Key<String>? key, this.value) {
    parentKey = key?.parent;
    id = key?.id;
  }

  @StringProperty(propertyName: 'ParameterValue')
  late String value;
}
