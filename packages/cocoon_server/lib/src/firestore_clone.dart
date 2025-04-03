// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:googleapis/firestore/v1.dart' as g;
import 'package:meta/meta.dart';

/// Creates a shallow-ish clone of [other].
///
/// The underlying [g.Document.fields] has each key-value copied (meaning that
/// changes _to_ the Map istelf are not reflected), but the underlying [g.Value]
/// is not deep-copied, assuming that it is not mutated directly.
@internal
g.Document cloneFirestoreDocument(g.Document other, {String? name}) {
  return g.Document(
    name: name ?? other.name,
    fields: {...?other.fields},
    createTime: other.createTime,
    updateTime: other.updateTime,
  );
}
