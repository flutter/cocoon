import 'dart:io';

import 'datastore/cocoon_config.dart';

export 'request_handlers/github_webhook.dart';
export 'datastore/cocoon_config.dart';

typedef HttpRequestHandler = Future<void> Function(Config, HttpRequest);
