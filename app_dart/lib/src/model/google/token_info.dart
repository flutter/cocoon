// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';

import '../common/json_converters.dart';

part 'token_info.g.dart';

@JsonSerializable()
class TokenInfo {
  /// Creates a new [TokenInfo].
  const TokenInfo({
    this.issuer,
    this.authorizedParty,
    this.audience,
    this.subject,
    this.hostedDomain,
    this.email,
    this.emailIsVerified,
    this.accessTokenHash,
    this.fullName,
    this.profilePictureUrl,
    this.givenName,
    this.familyName,
    this.locale,
    this.issued,
    this.expiration,
    this.jwtId,
    this.algorithm,
    this.keyId,
    this.encoding,
  });

  /// Create a new [TokenInfo] object from its JSON representation.
  factory TokenInfo.fromJson(Map<String, dynamic> json) =>
      _$TokenInfoFromJson(json);

  /// The issuer of the token (e.g. "accounts.google.com").
  @JsonKey(name: 'iss')
  final String? issuer;

  /// The party to which the ID Token was issued.
  @JsonKey(name: 'azp')
  final String? authorizedParty;

  /// The token's intended audience.
  ///
  /// This should be compared against the expected OAuth client ID.
  @JsonKey(name: 'aud')
  final String? audience;

  /// The principal (subject) of the token.
  @JsonKey(name: 'sub')
  final String? subject;

  /// The user's domain.
  ///
  /// https://developers.google.com/identity/protocols/OpenIDConnect#hd-param
  @JsonKey(name: 'hd')
  final String? hostedDomain;

  /// The user's email address.
  @JsonKey(name: 'email')
  final String? email;

  /// Boolean indicating whether the user has verified their email address.
  @JsonKey(name: 'email_verified')
  @BoolConverter()
  final bool? emailIsVerified;

  /// Access token hash value.
  @JsonKey(name: 'at_hash')
  final String? accessTokenHash;

  /// The user's full name.
  @JsonKey(name: 'name')
  final String? fullName;

  /// URL of the user's profile picture.
  @JsonKey(name: 'picture')
  final String? profilePictureUrl;

  /// The user's given name.
  @JsonKey(name: 'given_name')
  final String? givenName;

  /// The user's family name / surname.
  @JsonKey(name: 'family_name')
  final String? familyName;

  /// The user's local code (e.g. "en")
  @JsonKey(name: 'locale')
  final String? locale;

  /// Token issuance date.
  @JsonKey(name: 'iat')
  @SecondsSinceEpochConverter()
  final DateTime? issued;

  /// Token expiration.
  @JsonKey(name: 'exp')
  @SecondsSinceEpochConverter()
  final DateTime? expiration;

  /// Unique identifier for the token itself.
  @JsonKey(name: 'jti')
  final String? jwtId;

  /// Encryption algorithm used to encrypt the token (e.g. "RS256").
  @JsonKey(name: 'alg')
  final String? algorithm;

  /// Key identifier.
  @JsonKey(name: 'kid')
  final String? keyId;

  /// The encoding that was used to encode the unverified token (e.g. "JWT")
  @JsonKey(name: 'typ')
  final String? encoding;

  /// Serializes this object to a JSON primitive.
  Map<String, dynamic> toJson() => _$TokenInfoToJson(this);
}
