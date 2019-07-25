// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';

import 'request_handler.dart';

/// A [RequestHandler] that acts as a proxy for another backend.
///
/// All requests handled by this request handler will be forwarded (unmodified)
/// to the specified backend.
@immutable
class ProxyRequestHandler extends RequestHandler {
  /// Creates a new [ProxyRequestHandler].
  const ProxyRequestHandler({
    @required Config config,
    @required this.scheme,
    @required this.host,
    @required this.port,
  })  : assert(scheme != null),
        assert(host != null),
        assert(port != null),
        super(config: config);

  /// The URI scheme to use when forwarding requests (e.g. 'https').
  final String scheme;

  /// The host to use when forwarding requests.
  final String host;

  /// The port to use when forwarding requests (e.g. 443 for HTTPS).
  final int port;

  @override
  Future<void> service(HttpRequest request) async {
    HttpClient httpClient = HttpClient();
    Uri forwardUri = request.uri.replace(scheme: scheme, host: host, port: port);
    HttpClientRequest clientRequest = await httpClient.openUrl(request.method, forwardUri);
    clientRequest.followRedirects = false;
    _transferHttpHeaders(from: request.headers, to: clientRequest.headers);
    await request.cast<List<int>>().pipe(clientRequest);
    await clientRequest.flush();
    HttpClientResponse clientResponse = await clientRequest.close();
    HttpResponse response = request.response;
    response.statusCode = clientResponse.statusCode;
    _transferHttpHeaders(from: clientResponse.headers, to: response.headers);
    await clientResponse.pipe(response);
    await response.flush();
    await response.close();
  }

  void _transferHttpHeaders({@required HttpHeaders from, @required HttpHeaders to}) {
    to.clear();
    from.forEach((String name, List<String> values) {
      for (String value in values) {
        to.add(name, value);
      }
    });
  }
}
