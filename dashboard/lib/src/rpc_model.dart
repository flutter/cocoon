// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Storage agnostic data models that originate from the Cocoon backend.
///
/// This library contains models that are are deserialized from calls to
/// [CocoonService]. While they _may_ be created ephemerally within the app
/// itself, models that are UI-specific should live elsewhere (closer to the
/// widgets they define).
///
/// Every model in this library must:
/// 1. Be deeply [immutable], using unmodifiable collections where appropriate
/// 2. Not expose what backend store the model originates from (no primary keys)
/// 3. Use [JsonSerializable] to define `.fromJson` and `.toJson` functions
/// 4. Not depend on the Flutter SDK
///
/// To regenerate the JSON serialization code after making model changes:
/// ```sh
/// cd dashboard
/// dart run build_runner build
/// ```
///
/// @docImport 'package:json_annotation/json_annotation.dart';
/// @docImport 'package:meta/meta.dart';
/// @docImport '../service/cocoon.dart';
library;

export 'rpc_model/branch.dart' show Branch;
export 'rpc_model/build_status_response.dart'
    show
        BuildStatus, //
        BuildStatusResponse;
