
import 'dart:io';

import '../datastore/cocoon_config.dart';

typedef HttpRequestHandler = Future<void> Function(Config, HttpRequest);
