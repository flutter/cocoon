// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:yaml/yaml.dart';

import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../foundation/utils.dart';
import '../model/devicelab/manifest.dart';
import '../request_handling/exceptions.dart';

/// FileService loads and parses the content of a file to useful data structures, typically from a remote location.
class FileService {
  const FileService(
      {this.httpClientProvider = Providers.freshHttpClient, this.gitHubBackoffCalculator = twoSecondLinearBackoff});

  final HttpClientProvider httpClientProvider;
  final GitHubBackoffCalculator gitHubBackoffCalculator;

  /// Loads the devicelab manifest from the flutter/flutter repository at [sha] revision.
  /// Throws an HttpStatusException when GitHub doesn't respond.
  Future<Manifest> loadDevicelabManifest(String sha, Logging logger) async {
    final String path = '/flutter/flutter/$sha/dev/devicelab/manifest.yaml';
    final Uri url = Uri.https('raw.githubusercontent.com', path);

    final HttpClient client = httpClientProvider();
    try {
      for (int attempt = 0; attempt < 3; attempt++) {
        final HttpClientRequest clientRequest = await client.getUrl(url);

        try {
          final HttpClientResponse clientResponse = await clientRequest.close();
          final int status = clientResponse.statusCode;

          if (status == HttpStatus.ok) {
            final String content = await utf8.decoder.bind(clientResponse).join();
            return Manifest.fromJson(loadYaml(content) as YamlMap);
          } else {
            logger.warning('Attempt to download manifest.yaml failed (HTTP $status)');
          }
        } catch (error, stackTrace) {
          logger.error('Attempt to download manifest.yaml failed:\n$error\n$stackTrace');
        }

        await Future<void>.delayed(gitHubBackoffCalculator(attempt));
      }
    } finally {
      client.close(force: true);
    }

    logger.error('GitHub not responding; giving up');
    throw const HttpStatusException(HttpStatus.serviceUnavailable, 'GitHub not responding');
  }
}
