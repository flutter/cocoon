// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

typedef ContentLengthProvider = int Function();

class _Body {
  _Body.empty()
      : isUtf8 = true,
        value = null,
        bytes = Uint8List(0),
        stream = Stream<Uint8List>.fromIterable(const Iterable<Uint8List>.empty());

  _Body.utf8(this.value)
      : assert(value != null),
        isUtf8 = true,
        bytes = utf8.encode(value),
        stream = Stream<Uint8List>.fromIterable(<Uint8List>[utf8.encode(value)]);

  _Body.rawBytes(this.bytes)
      : assert(bytes != null),
        isUtf8 = false,
        value = null,
        stream = Stream<Uint8List>.fromIterable(<Uint8List>[bytes]);

  final bool isUtf8;
  final String value;
  final Uint8List bytes;
  final Stream<Uint8List> stream;
}

class FakeHttpRequest implements HttpRequest {
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
    FakeHttpResponse response,
  }) {
    _body = body == null ? _Body.empty() : _Body.utf8(body);
    uri = Uri(path: path);
    this.response = response ?? FakeHttpResponse();
  }

  /// Indicates whether the body stream has been exposed to callers in any way.
  /// Once the body stream has been exposed to callers, [body] becomes
  /// immutable.
  bool _isStreamExposed = false;

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
      throw StateError('The body of this FakeHttpRequest has been made immutable');
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
  Uint8List  get bodyBytes => _body.bytes;
  set bodyBytes(Uint8List value) {
    if (_isStreamExposed) {
      throw StateError('The body of this FakeHttpRequest has been made immutable');
    }
    assert(value != null);
    _body = _Body.rawBytes(value);
  }

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
  final HttpHeaders headers = FakeHttpHeaders();

  @override
  String get protocolVersion => '1.1';

  @override
  Uri get requestedUri => uri;

  @override
  HttpSession get session => throw UnsupportedError('Unsupported');

  @override
  X509Certificate get certificate => null;

  @override
  HttpConnectionInfo get connectionInfo => null;

  @override
  int get contentLength => _body.bytes.length;

  @override
  List<Cookie> get cookies => throw UnimplementedError();

  @override
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

  @override
  bool get persistentConnection => false;

  @override
  Future<bool> any(bool Function(Uint8List element) test) {
    _isStreamExposed = true;
    return _body.stream.any(test);
  }

  @override
  Stream<Uint8List> asBroadcastStream({
    void Function(StreamSubscription<Uint8List> subscription) onListen,
    void Function(StreamSubscription<Uint8List> subscription) onCancel,
  }) {
    _isStreamExposed = true;
    return _body.stream.asBroadcastStream(onListen: onListen, onCancel: onCancel);
  }

  @override
  Stream<E> asyncExpand<E>(Stream<E> Function(Uint8List event) convert) {
    _isStreamExposed = true;
    return _body.stream.asyncExpand<E>(convert);
  }

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(Uint8List event) convert) {
    _isStreamExposed = true;
    return _body.stream.asyncMap<E>(convert);
  }

  @override
  Stream<R> cast<R>() {
    _isStreamExposed = true;
    return _body.stream.cast<R>();
  }

  @override
  Future<bool> contains(Object needle) {
    _isStreamExposed = true;
    return _body.stream.contains(needle);
  }

  @override
  Stream<Uint8List> distinct([bool Function(Uint8List previous, Uint8List next) equals]) {
    _isStreamExposed = true;
    return _body.stream.distinct(equals);
  }

  @override
  Future<E> drain<E>([E futureValue]) {
    _isStreamExposed = true;
    return _body.stream.drain<E>(futureValue);
  }

  @override
  Future<Uint8List> elementAt(int index) {
    _isStreamExposed = true;
    return _body.stream.elementAt(index);
  }

  @override
  Future<bool> every(bool Function(Uint8List element) test) {
    _isStreamExposed = true;
    return _body.stream.every(test);
  }

  @override
  Stream<S> expand<S>(Iterable<S> Function(Uint8List element) convert) {
    _isStreamExposed = true;
    return _body.stream.expand(convert);
  }

  @override
  Future<Uint8List> get first {
    _isStreamExposed = true;
    return _body.stream.first;
  }

  @override
  Future<Uint8List> firstWhere(
    bool Function(Uint8List element) test, {
    List<int> Function() orElse,
  }) {
    _isStreamExposed = true;
    return _body.stream.firstWhere(test, orElse: orElse);
  }

  @override
  Future<S> fold<S>(S initialValue, S Function(S previous, Uint8List element) combine) {
    _isStreamExposed = true;
    return _body.stream.fold<S>(initialValue, combine);
  }

  @override
  Future<dynamic> forEach(void Function(Uint8List element) action) {
    _isStreamExposed = true;
    return _body.stream.forEach(action);
  }

  @override
  Stream<Uint8List> handleError(
    Function onError, {
    bool Function(dynamic error) test,
  }) {
    _isStreamExposed = true;
    return _body.stream.handleError(onError, test: test);
  }

  @override
  bool get isBroadcast {
    _isStreamExposed = true;
    return _body.stream.isBroadcast;
  }

  @override
  Future<bool> get isEmpty {
    _isStreamExposed = true;
    return _body.stream.isEmpty;
  }

  @override
  Future<String> join([String separator = '']) {
    _isStreamExposed = true;
    return _body.stream.join(separator);
  }

  @override
  Future<Uint8List> get last {
    _isStreamExposed = true;
    return _body.stream.last;
  }

  @override
  Future<Uint8List> lastWhere(
    bool Function(Uint8List element) test, {
    List<int> Function() orElse,
  }) {
    _isStreamExposed = true;
    return _body.stream.lastWhere(test, orElse: orElse);
  }

  @override
  Future<int> get length {
    _isStreamExposed = true;
    return _body.stream.length;
  }

  @override
  Stream<S> map<S>(S Function(Uint8List event) convert) {
    _isStreamExposed = true;
    return _body.stream.map<S>(convert);
  }

  @override
  Future<dynamic> pipe(StreamConsumer<List<int>> streamConsumer) {
    _isStreamExposed = true;
    return _body.stream.pipe(streamConsumer);
  }

  @override
  Future<Uint8List> reduce(List<int> Function(Uint8List previous, Uint8List element) combine) {
    _isStreamExposed = true;
    return _body.stream.reduce(combine);
  }

  @override
  Future<Uint8List> get single {
    _isStreamExposed = true;
    return _body.stream.single;
  }

  @override
  Future<Uint8List> singleWhere(
    bool Function(Uint8List element) test, {
    List<int> Function() orElse,
  }) {
    _isStreamExposed = true;
    return _body.stream.singleWhere(test, orElse: orElse);
  }

  @override
  Stream<Uint8List> skip(int count) {
    _isStreamExposed = true;
    return _body.stream.skip(count);
  }

  @override
  Stream<Uint8List> skipWhile(bool Function(Uint8List element) test) {
    _isStreamExposed = true;
    return _body.stream.skipWhile(test);
  }

  @override
  Stream<Uint8List> take(int count) {
    _isStreamExposed = true;
    return _body.stream.take(count);
  }

  @override
  Stream<Uint8List> takeWhile(bool Function(Uint8List element) test) {
    _isStreamExposed = true;
    return _body.stream.takeWhile(test);
  }

  @override
  Stream<Uint8List> timeout(
    Duration timeLimit, {
    void Function(EventSink<Uint8List> sink) onTimeout,
  }) {
    _isStreamExposed = true;
    return _body.stream.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<List<Uint8List>> toList() {
    _isStreamExposed = true;
    return _body.stream.toList();
  }

  @override
  Future<Set<Uint8List>> toSet() {
    _isStreamExposed = true;
    return _body.stream.toSet();
  }

  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) {
    _isStreamExposed = true;
    return _body.stream.transform<S>(streamTransformer);
  }

  @override
  Stream<Uint8List> where(bool Function(Uint8List event) test) {
    _isStreamExposed = true;
    return _body.stream.where(test);
  }
}

class FakeHttpResponse implements HttpResponse {
  final StringBuffer _buffer = StringBuffer();

  String get body => _buffer.toString();

  @override
  bool get bufferOutput => false;

  @override
  set bufferOutput(bool value) => throw UnsupportedError('Unsupported');

  @override
  int get contentLength => _contentLength ?? _buffer.length;
  int _contentLength;

  @override
  set contentLength(int value) {
    _contentLength = value;
  }

  @override
  Duration get deadline => null;

  @override
  set deadline(Duration value) => throw UnsupportedError('Unsupported');

  @override
  Encoding get encoding => utf8;

  @override
  set encoding(Encoding value) => throw UnsupportedError('Unsupported');

  @override
  bool get persistentConnection => false;

  @override
  set persistentConnection(bool value) => throw UnsupportedError('Unsupported');

  @override
  String get reasonPhrase => null;

  @override
  set reasonPhrase(String value) => throw UnsupportedError('Unsupported');

  @override
  int statusCode = HttpStatus.ok;

  @override
  void add(List<int> data) {
    headers._sealed = true;
    _buffer.write(utf8.decode(data));
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) => throw UnsupportedError('Unsupported');

  @override
  Future<dynamic> addStream(Stream<List<int>> stream) async {
    headers._sealed = true;
    _buffer.write(await utf8.decoder.bind(stream).join());
  }

  @override
  void write(Object obj) {
    headers._sealed = true;
    _buffer.write(obj);
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) {
    headers._sealed = true;
    _buffer.writeAll(objects, separator);
  }

  @override
  void writeCharCode(int charCode) {
    headers._sealed = true;
    _buffer.writeCharCode(charCode);
  }

  @override
  void writeln([Object obj = '']) {
    headers._sealed = true;
    _buffer.writeln(obj);
  }

  @override
  HttpConnectionInfo get connectionInfo => throw UnsupportedError('Unsupported');

  @override
  FakeHttpHeaders get headers => FakeHttpHeaders(contentLengthProvider: () => contentLength);

  @override
  List<Cookie> get cookies => throw UnimplementedError();

  @override
  Future<dynamic> redirect(Uri location, {int status = HttpStatus.movedTemporarily}) {
    statusCode = status;
    headers.add(HttpHeaders.locationHeader, '$location');
    return close();
  }

  @override
  Future<Socket> detachSocket({bool writeHeaders = true}) => throw UnsupportedError('Unsupported');

  @override
  Future<dynamic> get done => Future<dynamic>.value();

  @override
  Future<dynamic> flush() => Future<dynamic>.value();

  @override
  Future<dynamic> close() => Future<dynamic>.value();
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
  void add(String name, Object value) {
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
  void set(String name, Object value) {
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
