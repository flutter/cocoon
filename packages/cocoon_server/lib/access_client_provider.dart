// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:http/http.dart';

/// Creates a Firestore base client for none (default) database.
///
/// A default header is required for none (default) Firestore API calls.
/// Both `project_id` and `database_id` are required.
///
/// https://firebase.google.com/docs/firestore/manage-databases#access_a_named_database_with_a_client_library
class FirestoreBaseClient extends BaseClient {
  FirestoreBaseClient({required this.projectId, required this.databaseId});
  final String databaseId;
  final String projectId;
  final Client client = Client();
  @override
  Future<StreamedResponse> send(BaseRequest request) {
    final defaultHeaders = <String, String>{
      'x-goog-request-params': 'project_id=$projectId&database_id=$databaseId',
    };
    request.headers.addAll(defaultHeaders);
    return client.send(request);
  }
}
