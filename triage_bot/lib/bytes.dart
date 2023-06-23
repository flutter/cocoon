// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

typedef Reader<T> = T Function();
typedef CustomReader<T> = T Function(FileReader reader);
typedef Writer<T> = void Function(T value);
typedef CustomWriter<T> = void Function(FileWriter reader, T value);

const int _typeNullable = 0x01;
const int _typeBool = 0x02;
const int _typeInt = 0x03;
const int _typeString = 0x04;
const int _typeDateTime = 0x05;
const int _typeSet = 0x10;
const int _typeMap = 0x11;
const int _typeCustom = 0xFE;
const int _typeEnd = 0xFF;

class FileReader {
  FileReader(this._buffer) : _endianness = Endian.host;

  final ByteData _buffer;
  final Endian _endianness;
  int _position = 0;

  static Future<FileReader> open(File file) async {
    final Uint8List bytes = await file.readAsBytes();
    return FileReader(bytes.buffer.asByteData(bytes.offsetInBytes, bytes.length));
  }

  void _readType(int expected) {
    final int type = _buffer.getUint8(_position);
    _position += 1;
    if (expected != type) {
      throw FormatException('expected $expected but got $type at byte ${_position - 1}');
    }
  }

  T? readNullOr<T>(Reader<T> reader) {
    _readType(_typeNullable);
    final int result = _buffer.getUint8(_position);
    _position += 1;
    if (result == 0) {
      return null;
    }
    return reader();
  }

  bool readBool() {
    _readType(_typeBool);
    final int result = _buffer.getUint8(_position);
    _position += 1;
    return result != 0x00;
  }

  int readInt() {
    _readType(_typeInt);
    final int result = _buffer.getInt64(_position, _endianness);
    _position += 8;
    return result;
  }

  String readString() {
    _readType(_typeString);
    final int length = readInt();
    final String result = utf8.decode(_buffer.buffer.asUint8List(_buffer.offsetInBytes + _position, length));
    _position += length;
    return result;
  }

  DateTime readDateTime() {
    _readType(_typeDateTime);
    return DateTime.fromMicrosecondsSinceEpoch(readInt(), isUtc: true);
  }

  Reader<Set<T>> readerForSet<T>(Reader<T> reader) {
    return () {
      _readType(_typeSet);
      final int count = readInt();
      final Set<T> result = <T>{};
      for (int index = 0; index < count; index += 1) {
        result.add(reader());
      }
      return result;
    };
  }

  Set<T> readSet<T>(Reader<T> reader) {
    return readerForSet<T>(reader)();
  }

  Reader<Map<K, V>> readerForMap<K, V>(Reader<K> keyReader, Reader<V> valueReader) {
    return () {
      _readType(_typeMap);
      final int count = readInt();
      final Map<K, V> result = <K, V>{};
      for (int index = 0; index < count; index += 1) {
        result[keyReader()] = valueReader();
      }
      return result;
    };
  }

  Map<K, V> readMap<K, V>(Reader<K> keyReader, Reader<V> valueReader) {
    return readerForMap<K, V>(keyReader, valueReader)();
  }

  Reader<T> readerForCustom<T>(CustomReader<T> reader) {
    return () {
      _readType(_typeCustom);
      return reader(this);
    };
  }

  void close() {
    _readType(_typeEnd);
    if (_position != _buffer.lengthInBytes) {
      throw StateError('read failed; position=$_position, expected ${_buffer.lengthInBytes}');
    }
  }
}

class FileWriter {
  FileWriter() : _endianness = Endian.host;

  final BytesBuilder _buffer = BytesBuilder();
  final Endian _endianness;

  void _writeType(int type) {
    _buffer.addByte(type);
  }

  void writeNullOr<T>(T? value, Writer<T> writer) {
    _writeType(_typeNullable);
    if (value == null) {
      _buffer.addByte(0x00);
    } else {
      _buffer.addByte(0xFF);
      writer(value);
    }
  }

  void writeBool(bool value) { // ignore: avoid_positional_boolean_parameters
    _writeType(_typeBool);
    _buffer.addByte(value ? 0x01 : 0x00);
  }

  final ByteData _intBuffer = ByteData(8);
  late final Uint8List _intBytes = _intBuffer.buffer.asUint8List();

  void writeInt(int value) {
    _writeType(_typeInt);
    _intBuffer.setInt64(0, value, _endianness);
    _buffer.add(_intBytes);
  }

  void writeString(String value) {
    _writeType(_typeString);
    final List<int> stringBuffer = utf8.encode(value);
    writeInt(stringBuffer.length);
    _buffer.add(stringBuffer);
  }

  void writeDateTime(DateTime value) {
    _writeType(_typeDateTime);
    writeInt(value.microsecondsSinceEpoch);
  }

  Writer<Set<T>> writerForSet<T>(Writer<T> writer) {
    return (Set<T> value) {
      _writeType(_typeSet);
      writeInt(value.length);
      value.forEach(writer);
    };
  }

  void writeSet<T>(Writer<T> writer, Set<T> value) {
    writerForSet<T>(writer)(value);
  }

  Writer<Map<K, V>> writerForMap<K, V>(Writer<K> keyWriter, Writer<V> valueWriter) {
    return (Map<K, V> value) {
      _writeType(_typeMap);
      writeInt(value.length);
      value.forEach((K key, V value) {
        keyWriter(key);
        valueWriter(value);
      });
    };
  }

  void writeMap<K, V>(Writer<K> keyWriter, Writer<V> valueWriter, Map<K, V> value) {
    writerForMap<K, V>(keyWriter, valueWriter)(value);
  }

  Writer<T> writerForCustom<T>(CustomWriter<T> writer) {
    return (T value) {
      _writeType(_typeCustom);
      writer(this, value);
    };
  }

  Future<void> write(File file) async {
    _writeType(_typeEnd);
    final File temp = File('${file.path}.\$\$\$');
    await temp.writeAsBytes(_buffer.takeBytes());
    if (file.existsSync()) {
      await file.delete();
    }
    await temp.rename(file.path);
  }

  ByteData serialize() {
    _writeType(_typeEnd);
    final int length = _buffer.length;
    return _buffer.takeBytes().buffer.asByteData(0, length);
  }
}
