import 'dart:typed_data';

extension BytesStreamExtension on Stream<List<int>> {
  /// Collects and returns all of the integer lists as list of bytes.
  Future<Uint8List> collectBytes({bool copy = true}) async {
    final builder = await fold(BytesBuilder(copy: copy), (builder, data) {
      builder.add(data);
      return builder;
    });
    return builder.takeBytes();
  }
}
