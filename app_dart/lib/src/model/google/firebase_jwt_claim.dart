// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';

part 'firebase_jwt_claim.g.dart';

@JsonSerializable()
class FirebaseJwtClaim {
  /// Creates a new [FirebaseJwtClaim].
  const FirebaseJwtClaim({this.identities, this.signInProvider, this.tenant});

  /// Create a new [FirebaseJwtClaim] object from its JSON representation.
  factory FirebaseJwtClaim.fromJson(Map<String, dynamic> json) =>
      _$FirebaseJwtClaimFromJson(json);

  /// Dictionary of all the identities that are associated with this user's
  /// account. The keys of the dictionary can be any of the following: email,
  /// phone, google.com, facebook.com, github.com, twitter.com.
  /// The values of the dictionary are arrays of unique identifiers for each
  /// identity provider associated with the account.
  ///
  /// For example, auth.token.firebase.identities["google.com"][0] contains the
  /// first Google user ID associated with the account.
  @JsonKey(name: 'identities')
  final Map<String, List<String>>? identities;

  /// The sign-in provider used to obtain this token. Can be one of the
  /// following strings: custom, password, phone, anonymous, google.com,
  /// facebook.com, github.com, twitter.com.
  @JsonKey(name: 'sign_in_provider')
  final String? signInProvider;

  /// The tenantId associated with the account, if present. e.g. tenant2-m6tyz
  @JsonKey(name: 'tenant')
  final String? tenant;

  /// Serializes this object to a JSON primitive.
  Map<String, dynamic> toJson() => _$FirebaseJwtClaimToJson(this);
}
