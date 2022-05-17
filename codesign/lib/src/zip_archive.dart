// Copyright 2021 The Flutter Authors. All rights reserved.
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
class RemoteZip {//extends ZipArchive {
  RemoteZip({
    required this.path,
  });

  final String path;

  Future<void> visit(FileVisitor visitor, Directory parent) {
    return visitor.visitRemoteZip(this, parent);
  }

  static Map<String, RemoteZip> pathToRemoteZip(){
    Map<String, RemoteZip> pathToZip = <String, RemoteZip>{};

    // Android artifacts mappings
    for (final String arch in <String>['arm', 'arm64', 'x64']){
      for (final String buildMode in <String>['release', 'profile']){
        String path = 'android-$arch-$buildMode/darwin-x64.zip';
        pathToZip[path] = RemoteZip(
          path: 'android-$arch-$buildMode/darwin-x64.zip',
          // files: const <BinaryFile>[
          //   BinaryFile(path: 'gen_snapshot', entitlements: true),
          // ],
        );
      }
    }
    // macOS Dart SDK
    for (final String arch in <String>['arm64', 'x64']){
      String path = 'dart-sdk-darwin-$arch.zip';
      pathToZip[path] = RemoteZip(
        path: 'dart-sdk-darwin-$arch.zip',
        // files: const <BinaryFile>[
        //   BinaryFile(path: 'dart-sdk/bin/dart', entitlements: true),
        //   BinaryFile(path: 'dart-sdk/bin/dartaotruntime', entitlements: true),
        //   BinaryFile(path: 'dart-sdk/bin/utils/gen_snapshot', entitlements: true),
        // ],
      );
    }
    // macOS host debug artifacts
    String path = 'darwin-x64/artifacts.zip';
    pathToZip[path] = RemoteZip(
      path: 'darwin-x64/artifacts.zip',
      // files: <BinaryFile>[
      //   BinaryFile(path: 'flutter_tester', entitlements: true),
      //   BinaryFile(path: 'gen_snapshot', entitlements: true),
      //   BinaryFile(path: 'impellerc', entitlements: true),
      //   BinaryFile(path: 'libtessellator.dylib', entitlements: true),
      // ],
    );
    // macOS host profile and release artifacts
    for (final String buildMode in <String>['profile', 'release']){
      String path = 'darwin-x64-$buildMode/artifacts.zip';
      pathToZip[path] = RemoteZip(
        path: 'darwin-x64-$buildMode/artifacts.zip',
        // files: const <BinaryFile>[
        //   BinaryFile(path: 'gen_snapshot', entitlements: true),
        // ],
      );
    }
    path = 'darwin-x64/font-subset.zip';
    pathToZip[path] = RemoteZip(
      path: 'darwin-x64/font-subset.zip',
      //files: <BinaryFile>[BinaryFile(path: 'font-subset')],
    );
    // macOS desktop Framework
    for (final String buildModeSuffix in <String>['', '-profile', '-release']){
      path = 'darwin-x64$buildModeSuffix/FlutterMacOS.framework.zip';
      pathToZip[path] = RemoteZip(
        path: 'darwin-x64$buildModeSuffix/FlutterMacOS.framework.zip',
        // files: <ArchiveFile>[
        //   EmbeddedZip(
        //     path: 'FlutterMacOS.framework.zip',
        //     //files: <BinaryFile>[BinaryFile(path: 'Versions/A/FlutterMacOS')]
        //   ),
        // ],
      );
    }
    // ios artifacts
    for (final String buildModeSuffix in <String>['', '-profile', '-release']){
      path = 'ios$buildModeSuffix/artifacts.zip';
      pathToZip[path] = RemoteZip(
        path: 'ios$buildModeSuffix/artifacts.zip',
        // files: const <ArchiveFile>[
        //   BinaryFile(path: 'gen_snapshot_arm64', entitlements: true),
        //   BinaryFile(path: 'Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework/Flutter'),
        //   BinaryFile(path: 'Flutter.xcframework/ios-arm64/Flutter.framework/Flutter'),
        // ],
      );
    }
    return pathToZip;
  }

  /// The [List] of all archives on cloud storage that contain binaries that
  /// must be codesigned.
  static List<RemoteZip> archives = <RemoteZip>[
    // Android artifacts
    for (final String arch in <String>['arm', 'arm64', 'x64'])
      for (final String buildMode in <String>['release', 'profile'])
        RemoteZip(
          path: 'android-$arch-$buildMode/darwin-x64.zip',
          // files: const <BinaryFile>[
          //   BinaryFile(path: 'gen_snapshot', entitlements: true),
          // ],
        ),
    // macOS Dart SDK
    for (final String arch in <String>['arm64', 'x64'])
      RemoteZip(
        path: 'dart-sdk-darwin-$arch.zip',
        // files: const <BinaryFile>[
        //   BinaryFile(path: 'dart-sdk/bin/dart', entitlements: true),
        //   BinaryFile(path: 'dart-sdk/bin/dartaotruntime', entitlements: true),
        //   BinaryFile(path: 'dart-sdk/bin/utils/gen_snapshot', entitlements: true),
        // ],
      ),
    // macOS host debug artifacts
    RemoteZip(
      path: 'darwin-x64/artifacts.zip',
      // files: <BinaryFile>[
      //   BinaryFile(path: 'flutter_tester', entitlements: true),
      //   BinaryFile(path: 'gen_snapshot', entitlements: true),
      //   BinaryFile(path: 'impellerc', entitlements: true),
      //   BinaryFile(path: 'libtessellator.dylib', entitlements: true),
      // ],
    ),
    // macOS host profile and release artifacts
    for (final String buildMode in <String>['profile', 'release'])
      RemoteZip(
        path: 'darwin-x64-$buildMode/artifacts.zip',
        // files: const <BinaryFile>[
        //   BinaryFile(path: 'gen_snapshot', entitlements: true),
        // ],
      ),
    RemoteZip(
      path: 'darwin-x64/font-subset.zip',
      //files: <BinaryFile>[BinaryFile(path: 'font-subset')],
    ),

    // macOS desktop Framework
    for (final String buildModeSuffix in <String>['', '-profile', '-release'])
      RemoteZip(
        path: 'darwin-x64$buildModeSuffix/FlutterMacOS.framework.zip',
        // files: <ArchiveFile>[
        //   EmbeddedZip(
        //     path: 'FlutterMacOS.framework.zip',
        //     //files: <BinaryFile>[BinaryFile(path: 'Versions/A/FlutterMacOS')]
        //   ),
        // ],
      ),

    // ios artifacts
    for (final String buildModeSuffix in <String>['', '-profile', '-release'])
      RemoteZip(
        path: 'ios$buildModeSuffix/artifacts.zip',
        // files: const <ArchiveFile>[
        //   BinaryFile(path: 'gen_snapshot_arm64', entitlements: true),
        //   BinaryFile(path: 'Flutter.xcframework/ios-arm64_x86_64-simulator/Flutter.framework/Flutter'),
        //   BinaryFile(path: 'Flutter.xcframework/ios-arm64/Flutter.framework/Flutter'),
        // ],
      ),
  ];
}


class EmbeddedZip extends ZipArchive {
  EmbeddedZip({
    required super.path,
  });

  @override
  Future<void> visit(FileVisitor visitor, String parent) {
    return visitor.visitEmbeddedZip(this, parent);
  }
}

abstract class ArchiveFile {
  const ArchiveFile({
    required this.path,
  });

  final String path;

  Future<void> visit(FileVisitor visitor, String parent);
}

class BinaryFile extends ArchiveFile {
  const BinaryFile({
    this.entitlements = false,
    required super.path,
  });

  final bool entitlements;

  @override
  Future<void> visit(FileVisitor visitor, String parent) {
    return visitor.visitBinaryFile(this, parent);
  }
}