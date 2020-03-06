// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:meta/meta.dart';

import '../model/luci/buildbucket.dart';
import '../request_handling/body.dart';
import 'access_token_provider.dart';

/// A client interface to LUCI BuildBucket
@immutable
class BuildBucketClient {
  /// Creates a new build bucket Client.
  ///
  /// The [buildBucketUri] parameter must not be null, and will be defaulted to
  /// [kDefaultBuildBucketUri] if not specified.
  ///
  /// The [httpClient] parameter will be defaulted to `HttpClient()` if not
  /// specified or null.
  BuildBucketClient({
    this.buildBucketUri = kDefaultBuildBucketUri,
    this.accessTokenProvider,
    HttpClient httpClient,
  })  : assert(buildBucketUri != null),
        httpClient = httpClient ?? HttpClient();

  /// Garbage to prevent browser/JSON parsing exploits.
  static const String kRpcResponseGarbage = ")]}'";

  /// The default endpoint for BuildBucket requests.
  static const String kDefaultBuildBucketUri =
      'https://cr-buildbucket.appspot.com/prpc/buildbucket.v2.Builds';

  /// The base URI for build bucket requests.
  ///
  /// Defaults to [kDefaultBuildBucketUri].
  final String buildBucketUri;

  /// The token provider for OAuth2 requests.
  ///
  /// If this is non-null, an access token will be attached to any outbound
  /// HTTP requests issued by this client.
  final AccessTokenProvider accessTokenProvider;

  /// The [HttpClient] to use for requests.
  ///
  /// Defaults to `HttpClient()`.
  final HttpClient httpClient;

  Future<T> _postRequest<S extends JsonBody, T>(
    String path,
    S request,
    T responseFromJson(Map<String, dynamic> rawResponse),
  ) async {
    final Uri url = Uri.parse('$buildBucketUri$path');
    final HttpClientRequest httpRequest = await httpClient.postUrl(url);

    httpRequest.headers.add(HttpHeaders.contentTypeHeader, 'application/json');
    httpRequest.headers.add(HttpHeaders.acceptHeader, 'application/json');

    if (accessTokenProvider != null) {
      final AccessToken token = await accessTokenProvider.createAccessToken(
        scopes: <String>[
          'openid',
          'https://www.googleapis.com/auth/userinfo.profile',
          'https://www.googleapis.com/auth/userinfo.email',
        ],
      );
      if (token != null) {
        httpRequest.headers.add(
            HttpHeaders.authorizationHeader, '${token.type} ${token.data}');
      }
    }

    httpRequest.write(json.encode(request.toJson()));
    await httpRequest.flush();
    final HttpClientResponse response = await httpRequest.close();

    final String rawResponse = await utf8.decodeStream(response);
    if (response.statusCode < 300) {
      return responseFromJson(
          json.decode(rawResponse.substring(kRpcResponseGarbage.length))
              as Map<String, dynamic>);
    }
    throw BuildBucketException(response.statusCode, rawResponse);
  }

  /// The RPC request to schedule a build.
  Future<Build> scheduleBuild(ScheduleBuildRequest request) {
    return _postRequest<ScheduleBuildRequest, Build>(
      '/ScheduleBuild',
      request,
      Build.fromJson,
    );
  }

  /// The RPC request to search for builds.
  Future<SearchBuildsResponse> searchBuilds(SearchBuildsRequest request) {
    return _postRequest<SearchBuildsRequest, SearchBuildsResponse>(
      '/SearchBuilds',
      request,
      SearchBuildsResponse.fromJson,
    );
  }

  /// The RPC method to batch multiple RPC methods in a single HTTP request.
  ///
  /// The response is guaranteed to contain line-item responses for all
  /// line-item requests that were issued in [request]. If only a subset of
  /// responses were retrieved, a [BatchRequestException] will be thrown.
  Future<BatchResponse> batch(BatchRequest request) async {
    final BatchResponse response =
        await _postRequest<BatchRequest, BatchResponse>(
      '/Batch',
      request,
      BatchResponse.fromJson,
    );
    if (response.responses.length != request.requests.length) {
      throw BatchRequestException('Failed to execute all requests');
    }
    return response;
  }

  /// The RPC request to cancel a build.
  Future<Build> cancelBuild(CancelBuildRequest request) {
    return _postRequest<CancelBuildRequest, Build>(
      '/CancelBuild',
      request,
      Build.fromJson,
    );
  }

  /// The RPC request to get details about a build.
  Future<Build> getBuild(GetBuildRequest request) {
    return _postRequest<GetBuildRequest, Build>(
      '/GetBuild',
      request,
      Build.fromJson,
    );
  }

  /// Closes the underlying [HttpClient].
  ///
  /// If `force` is true, it will close immediately and cause outstanding
  /// requests to end with an error. Otherwise, it will wait for outstanding
  /// requests to finish before closing.
  ///
  /// Once this call completes, additional RPC requests will throw an exception.
  void close({bool force = false}) {
    httpClient.close(force: force);
  }
}

class BuildBucketException implements Exception {
  const BuildBucketException(this.statusCode, this.message);

  /// The HTTP status code of the error.
  final int statusCode;

  /// The message from the server.
  final String message;

  @override
  String toString() => '$runtimeType: [$statusCode]: $message';
}

class BatchRequestException implements Exception {
  BatchRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}
