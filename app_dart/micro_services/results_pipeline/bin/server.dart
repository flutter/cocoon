import 'dart:convert';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:results_pipeline/common/auth_utils.dart';
import 'package:results_pipeline/common/logging.dart';
import 'package:results_pipeline/common/response.dart';

/// Default handler, returns a 404
void _defaultHandler(HttpRequest request) {
  respond(request, status: HttpStatus.notFound);
}

/// Check authorization of incoming request.
Future<void> _checkAuthorization(HttpRequest request) async {
  if (!await authenticateRequest(request.headers)) {
    await respond(request, status: HttpStatus.unauthorized);
    throw HttpException('Unauthorized request: ${request.headers}');
  }
}

/// Processes LUCI build status updates messages.
///
/// Endpoint for push messages from the pubsub topic that
/// LUCI send build update status messages to.
/// Tasks:
///  1) Verify authorization on incoming message.
///  2) Decodes build update message.
///  3) Saves update to datatstore.
///  4) Triggers retry for failing build.
///
/// POST: /api/process_build_request
///
/// Response: Status 200 OK
///
/// Response: Status 401 Unauthorized
///
Future<void> _processUpdate(HttpRequest request) async {
  final String requestString = await utf8.decodeStream(request);
  log.info(requestString);
  await respond(request);
}

/// Federate incoming requests to the appropriate handlers.
Future<void> _requestHandler(HttpRequest request) async {
  if (request.uri.path == '/api/process_build_update') {
    await _checkAuthorization(request);
    await _processUpdate(request);
  } else {
    _defaultHandler(request);
  }
}

Future<void> main() async {
  useLoggingPackageAdaptor();

  await runAppEngine(_requestHandler,
      onAcceptingConnections: (InternetAddress address, int port) {
    final String host = address.isLoopback ? 'localhost' : address.host;
    print('Serving requests at http://$host:$port/');
  });
}
