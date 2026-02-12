// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;

class FakeAuthClient extends AutoRefreshingAuthClient {
  FakeAuthClient(this.baseClient);

  final http.Client baseClient;

  @override
  void close() => baseClient.close();

  @override
  Stream<AccessCredentials> get credentialUpdates => throw UnimplementedError();

  @override
  AccessCredentials get credentials => throw UnimplementedError();

  @override
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async => baseClient.delete(url, headers: headers, encoding: encoding);
  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async =>
      baseClient.get(url, headers: headers);

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) async =>
      baseClient.head(url, headers: headers);

  @override
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async =>
      baseClient.patch(url, headers: headers, body: body, encoding: encoding);

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async =>
      baseClient.post(url, headers: headers, body: body, encoding: encoding);

  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async =>
      baseClient.put(url, headers: headers, body: body, encoding: encoding);

  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) async =>
      baseClient.read(url, headers: headers);

  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) async =>
      baseClient.readBytes(url, headers: headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      baseClient.send(request);
}
