// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import 'package:cocoon/ioutil.dart';

/// Whether dev server is about to exit.
bool _stopping = false;

/// Processes started by dev server.
final List<ManagedProcess> _childProcesses = <ManagedProcess>[];

final List<StreamSubscription> _streamSubscriptions = <StreamSubscription>[];

/// Proxies HTTP in front of `pub` and `goapp`.
HttpServer devServer;

const _devServerPort = 8080;
const _adminPort = 9089;
const _goappServePort = 9001;
const _pubServePort = 9002;

/// Set from the `--test-agent-auth` command-line argument, instructs the dev
/// server to send API calls to production servers.
///
/// Use this to test local changes on production data, but BE CAREFUL to not
/// corrupt production data.
///
/// See go/flutter-dev-server-auth.
TestAgentAuthentication _testAgentAuth;

/// Forwards requests to pub server and local Google App Engine servers.
HttpClient _localhostProxy;

/// Forwards requests to production Google App Engine servers.
HttpClient _gaeProxy;

/// Runs `pub serve` and `goapp serve` such that the app can be debugged in
/// Dartium.
Future<Null> main(List<String> rawArgs) async {
  ArgResults args = _parseArgs(rawArgs);

  try {
    await _start(args);
  } catch (error, stackTrace) {
    print('Dev server error: $error\n$stackTrace');
    print('Quitting');
    await _stop();
  }
}

Future<Null> _start(ArgResults args) async {
  bool clearDatastore = args['clear-datastore'];

  _streamSubscriptions.addAll(<StreamSubscription>[
    ProcessSignal.sigint.watch().listen((_) {
      print('\nReceived SIGINT. Shutting down.');
      _stop(ProcessSignal.sigint);
    }),
    ProcessSignal.sigint.watch().listen((_) {
      print('\nReceived SIGTERM. Shutting down.');
      _stop(ProcessSignal.sigint);
    }),
  ]);

  await _validateCwd();

  print('Running `goapp serve` on port $_goappServePort');
  List<String> goappArgs = <String>['app.yaml', '--admin_port', '$_adminPort', '--port', '$_goappServePort'];
  if (clearDatastore)
    goappArgs.add('--clear_datastore');

  _childProcesses.add(new ManagedProcess(
    'dev_appserver.py',
    await startProcess('dev_appserver.py', goappArgs)
  ));

  print('Running `pub run build_runner server` on port $_pubServePort');
  _childProcesses.add(new ManagedProcess(
    'pub run',
    await startProcess('pub', ['run', 'build_runner', 'serve', 'web:${_pubServePort}'])
  ));

  devServer = await HttpServer.bind(InternetAddress.loopbackIPv4, _devServerPort);
  print('Listening on http://localhost:$_devServerPort');

  try {
    await _whenLocalPortIsListening(_goappServePort);
    await _whenLocalPortIsListening(_pubServePort);
  } catch(_) {
    print('\n[ERROR] Timed out waiting for goapp and pub ports to become available\n');
    await _stop();
  }

  // We need separate HTTP clients because we keep connections alive, and one
  // is HTTP while the other is HTTPS.
  _localhostProxy = new HttpClient()..autoUncompress = false;
  _gaeProxy = new HttpClient()..autoUncompress = false;

  await for (HttpRequest request in devServer) {
    try {
      await _dispatchRequest(request);
    } catch(e, s) {
      print('Failed redirecting ${request.uri}');
      print(e);
      print(s);
      await _stop();
    }
  }
}

/// If supplied, causes the dev server to forward API calls to the production
/// servers.
class TestAgentAuthentication {
  TestAgentAuthentication._(this.agentId, this.authToken);

  static TestAgentAuthentication fromArgs(String value) {
    final List<String> parts = value.split(':');
    return new TestAgentAuthentication._(parts[0], parts[1]);
  }

  String agentId;
  String authToken;
}

ArgResults _parseArgs(List<String> rawArgs) {
  ArgParser argp = new ArgParser()
    ..addFlag('clear-datastore')
    ..addOption('test-agent-auth', callback: (String value) {
      if (value != null) {
        _testAgentAuth = TestAgentAuthentication.fromArgs(value);
      }
    });

  return argp.parse(rawArgs);
}

bool get _hasTestAgentAuth => _testAgentAuth != null;

Future<Null> _dispatchRequest(HttpRequest request) async {
  final bool isApiRequest = request.uri.path.contains('/api/') || request.uri.path.contains('/_ah/');

  HttpClient proxy;
  Uri uri;
  if (!isApiRequest) {
    // Pub request
    proxy = _localhostProxy;
    uri = request.uri.replace(
      scheme: 'http',
      host: 'localhost',
      port: _pubServePort,
    );
  } else if (_hasTestAgentAuth) {
    // API request with prod auth: forward to prod server
    proxy = _gaeProxy;
    uri = request.uri.replace(
      scheme: 'https',
      host: 'flutter-dashboard.appspot.com',
      port: 443,
    );
  } else {
    // API request with no auth: forward to local dev server
    proxy = _localhostProxy;
    uri = request.uri.replace(
      scheme: 'http',
      host: 'localhost',
      port: _goappServePort,
    );
  }

  HttpClientRequest proxyRequest = await proxy.openUrl(request.method, uri);
  proxyRequest.followRedirects = false;

  if (isApiRequest && _hasTestAgentAuth) {
    proxyRequest.headers.add('Agent-ID', _testAgentAuth.agentId);
    proxyRequest.headers.add('Agent-Auth-Token', _testAgentAuth.authToken);
  } else {
    request.headers.forEach((String name, List<String> values) {
      for (String value in values) {
        proxyRequest.headers.add(name, value);
      }
    });
  }

  await proxyRequest.addStream(request);

  HttpClientResponse proxyResponse = await proxyRequest.close();
  request.response.statusCode = proxyResponse.statusCode;
  List<String> copyHeaders = <String>[
    'content-type',
    'content-encoding',
    'location',
    'cookie',
    'set-cookie',
  ]..addAll(HttpHeaders.responseHeaders);
  for (String headerName in copyHeaders) {
    request.response.headers.set(headerName, proxyResponse.headers.value(headerName));
  }
  await request.response.addStream(proxyResponse);
  await request.response.close();
}

Future<Null> _whenLocalPortIsListening(int port) async {
  Stopwatch sw = new Stopwatch()..start();
  Socket socket;
  dynamic lastError;
  dynamic lastStackTrace;

  while(sw.elapsed < const Duration(seconds: 20) && socket == null) {
    try {
      socket = await Socket.connect('localhost', port);
    } catch(error, stackTrace) {
      lastError = error;
      lastStackTrace = stackTrace;
      await new Future.delayed(new Duration(milliseconds: 500));
    }
  }

  if (socket != null)
    await socket.close();
  else
    return new Future.error(lastError, lastStackTrace);
}

class ManagedProcess {
  ManagedProcess(this.name, this.process) {
    process.exitCode.then((int exitCode) {
      print('$name exited.');
      if (!_stopping) {
        _childProcesses.remove(process);
        _stop(ProcessSignal.sigint);
      }
    });
    _redirectIoStream('[$name][STDOUT]', process.stdout);
    _redirectIoStream('[$name][STDERR]', process.stderr);
  }

  void _redirectIoStream(String label, Stream<List<int>> ioStream) {
    ioStream
      .transform(const Utf8Decoder())
      .transform(const LineSplitter())
      .listen((String line) {
        print('$label: $line');
      });
  }

  final String name;
  final Process process;
}

Future<Null> _validateCwd() async {
  File pubspecYaml = file('${Directory.current.path}/pubspec.yaml');
  File appYaml = file('${Directory.current.path}/app.yaml');

  if (!(await pubspecYaml.exists()))
    throw '${pubspecYaml.path} not found in current working directory';

  if (!(await appYaml.exists()))
    throw '${appYaml.path} not found in current working directory';
}

Future<Null> _stop([ProcessSignal signal = ProcessSignal.sigint]) async {
  if (_stopping)
    return;

  _stopping = true;
  _streamSubscriptions.forEach((s) => s.cancel());
  await devServer.close(force: true);

  // ignore: unawaited_futures
  Future
    .wait(_childProcesses.map((p) => p.process.exitCode))
    .timeout(const Duration(seconds: 5))
    .whenComplete(() {
      // TODO(yjbanov): something is preventing the Dart VM from exiting and I can't
      // figure out what.
      exit(0);
    });

  while (_childProcesses.isNotEmpty) {
    ManagedProcess childProcess = _childProcesses.removeLast();
    print('Sending $signal to ${childProcess.name}');
    childProcess.process.kill(signal);
  }
}
