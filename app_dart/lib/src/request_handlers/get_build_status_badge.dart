// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:cocoon_common/rpc_model.dart' as rpc_model;
import 'package:meta/meta.dart';

import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import 'get_build_status.dart';

/// [GetBuildStatusBadge] returns an SVG representing the current tree status for the given repo.
///
/// It reuses [GetBuildStatus] and translates it to the SVG. The primary caller for this is the
/// README's from the larger Flutter repositories.
final class GetBuildStatusBadge extends GetBuildStatus {
  const GetBuildStatusBadge({
    required super.config,
    required super.buildStatusService,
  });

  /// Provides a template that is easily injectable.
  ///
  /// Template follows the mustache format of `{{ VARIABLE }}`.
  final String template =
      '''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="150" height="20" role="img" aria-label="Flutter CI: {{ STATUS }}">
  <title>Flutter CI: {{ STATUS }}</title>
  <linearGradient id="s" x2="0" y2="100%">
    <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
    <stop offset="1" stop-opacity=".1"/></linearGradient>
    <clipPath id="r"><rect width="150" height="20" rx="3" fill="#fff"/></clipPath>
    <g clip-path="url(#r)">
    <rect width="80" height="20" fill="#555"/>
    <rect x="80" width="107" height="20" fill="{{ COLOR }}"/>
    <rect width="238" height="20" fill="url(#s)"/></g>
    <g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" text-rendering="geometricPrecision" font-size="110">
    <text x="380" y="140" transform="scale(.1)" fill="#fff" textLength="600">Flutter CI</text>
    <text x="1125" y="140" transform="scale(.1)" fill="#fff" textLength="550">{{ STATUS }}</text></g>
  </svg>''';

  static const red = '#e05d44';
  static const green = '#3BB143';

  @override
  Future<Body> get(Request request) async {
    return Body.forString(
      generateSVG(await super.createResponse(request)),
      contentType: _imageSvgXml,
    );
  }

  static final _imageSvgXml = ContentType.parse('image/svg+xml');

  @visibleForTesting
  String generateSVG(rpc_model.BuildStatusResponse response) {
    final passing = response.failingTasks.isEmpty;
    return template
        .replaceAll(
          '{{ STATUS }}',
          passing ? 'passing' : '${response.failingTasks.length} failures',
        )
        .replaceAll('{{ COLOR }}', passing ? green : red);
  }
}
