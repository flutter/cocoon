// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const String _jsonEndpoint = 'https://build.chromium.org/p/client.flutter/json';

/// Looks up the latest `git` commit SHA that succeeded both on Linux and Mac
/// buildbots.
Future<String> getLatestGreenRevision() async {
  BuilderClient linuxBuilder = new BuilderClient('Linux');
  BuilderClient macBuilder = new BuilderClient('Mac');
  List<int> linuxBuildNumbers = await linuxBuilder.listRecentBuilds();
  List<int> macBuildNumbers = await macBuilder.listRecentBuilds();
  Set<String> greenLinuxRevisions = new Set<String>();
  Set<String> greenMacRevisions = new Set<String>();

  // Keep fetching builds until we find a build that was green both on Mac
  // and Linux buildbots.
  while (greenLinuxRevisions.intersection(greenMacRevisions).isEmpty &&
      linuxBuildNumbers.isNotEmpty &&
      macBuildNumbers.isNotEmpty) {
    BuildInfo linuxBuild = await linuxBuilder.getBuild(linuxBuildNumbers.removeLast());
    if (linuxBuild.isGreen)
      greenLinuxRevisions.add(linuxBuild.revision);

    BuildInfo macBuild = await macBuilder.getBuild(macBuildNumbers.removeLast());
    if (macBuild.isGreen)
      greenMacRevisions.add(macBuild.revision);
  }

  Set<String> intersection = greenLinuxRevisions.intersection(greenMacRevisions);
  if (intersection.isEmpty) {
    // No builds that are green on both Mac and Linux
    return null;
  }

  return intersection.single;
}

class BuildInfo {
  BuildInfo(this.builderName, this.number, this.isGreen, this.revision);

  final String builderName;
  final int number;
  final bool isGreen;
  final String revision;
}

class BuilderClient {
  BuilderClient(this.builderName);

  final String builderName;

  String get builderUrl => '${_jsonEndpoint}/builders/$builderName';

  Future<BuildInfo> getBuild(int buildNumber) async {
    Map<String, dynamic> buildJson = await _getJson('$builderUrl/builds/$buildNumber');

    return new BuildInfo(
      builderName,
      buildNumber,
      _isGreen(buildJson),
      _getBuildProperty(buildJson, 'git_revision')
    );
  }

  Future<List<int>> listRecentBuilds() async {
    Map<String, dynamic> resp = await _getJson('$builderUrl/builds');
    return resp.keys.map(int.parse).toList();
  }
}

Future<dynamic> _getJson(String url) async {
  return JSON.decode((await http.get(url)).body);
}

/// Properties are encoded as:
///
///     {
///       "properties": [
///         [
///           "name1",
///           value1,
///           ... things we don't care about ...
///         ],
///         [
///           "name2",
///           value2,
///           ... things we don't care about ...
///         ]
///       ]
///     }
dynamic _getBuildProperty(Map<String, dynamic> buildJson, String propertyName) {
  List<List<dynamic>> properties = buildJson['properties'];
  for (List<dynamic> property in properties) {
    if (property[0] == propertyName)
      return property[1];
  }
  return null;
}

/// Parses out whether the build was successful.
///
/// Successes are encoded like this:
///
///     "text": [
///       "build",
///       "successful"
///     ]
///
/// Exceptions are encoded like this:
///
///     "text": [
///       "exception",
///       "steps",
///       "exception",
///       "flutter build apk material_gallery"
///     ]
///
/// Errors are encoded like this:
///
///     "text": [
///       "failed",
///       "steps",
///       "failed",
///       "flutter build ios simulator stocks"
///     ]
bool _isGreen(Map<String, dynamic> buildJson) {
  if (buildJson['text'] == null || buildJson['text'].length < 2) {
    stderr.writeln('WARNING: failed to parse "text" property out of build JSON');
    return false;
  }

  return buildJson['text'][1] == 'successful';
}
