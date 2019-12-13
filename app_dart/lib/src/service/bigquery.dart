import 'dart:async';

import 'package:googleapis/bigquery/v2.dart';
import 'package:http/http.dart';

import 'access_client_provider.dart';

class BigqueryService {
  const BigqueryService(this.accessClientProvider)
      : assert(accessClientProvider != null);

  /// AccessClientProvider for OAuth 2.0 authenticated access client
  final AccessClientProvider accessClientProvider;

  /// Return a [TabledataResourceApi] with an authenticated [client]
  Future<TabledataResourceApi> defaultTabledata() async {
    final Client client = await accessClientProvider.createAccessClient(
      scopes: const <String>[BigqueryApi.BigqueryScope],
    );
    return BigqueryApi(client).tabledata;
  }
}
