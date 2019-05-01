// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'entities.dart';

class AuthenticationStatus {
  AuthenticationStatus(
    this.isAuthenticated,
    this.loginUrl,
    this.logoutUrl,
  );

  final bool isAuthenticated;
  final String loginUrl;
  final String logoutUrl;
}

class ApplicationService {
  static final _client = HttpClient();
  static const _root = 'https://flutter-dashboard.appspot.com/';
  static const _github = 'https://api.github.com';

  Future<AuthenticationStatus> fetchAuthenticationStatus() async {
    var url = Uri.parse('$_root/api/get-authentication-status');
    var status = await _getUrl(url);
    return AuthenticationStatus(
      status['Status'] == 'OK',
      status['LoginURL'],
      status['LogoutURL'],
    );
  }

  Future<GetBenchmarksResult> fetchBenchmarks() async {
    var url = Uri.parse('$_root/api/public/get-benchmarks');
    var result = await _getUrl(url);
    return GetBenchmarksResult.fromJson(result);
  }

  Future<bool> fetchBuildBroken() async {
    var url = Uri.parse('$_root/api/public/build-status');
    var result = await _getUrl(url);
    return result['AnticipatedBuildStatus'] == 'Build Will Fail';
  }

  Future<GetStatusResult> fetchBuildStatus() async {
    var url = Uri.parse('$_root/api/public/get-status');
    var result = await _getUrl(url);
    return GetStatusResult.fromJson(result);
  }

  Future<Map<String, Object>> fetchCommitInfo(String commit, String username, String token) async {
    var url = Uri.parse('$_github/repos/flutter/flutter/commits/$commit');
    var authorization = base64.encode('$username:$token'.codeUnits);
    return _getUrl(url, authorization: 'Basic $authorization');
  }

  Future<void> resetTask(String taskId) async {
    var url = Uri.parse('$_root/api/reset-devicelab-task');
    var request = await _client.postUrl(url);
    request.write(json.encode({
      'Key': taskId,
    }));
    var response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw Exception('${response.statusCode}');
    }
  }

  Future<Map<String, Object>> _getUrl(Uri url, {String authorization}) async {
    var request = await _client.getUrl(url);
    if (authorization != null) {
      request.headers.add(HttpHeaders.authorizationHeader, authorization);
    }
    var response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw Exception('${response.statusCode}');
    }
    var body = await response.transform(utf8.decoder).join('');
    return json.decode(body);
  }
}
