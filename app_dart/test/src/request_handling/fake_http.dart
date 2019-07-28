// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

abstract class _ContentLengthProvider {
  int get contentLength;
}

class FakeHttpResponse implements HttpResponse, _ContentLengthProvider {
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
  FakeHttpHeaders get headers => FakeHttpHeaders(this);

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
  FakeHttpHeaders(this._contentLengthProvider);

  final _ContentLengthProvider _contentLengthProvider;
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
  int get contentLength => _contentLengthProvider.contentLength;

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
    if (_values.containsKey('$value')) {
      _values[name].remove('$value');
    }
  }

  @override
  void removeAll(String name) {
    _checkSealed();
    _values.remove(name);
  }

  @override
  void set(String name, Object value) {
    _checkSealed();
    _values[name] = <String>['$value'];
  }

  @override
  String value(String name) {
    final List<String> value = _values[name];
    return value == null ? null : value.single;
  }
}
