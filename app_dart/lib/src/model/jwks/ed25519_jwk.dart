// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:jose_plus/jose.dart';
import 'package:meta/meta.dart';

/// Size in bytes of an Ed25519 public key (`x`).
const int kEd25519KeyLength = 32;

/// Size in bytes of an Ed25519 signature.
const int kEd25519SignatureLength = 64;

const String _kPublicKeyPemHeader = '-----BEGIN PUBLIC KEY-----';
const String _kPublicKeyPemFooter = '-----END PUBLIC KEY-----';

/// DER encoding of OID `1.3.101.112` (`id-Ed25519`, RFC 8410 Section 3).
const List<int> _kEd25519OidBytes = <int>[0x2b, 0x65, 0x70];

/// Fixed 12-byte RFC 8410 Section 4 SubjectPublicKeyInfo DER prefix for Ed25519.
const List<int> _kEd25519SpkiPrefix = <int>[
  0x30, 0x2a, // SEQUENCE (42 bytes)
  0x30, 0x05, // SEQUENCE (5 bytes) - AlgorithmIdentifier
  0x06, 0x03, 0x2b, 0x65, 0x70, // OID 1.3.101.112 (id-Ed25519)
  0x03, 0x21, 0x00, // BIT STRING (33 bytes, 0 unused bits)
];

/// Pattern for valid Key IDs (unpadded base64url characters).
final RegExp _validKidPattern = RegExp(r'^[A-Za-z0-9_-]+$');

/// Returns whether [kid] contains only valid base64url Key ID characters.
bool isValidJwksKeyId(String kid) =>
    kid.isNotEmpty && _validKidPattern.hasMatch(kid);

/// RFC 8037 Octet Key Pair (`OKP`) JSON Web Key representation of an Ed25519 public key.
///
/// The [kid] is computed as the RFC 7638 JWK Thumbprint using SHA-256 over the
/// canonical JWK members (`crv`, `kty`, `x`).
@immutable
final class Ed25519PublicJwk {
  Ed25519PublicJwk._({
    required Uint8List publicKeyBytes,
    required this.x,
    required this.kid,
  }) : _publicKeyBytes = publicKeyBytes;

  /// Constructs an [Ed25519PublicJwk] from raw 32-byte Ed25519 [publicKeyBytes].
  factory Ed25519PublicJwk.fromPublicKeyBytes(List<int> publicKeyBytes) {
    if (publicKeyBytes.length != kEd25519KeyLength) {
      throw FormatException(
        'Ed25519 public key must be $kEd25519KeyLength bytes, '
        'got ${publicKeyBytes.length}.',
      );
    }
    final bytes = Uint8List.fromList(publicKeyBytes);
    final x = _base64UrlUnpadded(bytes);
    final kid = computeThumbprintForX(x);
    return Ed25519PublicJwk._(publicKeyBytes: bytes, x: x, kid: kid);
  }

  /// Parses an RFC 8410 SubjectPublicKeyInfo (`PUBLIC KEY`) [pem] into an [Ed25519PublicJwk].
  ///
  /// Compatible with the SPKI PEM returned by Google Cloud KMS
  /// `cryptoKeyVersions.getPublicKey` for `EC_SIGN_ED25519` keys.
  ///
  /// If [expectedKid] is provided, throws a [FormatException] if the computed
  /// RFC 7638 thumbprint does not match [expectedKid].
  factory Ed25519PublicJwk.fromPublicKeyPem(String pem, {String? expectedKid}) {
    final der = _decodePem(
      pem,
      expectedHeader: _kPublicKeyPemHeader,
      expectedFooter: _kPublicKeyPemFooter,
    );
    final outer = _readDerTlv(der, 0);
    if (outer.tag != 0x30 || outer.nextOffset != der.length) {
      throw const FormatException(
        'Invalid SPKI DER structure for Ed25519 public key.',
      );
    }

    final algSeq = _readDerTlv(outer.value, 0);
    _validateEd25519AlgorithmIdentifier(algSeq);

    final bitString = _readDerTlv(outer.value, algSeq.nextOffset);
    if (bitString.tag != 0x03 || bitString.nextOffset != outer.value.length) {
      throw const FormatException('Invalid SPKI subjectPublicKey BIT STRING.');
    }
    if (bitString.value.length != kEd25519KeyLength + 1 ||
        bitString.value[0] != 0x00) {
      throw const FormatException(
        'Invalid Ed25519 SPKI BIT STRING length or unused bits.',
      );
    }

    final jwk = Ed25519PublicJwk.fromPublicKeyBytes(
      Uint8List.sublistView(bitString.value, 1),
    );
    if (expectedKid != null && jwk.kid != expectedKid) {
      throw FormatException(
        'Computed RFC 7638 JWK thumbprint (${jwk.kid}) does not match '
        'expected kid ($expectedKid).',
      );
    }
    return jwk;
  }

  final Uint8List _publicKeyBytes;

  /// Raw 32-byte Ed25519 public key bytes.
  Uint8List get publicKeyBytes => Uint8List.fromList(_publicKeyBytes);

  /// JWK Key Type (`"OKP"` per RFC 8037).
  String get kty => 'OKP';

  /// JWK Curve (`"Ed25519"` per RFC 8037).
  String get crv => 'Ed25519';

  /// JWK Public Key Use (`"sig"` for signature verification).
  String get use => 'sig';

  /// JWK Algorithm (`"EdDSA"` per RFC 8037).
  String get alg => 'EdDSA';

  /// Base64url-encoded (unpadded) 32-byte Ed25519 public key (`x`).
  final String x;

  /// Key ID calculated as the RFC 7638 SHA-256 JWK Thumbprint.
  final String kid;

  /// Computes the RFC 7638 SHA-256 JWK Thumbprint for an Ed25519 base64url public key [x].
  ///
  /// Per RFC 7638 Section 3.1 and RFC 8037 Appendix A.3, the required members
  /// for an `"OKP"` public key in lexicographic order are `crv`, `kty`, and `x`.
  static String computeThumbprintForX(String x) {
    final canonicalJson = '{"crv":"Ed25519","kty":"OKP","x":"$x"}';
    final digest = sha256.convert(utf8.encode(canonicalJson));
    return _base64UrlUnpadded(digest.bytes);
  }

  /// Encodes this public key as an RFC 8410 SubjectPublicKeyInfo (`PUBLIC KEY`) PEM string.
  String toPublicKeyPem() {
    final der = Uint8List(_kEd25519SpkiPrefix.length + _publicKeyBytes.length)
      ..setRange(0, _kEd25519SpkiPrefix.length, _kEd25519SpkiPrefix)
      ..setRange(
        _kEd25519SpkiPrefix.length,
        _kEd25519SpkiPrefix.length + _publicKeyBytes.length,
        _publicKeyBytes,
      );
    return _encodePem(
      der,
      header: _kPublicKeyPemHeader,
      footer: _kPublicKeyPemFooter,
    );
  }

  /// Converts this public key to a [JsonWebKey] for `jose_plus` JWT verification.
  JsonWebKey toJoseKey() => JsonWebKey.fromJson(toJson())!;

  /// Serializes this public key to an RFC 7517 / RFC 8037 JWK JSON object.
  Map<String, Object> toJson() => <String, Object>{
    'kty': kty,
    'crv': crv,
    'use': use,
    'alg': alg,
    'kid': kid,
    'x': x,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ed25519PublicJwk &&
          other.kid == kid &&
          other.x == x &&
          const ListEquality<int>().equals(
            other._publicKeyBytes,
            _publicKeyBytes,
          ));

  @override
  int get hashCode => Object.hash(kid, x);
}

String _base64UrlUnpadded(List<int> bytes) =>
    base64UrlEncode(bytes).replaceAll('=', '');

String _encodePem(
  Uint8List der, {
  required String header,
  required String footer,
}) {
  final encoded = base64Encode(der);
  final buffer = StringBuffer()..writeln(header);
  for (var i = 0; i < encoded.length; i += 64) {
    final end = min(i + 64, encoded.length);
    buffer.writeln(encoded.substring(i, end));
  }
  buffer.write(footer);
  return buffer.toString();
}

Uint8List _decodePem(
  String pem, {
  required String expectedHeader,
  required String expectedFooter,
}) {
  final lines = const LineSplitter().convert(pem);
  final headerLineIndex = lines.indexWhere(
    (line) => line.trim() == expectedHeader,
  );
  if (headerLineIndex == -1) {
    throw FormatException('Expected PEM block with $expectedHeader.');
  }
  final footerLineIndex = lines.indexWhere(
    (line) => line.trim() == expectedFooter,
    headerLineIndex + 1,
  );
  if (footerLineIndex == -1) {
    throw FormatException('Expected PEM block with $expectedFooter.');
  }
  if (lines.indexWhere(
        (line) => line.trim() == expectedHeader,
        footerLineIndex + 1,
      ) !=
      -1) {
    throw const FormatException('Expected a single PEM block, found multiple.');
  }
  final body = lines
      .sublist(headerLineIndex + 1, footerLineIndex)
      .join()
      .replaceAll(RegExp(r'\s+'), '');
  if (body.isEmpty) {
    throw const FormatException('PEM body is empty.');
  }
  try {
    return base64Decode(body);
  } on FormatException catch (e) {
    throw FormatException('Invalid base64 encoding in PEM block: ${e.message}');
  }
}

void _validateEd25519AlgorithmIdentifier(_DerTlv algSeq) {
  if (algSeq.tag != 0x30) {
    throw const FormatException('AlgorithmIdentifier must be a DER SEQUENCE.');
  }
  final oid = _readDerTlv(algSeq.value, 0);
  // Per RFC 8410 Section 3, AlgorithmIdentifier parameters MUST be absent.
  if (oid.tag != 0x06 ||
      oid.nextOffset != algSeq.value.length ||
      !const ListEquality<int>().equals(oid.value, _kEd25519OidBytes)) {
    throw const FormatException(
      'Expected Ed25519 OID 1.3.101.112 with absent parameters.',
    );
  }
}

final class _DerTlv {
  const _DerTlv({
    required this.tag,
    required this.value,
    required this.nextOffset,
  });

  final int tag;
  final Uint8List value;
  final int nextOffset;
}

_DerTlv _readDerTlv(Uint8List bytes, int offset) {
  if (offset >= bytes.length) {
    throw const FormatException('Unexpected end of DER input.');
  }
  final tag = bytes[offset];
  var cursor = offset + 1;
  if (cursor >= bytes.length) {
    throw const FormatException('Truncated DER length.');
  }
  final firstLenByte = bytes[cursor++];
  int length;
  if ((firstLenByte & 0x80) == 0) {
    length = firstLenByte;
  } else {
    final numLenBytes = firstLenByte & 0x7f;
    if (numLenBytes == 0) {
      throw const FormatException('Indefinite BER length is not valid DER.');
    }
    if (numLenBytes > 4 || cursor + numLenBytes > bytes.length) {
      throw const FormatException('Invalid or truncated DER length.');
    }
    if (bytes[cursor] == 0) {
      throw const FormatException('Non-minimal DER length encoding.');
    }
    length = 0;
    for (var i = 0; i < numLenBytes; i++) {
      length = (length << 8) | bytes[cursor++];
    }
    if (length < 128) {
      throw const FormatException('Non-minimal DER length encoding.');
    }
  }
  if (cursor + length > bytes.length) {
    throw const FormatException('DER value exceeds buffer bounds.');
  }
  return _DerTlv(
    tag: tag,
    value: Uint8List.sublistView(bytes, cursor, cursor + length),
    nextOffset: cursor + length,
  );
}
