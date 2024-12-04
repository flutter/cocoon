// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:googleapis/bigquery/v2.dart';

/// A fake bigquery tabledataresourceApi implementation.
///
/// This tabledataResourceApi considers only a simple case
/// where we focus on the number of rows inserted. This can be
/// easily extended for other test cases.
class FakeTabledataResource implements TabledataResource {
  List<TableDataInsertAllRequestRows>? rows;
  @override
  Future<TableDataInsertAllResponse> insertAll(
    TableDataInsertAllRequest request,
    String projectId,
    String datasetId,
    String tableId, {
    String? $fields,
  }) async {
    rows = request.rows;
    return TableDataInsertAllResponse.fromJson(<String, String>{});
  }

  @override
  Future<TableDataList> list(
    String projectId,
    String datasetId,
    String tableId, {
    // ignore: non_constant_identifier_names the name comes from the super method
    bool? formatOptions_useInt64Timestamp,
    int? maxResults,
    String? selectedFields,
    String? startIndex,
    String? pageToken,
    String? $fields,
  }) async {
    final List<Map<String, Object>> tableRowList = <Map<String, Object>>[];
    for (TableDataInsertAllRequestRows tableDataInsertAllRequestRows in rows!) {
      final dynamic value = tableDataInsertAllRequestRows.json;
      final List<Map<String, Object?>> tableCellList = <Map<String, Object?>>[];
      tableCellList.add(<String, Object?>{'v': value});
      tableRowList.add(<String, Object>{'f': tableCellList});
    }

    return TableDataList.fromJson(<String, Object>{'totalRows': rows!.length.toString(), 'rows': tableRowList});
  }
}
