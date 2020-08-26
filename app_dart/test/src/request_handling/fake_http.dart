// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';

typedef ContentLengthProvider = int Function();

/// Signature for a callback function that will be notified whenever a
/// [FakeHttpClient] issues requests.
typedef IssueRequestCallback = void Function(FakeHttpClientRequest request);

@immutable
class _Body {
  _Body.empty()
      : isUtf8 = true,
        value = null,
        bytes = Uint8List(0),
        stream = Stream<Uint8List>.fromIterable(const Iterable<Uint8List>.empty());

  _Body.utf8(this.value)
      : assert(value != null),
        isUtf8 = true,
        bytes = utf8.encode(value) as Uint8List,
        stream = Stream<Uint8List>.fromIterable(<Uint8List>[utf8.encode(value) as Uint8List]);

  _Body.rawBytes(this.bytes)
      : assert(bytes != null),
        isUtf8 = false,
        value = null,
        stream = Stream<Uint8List>.fromIterable(<Uint8List>[bytes]);

  _Body.copy(_Body other)
      : assert(other != null),
        isUtf8 = other.isUtf8,
        value = other.value,
        bytes = other.bytes,
        stream = Stream<Uint8List>.fromIterable(<Uint8List>[other.bytes]);

  final bool isUtf8;
  final String value;
  final Uint8List bytes;
  final Stream<Uint8List> stream;
}

abstract class FakeTransport {
  int get contentLength;

  HttpConnectionInfo get connectionInfo => null;

  final List<FakeCookie> cookies = <FakeCookie>[];

  FakeHttpHeaders get headers {
    _headers ??= FakeHttpHeaders(contentLengthProvider: () => contentLength);
    return _headers;
  }

  FakeHttpHeaders _headers;

  bool get persistentConnection => false;
}

// TODO(tvolkert): `implements Stream<Uint8List>` once HttpClientResponse does the same
abstract class FakeInbound extends FakeTransport {
  FakeInbound(String body) : _body = body == null ? _Body.empty() : _Body.utf8(body);

  /// Indicates whether the body stream has been exposed to callers in any way.
  /// Once the body stream has been exposed to callers, [body] becomes
  /// immutable.
  bool _isStreamExposed = false;

  /// Resets this transport so that it may be reused.
  @mustCallSuper
  void reset() {
    _body = _Body.copy(_body);
    _isStreamExposed = false;
  }

  /// The UTF-8 encoded value of the HTTP request body, or null if this request
  /// specifies no body.
  ///
  /// If the HTTP request body was set via [bodyBytes], then it's assumed that
  /// the body is not a UTF-8 encoded string, and subsequently attempting to
  /// access [body] will throw a [StateError].
  ///
  /// Once the body stream has been exposed to callers in any way, the [body]
  /// value becomes immutable (as does the [bodyBytes] value), and any attempt
  /// to modify it will throw a [StateError].
  String get body {
    if (!_body.isUtf8) {
      throw StateError('body is not a valid UTF-8 string');
    }
    return _body.value;
  }

  _Body _body;
  set body(String value) {
    if (_isStreamExposed) {
      throw StateError('The body of this transport has been made immutable');
    }
    _body = value == null ? _Body.empty() : _Body.utf8(value);
  }

  /// The raw bytes of the HTTP request body.
  ///
  /// This will never be null; if the HTTP request body is empty, this will be
  /// the empty list.
  ///
  /// Setting this value directly will be assumed to be because the bytes are
  /// not a UTF-8 encoded string, and subsequently attempting to access [body]
  /// will throw a [StateError].
  ///
  /// Once the body stream has been exposed to callers in any way, the
  /// [bodyBytes] value becomes immutable (as does the [body] value), and any
  /// attempt to modify it will throw a [StateError].
  Uint8List get bodyBytes => _body.bytes;
  set bodyBytes(Uint8List value) {
    if (_isStreamExposed) {
      throw StateError('The body of this transport has been made immutable');
    }
    assert(value != null);
    _body = _Body.rawBytes(value);
  }

  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event) onData, {
    Function onError,
    void Function() onDone,
    bool cancelOnError,
  }) {
    _isStreamExposed = true;
    return _body.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  Future<bool> any(bool Function(Uint8List element) test) {
    _isStreamExposed = true;
    return _body.stream.any(test);
  }

  Stream<Uint8List> asBroadcastStream({
    void Function(StreamSubscription<Uint8List> subscription) onListen,
    void Function(StreamSubscription<Uint8List> subscription) onCancel,
  }) {
    _isStreamExposed = true;
    return _body.stream.asBroadcastStream(onListen: onListen, onCancel: onCancel);
  }

  Stream<E> asyncExpand<E>(Stream<E> Function(Uint8List event) convert) {
    _isStreamExposed = true;
    return _body.stream.asyncExpand<E>(convert);
  }

  Stream<E> asyncMap<E>(FutureOr<E> Function(Uint8List event) convert) {
    _isStreamExposed = true;
    return _body.stream.asyncMap<E>(convert);
  }

  Stream<R> cast<R>() {
    _isStreamExposed = true;
    return _body.stream.cast<R>();
  }

  Future<bool> contains(Object needle) {
    _isStreamExposed = true;
    return _body.stream.contains(needle);
  }

  Stream<Uint8List> distinct([bool Function(Uint8List previous, Uint8List next) equals]) {
    _isStreamExposed = true;
    return _body.stream.distinct(equals);
  }

  Future<E> drain<E>([E futureValue]) {
    _isStreamExposed = true;
    return _body.stream.drain<E>(futureValue);
  }

  Future<Uint8List> elementAt(int index) {
    _isStreamExposed = true;
    return _body.stream.elementAt(index);
  }

  Future<bool> every(bool Function(Uint8List element) test) {
    _isStreamExposed = true;
    return _body.stream.every(test);
  }

  Stream<S> expand<S>(Iterable<S> Function(Uint8List element) convert) {
    _isStreamExposed = true;
    return _body.stream.expand(convert);
  }

  Future<Uint8List> get first {
    _isStreamExposed = true;
    return _body.stream.first;
  }

  Future<Uint8List> firstWhere(
    bool Function(Uint8List element) test, {
    List<int> Function() orElse,
  }) {
    _isStreamExposed = true;
    return _body.stream.firstWhere(test, orElse: () => Uint8List.fromList(orElse()));
  }

  Future<S> fold<S>(S initialValue, S Function(S previous, Uint8List element) combine) {
    _isStreamExposed = true;
    return _body.stream.fold<S>(initialValue, combine);
  }

  Future<dynamic> forEach(void Function(Uint8List element) action) {
    _isStreamExposed = true;
    return _body.stream.forEach(action);
  }

  Stream<Uint8List> handleError(
    Function onError, {
    bool Function(dynamic error) test,
  }) {
    _isStreamExposed = true;
    return _body.stream.handleError(onError, test: test);
  }

  bool get isBroadcast {
    _isStreamExposed = true;
    return _body.stream.isBroadcast;
  }

  Future<bool> get isEmpty {
    _isStreamExposed = true;
    return _body.stream.isEmpty;
  }

  Future<String> join([String separator = '']) {
    _isStreamExposed = true;
    return _body.stream.join(separator);
  }

  Future<Uint8List> get last {
    _isStreamExposed = true;
    return _body.stream.last;
  }

  Future<Uint8List> lastWhere(
    bool Function(Uint8List element) test, {
    List<int> Function() orElse,
  }) {
    _isStreamExposed = true;
    return _body.stream.lastWhere(test, orElse: () => Uint8List.fromList(orElse()));
  }

  Future<int> get length {
    _isStreamExposed = true;
    return _body.stream.length;
  }

  Stream<S> map<S>(S Function(Uint8List event) convert) {
    _isStreamExposed = true;
    return _body.stream.map<S>(convert);
  }

  Future<dynamic> pipe(StreamConsumer<List<int>> streamConsumer) {
    _isStreamExposed = true;
    return _body.stream.map((Uint8List list) => list.toList()).pipe(streamConsumer);
  }

  Future<Uint8List> reduce(List<int> Function(Uint8List previous, Uint8List element) combine) {
    _isStreamExposed = true;
    return _body.stream
        .reduce((Uint8List previous, Uint8List element) => Uint8List.fromList(combine(previous, element)));
  }

  Future<Uint8List> get single {
    _isStreamExposed = true;
    return _body.stream.single;
  }

  Future<Uint8List> singleWhere(
    bool Function(Uint8List element) test, {
    List<int> Function() orElse,
  }) {
    _isStreamExposed = true;
    return _body.stream.singleWhere(test, orElse: () => Uint8List.fromList(orElse()));
  }

  Stream<Uint8List> skip(int count) {
    _isStreamExposed = true;
    return _body.stream.skip(count);
  }

  Stream<Uint8List> skipWhile(bool Function(Uint8List element) test) {
    _isStreamExposed = true;
    return _body.stream.skipWhile(test);
  }

  Stream<Uint8List> take(int count) {
    _isStreamExposed = true;
    return _body.stream.take(count);
  }

  Stream<Uint8List> takeWhile(bool Function(Uint8List element) test) {
    _isStreamExposed = true;
    return _body.stream.takeWhile(test);
  }

  Stream<Uint8List> timeout(
    Duration timeLimit, {
    void Function(EventSink<Uint8List> sink) onTimeout,
  }) {
    _isStreamExposed = true;
    return _body.stream.timeout(timeLimit, onTimeout: onTimeout);
  }

  Future<List<Uint8List>> toList() {
    _isStreamExposed = true;
    return _body.stream.toList();
  }

  Future<Set<Uint8List>> toSet() {
    _isStreamExposed = true;
    return _body.stream.toSet();
  }

  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) {
    _isStreamExposed = true;
    return _body.stream.map((Uint8List list) => list.toList()).transform<S>(streamTransformer);
  }

  Stream<Uint8List> where(bool Function(Uint8List event) test) {
    _isStreamExposed = true;
    return _body.stream.where(test);
  }

  @override
  int get contentLength => _body.bytes.length;

  X509Certificate get certificate => null;
}

abstract class FakeOutbound extends FakeTransport implements IOSink {
  StringBuffer _buffer = StringBuffer();

  String get body => _buffer.toString();

  List<Object> get errors => _errors;
  List<Object> _errors = <Object>[];

  /// Whether this outbound has been closed.
  bool get isClosed => _isClosed;
  bool _isClosed = false;

  /// Resets this transport so that it may be reused.
  @mustCallSuper
  void reset() {
    _isClosed = false;
    _buffer = StringBuffer();
    _errors = <Object>[];
  }

  @override
  Encoding get encoding => utf8;

  @override
  set encoding(Encoding value) => throw UnsupportedError('Unsupported');

  @override
  void add(List<int> data) {
    if (isClosed) {
      throw StateError('Transport is closed');
    }
    headers._sealed = true;
    _buffer.write(utf8.decode(data));
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    if (isClosed) {
      throw StateError('Transport is closed');
    }
    errors.add(error);
  }

  @override
  Future<dynamic> addStream(Stream<List<int>> stream) async {
    if (isClosed) {
      throw StateError('Transport is closed');
    }
    headers._sealed = true;
    _buffer.write(await utf8.decoder.bind(stream).join());
  }

  @override
  void write(Object obj) {
    if (isClosed) {
      throw StateError('Transport is closed');
    }
    headers._sealed = true;
    _buffer.write(obj);
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) {
    if (isClosed) {
      throw StateError('Transport is closed');
    }
    headers._sealed = true;
    _buffer.writeAll(objects, separator);
  }

  @override
  void writeCharCode(int charCode) {
    if (isClosed) {
      throw StateError('Transport is closed');
    }
    headers._sealed = true;
    _buffer.writeCharCode(charCode);
  }

  @override
  void writeln([Object obj = '']) {
    if (isClosed) {
      throw StateError('Transport is closed');
    }
    headers._sealed = true;
    _buffer.writeln(obj);
  }

  @override
  Future<dynamic> get done async {}

  @override
  Future<dynamic> flush() async {}

  @override
  Future<dynamic> close() async {
    _isClosed = true;
  }

  bool get bufferOutput => false;

  set bufferOutput(bool value) => throw UnsupportedError('Unsupported');

  @override
  int get contentLength => _contentLength ?? _buffer.length;
  int _contentLength;

  set contentLength(int value) {
    _contentLength = value;
  }

  set persistentConnection(bool value) => throw UnsupportedError('Unsupported');
}

class FakeCookie implements Cookie {
  FakeCookie({
    this.name,
    this.value,
    this.domain,
    this.path,
    this.expires,
    this.httpOnly,
    this.maxAge,
    this.secure,
  });

  @override
  String name;

  @override
  String value;

  @override
  String domain;

  @override
  String path;

  @override
  DateTime expires;

  @override
  bool httpOnly;

  @override
  int maxAge;

  @override
  bool secure;
}

class FakeHttpHeaders implements HttpHeaders {
  FakeHttpHeaders({this.contentLengthProvider});

  final ContentLengthProvider contentLengthProvider;
  final Map<String, List<String>> _values = <String, List<String>>{};
  bool _sealed = false;

  void _checkSealed() {
    if (_sealed) {
      throw StateError('HTTP headers are sealed');
    }
  }

  @override
  bool get chunkedTransferEncoding => false;

  @override
  set chunkedTransferEncoding(bool value) => throw UnsupportedError('Unsupported');

  @override
  int get contentLength => contentLengthProvider != null ? contentLengthProvider() : -1;

  @override
  set contentLength(int value) => throw UnsupportedError('Unsupported');

  @override
  ContentType get contentType => throw UnimplementedError();

  @override
  set contentType(ContentType value) {
    _checkSealed();
    removeAll(HttpHeaders.contentTypeHeader);
    add(HttpHeaders.contentTypeHeader, '$value');
  }

  @override
  DateTime date;

  @override
  DateTime expires;

  @override
  String host;

  @override
  DateTime ifModifiedSince;

  @override
  bool persistentConnection;

  @override
  int port;

  @override
  List<String> operator [](String name) => _values[name];

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _checkSealed();
    name = name.toLowerCase();
    _values[name] ??= <String>[];
    _values[name].add('$value');
  }

  @override
  void clear() {
    _checkSealed();
    _values.clear();
  }

  @override
  void forEach(void Function(String name, List<String> values) f) {
    _values.forEach(f);
  }

  @override
  void noFolding(String name) {}

  @override
  void remove(String name, Object value) {
    _checkSealed();
    name = name.toLowerCase();
    if (_values.containsKey('$value')) {
      _values[name].remove('$value');
    }
  }

  @override
  void removeAll(String name) {
    _checkSealed();
    name = name.toLowerCase();
    _values.remove(name);
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _checkSealed();
    name = name.toLowerCase();
    _values[name] = <String>['$value'];
  }

  @override
  String value(String name) {
    final List<String> value = _values[name.toLowerCase()];
    return value == null ? null : value.single;
  }
}

class FakeHttpRequest extends FakeInbound implements HttpRequest {
  /// Creates a new [FakeHttpRequest].
  ///
  /// If the optional [body] argument is specified, the request stream will
  /// yield the specified body value when UTF-8 decoded. By default, the
  /// request stream will be empty. The [body] property can be modified until
  /// the stream has been exposed to callers, at which time it becomes
  /// immutable.
  FakeHttpRequest({
    this.method = 'GET',
    String body,
    String path = '/',
    Map<String, dynamic> queryParametersValue,
    FakeHttpResponse response,
  })  : assert(method != null),
        assert(path != null),
        uri = Uri(path: path, queryParameters: queryParametersValue),
        response = response ?? FakeHttpResponse(),
        super(body);

  @override
  String method;

  @override
  Uri uri;

  String get path => uri.path;
  set path(String value) {
    uri = uri.replace(path: value);
  }

  @override
  FakeHttpResponse response;

  @override
  String get protocolVersion => '1.1';

  @override
  Uri get requestedUri => uri;

  @override
  HttpSession get session => throw UnsupportedError('Unsupported');
}

class FakeHttpResponse extends FakeOutbound implements HttpResponse {
  @override
  Duration get deadline => null;

  @override
  set deadline(Duration value) => throw UnsupportedError('Unsupported');

  @override
  String get reasonPhrase => null;

  @override
  set reasonPhrase(String value) => throw UnsupportedError('Unsupported');

  @override
  int statusCode = HttpStatus.ok;

  @override
  Future<dynamic> redirect(Uri location, {int status = HttpStatus.movedTemporarily}) {
    assert(location != null);
    assert(status != null);
    statusCode = status;
    headers.add(HttpHeaders.locationHeader, '$location');
    return close();
  }

  @override
  Future<Socket> detachSocket({bool writeHeaders = true}) => throw UnsupportedError('Unsupported');
}

class FakeHttpClient implements HttpClient {
  FakeHttpClient({
    FakeHttpClientRequest request,
    this.onIssueRequest,
  }) : request = request ?? FakeHttpClientRequest();

  /// The request to return from the HTTP methods.
  FakeHttpClientRequest request;

  /// Optional callback that will be notified when this client issues requests.
  IssueRequestCallback onIssueRequest;

  /// The number of requests that have been issued.
  int get requestCount => _requestCount;
  int _requestCount = 0;

  static const String methodDelete = 'DELETE';
  static const String methodGet = 'GET';
  static const String methodHead = 'HEAD';
  static const String methodPatch = 'PATCH';
  static const String methodPost = 'POST';
  static const String methodPut = 'PUT';

  @override
  bool autoUncompress;

  @override
  Duration connectionTimeout;

  @override
  Duration idleTimeout;

  @override
  int maxConnectionsPerHost;

  @override
  String userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}

  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {}

  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String realm) f) {}

  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String realm) f) {}

  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port) callback) {}

  @override
  set findProxy(String Function(Uri url) f) {}

  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) async {
    return open(methodDelete, host, port, path);
  }

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) async {
    return openUrl(methodDelete, url);
  }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) async {
    return open(methodGet, host, port, path);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return openUrl(methodGet, url);
  }

  @override
  Future<HttpClientRequest> head(String host, int port, String path) async {
    return open(methodHead, host, port, path);
  }

  @override
  Future<HttpClientRequest> headUrl(Uri url) async {
    return openUrl(methodHead, url);
  }

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) {
    return open(methodPatch, host, port, path);
  }

  @override
  Future<HttpClientRequest> patchUrl(Uri url) {
    return openUrl(methodPatch, url);
  }

  @override
  Future<HttpClientRequest> post(String host, int port, String path) async {
    return open(methodPost, host, port, path);
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return openUrl(methodPost, url);
  }

  @override
  Future<HttpClientRequest> put(String host, int port, String path) async {
    return open(methodPut, host, port, path);
  }

  @override
  Future<HttpClientRequest> putUrl(Uri url) async {
    return openUrl(methodPut, url);
  }

  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) {
    return openUrl(method, Uri(host: host, port: port, path: path));
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    _requestCount++;
    request.reset();
    request.method = method;
    request.uri = url;
    if (onIssueRequest != null) {
      onIssueRequest(request);
    }
    return request;
  }
}

class FakeHttpClientRequest extends FakeOutbound implements HttpClientRequest {
  FakeHttpClientRequest({
    FakeHttpClientResponse response,
  }) : response = response ?? FakeHttpClientResponse();

  /// The response to produce when this request is closed.
  FakeHttpClientResponse response;

  Completer<HttpClientResponse> _doneCompleter = Completer<HttpClientResponse>();

  /// Resets this fake request so that it may be reused.
  @override
  void reset() {
    super.reset();
    response.reset();
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.complete(response);
    }
    _doneCompleter = Completer<HttpClientResponse>();
  }

  @override
  String method;

  @override
  Uri uri;

  @override
  bool followRedirects;

  @override
  int maxRedirects;

  @override
  Future<HttpClientResponse> close() async {
    await super.close();
    _doneCompleter.complete(response);
    return response;
  }

  @override
  Future<HttpClientResponse> get done => _doneCompleter.future;

  @override
  void abort([Object exception, StackTrace stackTrace]) {
    return;
  }
}

class FakeHttpClientResponse extends FakeInbound implements HttpClientResponse {
  FakeHttpClientResponse({String body}) : super(body);

  @override
  HttpClientResponseCompressionState get compressionState {
    return HttpClientResponseCompressionState.decompressed;
  }

  @override
  Future<Socket> detachSocket() async => throw UnsupportedError('Mocked response');

  @override
  bool get isRedirect => false;

  @override
  String get reasonPhrase => null;

  @override
  Future<HttpClientResponse> redirect([String method, Uri url, bool followLoops]) {
    return Future<HttpClientResponse>.error(UnsupportedError('Mocked response'));
  }

  @override
  List<RedirectInfo> get redirects => <RedirectInfo>[];

  @override
  int statusCode = HttpStatus.ok;
}
