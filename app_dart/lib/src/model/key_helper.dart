// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import 'dart:mirrors';

import 'package:appengine/appengine.dart';
import 'package:appengine/appengine.dart' as gae show context;
import 'package:gcloud/db.dart';
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'agent.dart';
import 'commit.dart';
import 'key_helper.pb.dart';
import 'task.dart';
import 'whitelisted_account.dart';

const Set<Type> _defaultTypes = <Type>{
  Agent,
  Commit,
  Task,
  WhitelistedAccount,
};

@immutable
class KeyHelper {
  KeyHelper({
    @required this.applicationContext,
    Set<Type> types = _defaultTypes,
  }) : this.types = _populateTypes(types);

  final AppEngineContext applicationContext;
  final Map<Type, Kind> types;

  String encode(Key key) {
    Reference reference = Reference()
      ..app = applicationContext.applicationID
      ..path = _asPath(key);
    if (applicationContext.partition != null && applicationContext.partition.isNotEmpty) {
      reference.nameSpace = applicationContext.partition;
    }
    Uint8List buffer = reference.writeToBuffer();
    String base64Encoded = base64Url.encode(buffer);
    return base64Encoded.split('=').first;
  }

  Key decode(String encoded) {
    // Re-add padding.
    int remainder = encoded.length % 4;
    if (remainder != 0) {
      String padding = '=' * (4 - remainder);
      encoded += padding;
    }

    Uint8List decoded = base64Url.decode(encoded);
    Reference reference = Reference.fromBuffer(decoded);
    String namespace = reference.nameSpace?.isEmpty ?? true ? null : reference.nameSpace;
    return reference.path.element.fold<Key>(
      Key.emptyKey(Partition(namespace)),
      (Key previous, Path_Element element) {
        Iterable<MapEntry<Type, Kind>> entries =
            types.entries.where((MapEntry<Type, Kind> entry) => entry.value.name == element.type);
        if (entries.isEmpty) {
          throw StateError('Unknown type: ${element.type}');
        }
        return previous.append(entries.single.key, id: element.name);
      },
    );
  }

  static Map<Type, Kind> _populateTypes(Set<Type> types) {
    Map<Type, Kind> result = <Type, Kind>{};

    for (Type type in types) {
      ClassMirror classMirror = reflectClass(type);
      List<InstanceMirror> kindAnnotations = classMirror.metadata
          .where((InstanceMirror annotation) => annotation.hasReflectee)
          .where((InstanceMirror annotation) => annotation.reflectee.runtimeType == Kind)
          .toList();
      if (kindAnnotations.isEmpty) {
        throw StateError('Class $type has no @Kind annotation');
      }
      Kind annotation = kindAnnotations.single.reflectee;
      result[type] = Kind(
        name: annotation.name ?? type.toString(),
        idType: annotation.idType ?? IdType.Integer,
      );
    }

    return Map<Type, Kind>.unmodifiable(result);
  }

  Path _asPath(Key key) {
    List<Key> path = <Key>[];
    for (Key current = key; current != null && !current.isEmpty; current = current.parent) {
      path.insert(0, current);
    }
    return Path()
      ..element.addAll(path.map<Path_Element>((Key key) {
        Path_Element element = Path_Element();
        if (key.type != null) {
          element.type = types.containsKey(key.type) ? types[key.type].name : key.type.toString();
        }
        if (key.id != null) {
          if (key.id is String) {
            element.name = key.id;
          } else if (key.id is int) {
            element.id = Int64(key.id);
          }
        }
        return element;
      }));
  }
}

const KeyConverter convertedByKeyHelper = const KeyConverter();

class KeyConverter implements JsonConverter<Key, String> {
  const KeyConverter();

  @override
  Key fromJson(String json) {
    KeyHelper helper = KeyHelper(applicationContext: gae.context.applicationContext);
    return helper.decode(json);
  }

  @override
  String toJson(Key key) {
    KeyHelper helper = KeyHelper(applicationContext: gae.context.applicationContext);
    return helper.encode(key);
  }
}
