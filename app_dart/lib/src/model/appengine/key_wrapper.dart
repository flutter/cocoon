// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fixnum/fixnum.dart';
import 'package:gcloud/db.dart';

import '../proto/protos.dart' as pb;

import 'key_helper.dart';

class KeyWrapper {
  const KeyWrapper(this.key) : assert(key != null);

  factory KeyWrapper.fromProto(pb.RootKey root) {
    Key<dynamic> result = Key<dynamic>.emptyKey(Partition(root.namespace));
    for (pb.Key key = root.child; key != null; key = key.child) {
      final Type type = _typeFromString(key.type);
      switch (key.whichId()) {
        case pb.Key_Id.uid:
          result = result.append<dynamic>(type, id: key.uid.toInt());
          break;
        case pb.Key_Id.name:
          result = result.append<dynamic>(type, id: key.name);
          break;
        case pb.Key_Id.notSet:
          result = result.append<dynamic>(type);
          break;
      }
    }

    return KeyWrapper(result);
  }

  final Key<dynamic> key;

  pb.RootKey toProto() {
    pb.Key previous;
    for (Key<dynamic> slice = key; slice != null; slice = key.parent) {
      final pb.Key current = pb.Key();
      if (slice.type != null) {
        current.type = slice.type.toString();
      }
      final Object id = slice.id;
      if (id is String) {
        current.name = id;
      } else if (id is int) {
        current.uid = Int64(id);
      }
      if (previous != null) {
        current.child = previous;
      }
      previous = current;

      if (slice.isEmpty) {
        return pb.RootKey()
          ..namespace = slice.partition.namespace
          ..child = previous;
      }
    }

    return pb.RootKey()..child = previous;
  }

  static Type _typeFromString(String value) {
    final KeyHelper keyHelper = KeyHelper();
    return keyHelper.types.keys.singleWhere((Type type) => type.toString() == value);
  }
}
