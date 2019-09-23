// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/protos.dart' show CommitStatus;
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'cocoon.dart';

class AppEngineCocoonService implements CocoonService {
  /// The Cocoon API endpoint to query
  static const baseApiUrl = 'https://flutter-dashboard.appspot.com/api';

  @override
  Future<List<CommitStatus>> getStats() async {
    var response = await http.get('$baseApiUrl/public/get-status');

    List<CommitStatus> statuses = List();

    List<dynamic> responsePiece = jsonDecode(response.body);
    responsePiece.map((piece) => statuses.add(CommitStatus.fromJson(piece)));

    return statuses;
  }
}
