// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:googleapis/bigquery/v2.dart';

/// A fake bigquery tabledataresourceApi implementation.
///
/// This tabledataResourceApi considers only a simple case
/// where we focus on the number of rows inserted. This can be
/// easily extended for other test cases.
class FakeTabledataResourceApi implements TabledataResourceApi {
  int rows = 0;
  
  @override
  Future<TableDataInsertAllResponse> insertAll(
      TableDataInsertAllRequest request,
      String projectId,
      String datasetId,
      String tableId,
      {String $fields}) async {
    rows += request.rows.length;
    return TableDataInsertAllResponse.fromJson(<String, String>{});
  }

  @override
  Future<TableDataList> list(String projectId, String datasetId, String tableId,
      {int maxResults,
      String selectedFields,
      String startIndex,
      String pageToken,
      String $fields}) async {
    return TableDataList.fromJson(
        <String, String>{'totalRows': rows.toString()});
  }
}

