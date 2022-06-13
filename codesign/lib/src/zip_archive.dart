// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:codesign/codesign.dart';
import 'package:file/file.dart';

/// A zip file that contains files that must be codesigned.
abstract class ZipArchive extends ArchiveFile {
  ZipArchive({
    this.files,
    required String path,
  }) : super(path: path);

  final List<ArchiveFile>? files;
}

/// A zip file that must be downloaded then extracted.
///
/// This is the entry point of a recursive visit.
class RemoteZip {
  RemoteZip({
    required this.path,
  });

  final String path;

  Future<void> visit(FileVisitor visitor, Directory parent) {
    return visitor.visitRemoteZip(this, parent);
  }
}

class EmbeddedZip extends ZipArchive {
  EmbeddedZip({
    required super.path,
  });

  @override
  Future<void> visit(FileVisitor visitor, String parent, String entitlementParentPath) {
    return visitor.visitEmbeddedZip(this, parent, entitlementParentPath);
  }
}

abstract class ArchiveFile {
  const ArchiveFile({
    required this.path,
  });

  final String path;

  Future<void> visit(FileVisitor visitor, String parent, String entitlementParentPath);
}

class BinaryFile extends ArchiveFile {
  const BinaryFile({
    this.entitlements = false,
    required super.path,
  });

  final bool entitlements;

  @override
  Future<void> visit(FileVisitor visitor, String parent, String entitlementParentPath) {
    return visitor.visitBinaryFile(this, entitlementParentPath);
  }
}
