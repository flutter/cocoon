// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:mirrors';
import 'dart:typed_data';

import 'package:appengine/appengine.dart';
import 'package:appengine/appengine.dart' as gae show context;
import 'package:gcloud/db.dart';
import 'package:fixnum/fixnum.dart';
import 'package:meta/meta.dart';

import 'agent.dart';
import 'commit.dart';
import 'github_build_status_update.dart';
import 'key_helper.pb.dart';
import 'log_chunk.dart';
import 'task.dart';
import 'time_series.dart';
import 'time_series_value.dart';
import 'whitelisted_account.dart';

const Set<Type> _defaultTypes = <Type>{
  Agent,
  Commit,
  GithubBuildStatusUpdate,
  LogChunk,
  Task,
  TimeSeries,
  TimeSeriesValue,
  WhitelistedAccount,
};

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
    AppEngineContext applicationContext,
    Set<Type> types = _defaultTypes,
  })  : applicationContext =
            applicationContext ?? gae.context.applicationContext,
        types = _populateTypes(types);

  /// Metadata about the App Engine application.
  final AppEngineContext applicationContext;

  /// Maps Dart [Model] classes to their corresponding App Engine datastore
  /// type names.
  ///
  /// This is initialized when the [KeyHelper] is created by iterating over
  /// the `types` argument to the [new KeyHelper] constructor and looking for
  /// `@`[Kind] annotations on those classes.
  final Map<Type, Kind> types;

  /// Encodes the specified [key] as a base-64 encoded protocol buffer
  /// representation of the key.
  ///
  /// See also:
  ///
  ///  * <https://github.com/golang/appengine/blob/b2f4a3cf3c67576a2ee09e1fe62656a5086ce880/datastore/key.go#L231>
  String encode(Key key) {
    final Reference reference = Reference()
      ..app = applicationContext.applicationID
      ..path = _asPath(key);
    if (applicationContext.partition != null &&
        applicationContext.partition.isNotEmpty) {
      reference.nameSpace = applicationContext.partition;
    }
    final Uint8List buffer = reference.writeToBuffer();
    final String base64Encoded = base64Url.encode(buffer);
    return base64Encoded.split('=').first;
  }

  /// Decodes the specified [encoded] string into its [Key] representation.
  ///
  /// See also:
  ///
  ///  * [encode], which is the complement to this method.
  ///  * <https://github.com/golang/appengine/blob/b2f4a3cf3c67576a2ee09e1fe62656a5086ce880/datastore/key.go#L244>
  Key decode(String encoded) {
    // Re-add padding.
    final int remainder = encoded.length % 4;
    if (remainder != 0) {
      final String padding = '=' * (4 - remainder);
      encoded += padding;
    }

    final Uint8List decoded = base64Url.decode(encoded);
    final Reference reference = Reference.fromBuffer(decoded);
    return reference.path.element.fold<Key>(
      Key.emptyKey(
          Partition(reference.nameSpace.isEmpty ? null : reference.nameSpace)),
      (Key previous, Path_Element element) {
        final Iterable<MapEntry<Type, Kind>> entries = types.entries.where(
            (MapEntry<Type, Kind> entry) => entry.value.name == element.type);
        if (entries.isEmpty) {
          throw StateError('Unknown type: ${element.type}');
        }
        final MapEntry<Type, Kind> entry = entries.single;
        return previous.append(
          entry.key,
          id: entry.value.idType == IdType.String
              ? element.name
              : element.id.toInt(),
        );
      },
    );
  }

  static Map<Type, Kind> _populateTypes(Set<Type> types) {
    final Map<Type, Kind> result = <Type, Kind>{};

    for (Type type in types) {
      final ClassMirror classMirror = reflectClass(type);
      final List<InstanceMirror> kindAnnotations = classMirror.metadata
          .where((InstanceMirror annotation) => annotation.hasReflectee)
          .where((InstanceMirror annotation) =>
              annotation.reflectee.runtimeType == Kind)
          .toList();
      if (kindAnnotations.isEmpty) {
        throw StateError('Class $type has no @Kind annotation');
      }
      final Kind annotation = kindAnnotations.single.reflectee as Kind;
      result[type] = Kind(
        name: annotation.name ?? type.toString(),
        idType: annotation.idType ?? IdType.Integer,
      );
    }

    return Map<Type, Kind>.unmodifiable(result);
  }

  Path _asPath(Key key) {
    final List<Key> path = <Key>[];
    for (Key current = key;
        current != null && !current.isEmpty;
        current = current.parent) {
      path.insert(0, current);
    }
    return Path()
      ..element.addAll(path.map<Path_Element>((Key key) {
        final Path_Element element = Path_Element();
        if (key.type != null) {
          element.type = types.containsKey(key.type)
              ? types[key.type].name
              : key.type.toString();
        }
        final Object id = key.id;
        if (id is String) {
          element.name = id;
        } else if (id is int) {
          element.id = Int64(id);
        }
        return element;
      }));
  }
}
