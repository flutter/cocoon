// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:mirrors';

import 'package:appengine/appengine.dart';
import 'package:appengine/appengine.dart' as gae show context;
import 'package:fixnum/fixnum.dart';
import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import 'allowed_account.dart';
import 'commit.dart';
import 'key_helper.pb.dart';
import 'task.dart';

const Set<Type> _defaultTypes = <Type>{Commit, Task, AllowedAccount};

/// Class used to encode and decode [Key] objects.
///
/// The encoding uses binary-encoded protocol buffers that are then base-64 URL
/// encoded (and the decoding reverses that process).
///
/// This encoding scheme is necessary to match the behavior of the Go AppEngine
/// datastore library. This parity is required while Cocoon operates with
/// two backends, because the serialized values vended by one backend must
/// be deserializable by the other backend.
@immutable
class KeyHelper {
  KeyHelper({
    AppEngineContext? applicationContext,
    Set<Type> types = _defaultTypes,
  }) : applicationContext =
           applicationContext ?? gae.context.applicationContext,
       types = _populateTypes(types);

  /// Metadata about the App Engine application.
  final AppEngineContext applicationContext;

  /// Maps Dart [Model] classes to their corresponding App Engine datastore
  /// type names.
  ///
  /// This is initialized when the [KeyHelper] is created by iterating over
  /// the `types` argument to the [KeyHelper.new] constructor and looking for
  /// `@`[Kind] annotations on those classes.
  final Map<Type, Kind> types;

  /// Encodes the specified [key] as a base-64 encoded protocol buffer
  /// representation of the key.
  ///
  /// See also:
  ///
  ///  * <https://github.com/golang/appengine/blob/b2f4a3cf3c67576a2ee09e1fe62656a5086ce880/datastore/key.go#L231>
  String encode(Key<dynamic> key) {
    final reference =
        Reference()
          ..app = applicationContext.applicationID
          ..path = _asPath(key);
    if (applicationContext.partition.isNotEmpty) {
      reference.nameSpace = applicationContext.partition;
    }
    final buffer = reference.writeToBuffer();
    final base64Encoded = base64Url.encode(buffer);
    return base64Encoded.split('=').first;
  }

  /// Decodes the specified [encoded] string into its [Key] representation.
  ///
  /// See also:
  ///
  ///  * [encode], which is the complement to this method.
  ///  * <https://github.com/golang/appengine/blob/b2f4a3cf3c67576a2ee09e1fe62656a5086ce880/datastore/key.go#L244>
  Key<dynamic> decode(String encoded) {
    // Re-add padding.
    final remainder = encoded.length % 4;
    if (remainder != 0) {
      final padding = '=' * (4 - remainder);
      encoded += padding;
    }

    final decoded = base64Url.decode(encoded);
    final reference = Reference.fromBuffer(decoded);
    return reference.path.element.fold<Key<dynamic>>(
      Key<int>.emptyKey(
        Partition(reference.nameSpace.isEmpty ? null : reference.nameSpace),
      ),
      (Key<dynamic> previous, Path_Element element) {
        final entries = types.entries.where(
          (MapEntry<Type, Kind> entry) => entry.value.name == element.type,
        );
        if (entries.isEmpty) {
          throw StateError('Unknown type: ${element.type}');
        }
        final entry = entries.single;
        if (entry.value.idType == IdType.String) {
          return previous.append<String>(entry.key, id: element.name);
        } else {
          return previous.append<int>(entry.key, id: element.id.toInt());
        }
      },
    );
  }

  static Map<Type, Kind> _populateTypes(Set<Type> types) {
    final result = <Type, Kind>{};

    for (var type in types) {
      final classMirror = reflectClass(type);
      final kindAnnotations =
          classMirror.metadata
              .where((InstanceMirror annotation) => annotation.hasReflectee)
              .where(
                (InstanceMirror annotation) =>
                    annotation.reflectee.runtimeType == Kind,
              )
              .toList();
      if (kindAnnotations.isEmpty) {
        throw StateError('Class $type has no @Kind annotation');
      }
      final annotation = kindAnnotations.single.reflectee as Kind;
      result[type] = Kind(
        name: annotation.name ?? type.toString(),
        idType: annotation.idType,
      );
    }

    return Map<Type, Kind>.unmodifiable(result);
  }

  Path _asPath(Key<dynamic> key) {
    final path = <Key<dynamic>>[];
    for (
      Key<dynamic>? current = key;
      current != null && !current.isEmpty;
      current = current.parent
    ) {
      path.insert(0, current);
    }
    return Path()
      ..element.addAll(
        path.map<Path_Element>((Key<dynamic> key) {
          final element = Path_Element();
          if (key.type != null) {
            element.type =
                types.containsKey(key.type)
                    ? types[key.type!]!.name!
                    : key.type.toString();
          }
          final Object? id = key.id;
          if (id is String) {
            element.name = id;
          } else if (id is int) {
            element.id = Int64(id);
          }
          return element;
        }),
      );
  }
}
