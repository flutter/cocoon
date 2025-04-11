// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Represents a repository at `https://github.com/{owner}/{name}`.
@immutable
final class GithubRepository {
  /// Creates a [GithubRepository] from a string in the format `owner/name`.
  ///
  /// See [GithubRepository.owner] and [GithubRepository.name] for requirements.
  ///
  /// Returns `null` if either segment is invalid.
  static GithubRepository? tryFrom(String owner, String name) {
    try {
      return GithubRepository.from(owner, name);
    } on FormatException {
      return null;
    }
  }

  /// Creates a [GithubRepository] from an [owner] and repo [name].
  ///
  /// See [GithubRepository.owner] and [GithubRepository.name] for requirements.
  ///
  /// Throws [FormatException] if either segment is invalid.
  factory GithubRepository.from(String owner, String name) {
    if (owner.isEmpty || owner.length > _maxOwnerChars) {
      throw FormatException(
        'owner must be 1-$_maxOwnerChars characters, got ${owner.length}',
        owner,
      );
    }
    if (name.isEmpty || name.length > _maxNameChars) {
      throw FormatException(
        'name must be 1-$_maxNameChars characters, got ${name.length}',
        name,
      );
    }

    if (!_validOwner.hasMatch(owner)) {
      throw FormatException('Invalid owner', owner);
    }

    if (!_validName.hasMatch(name)) {
      throw FormatException('Invalid name', name);
    }

    return GithubRepository._(owner, name);
  }

  /// Creates a [GithubRepository] from a string in the format `owner/name`.
  ///
  /// See [GithubRepository.owner] and [GithubRepository.name] for requirements.
  ///
  /// Returns `null` if the input or either segment is invalid.
  static GithubRepository? tryParse(String fullName) {
    try {
      return GithubRepository.parse(fullName);
    } on FormatException {
      return null;
    }
  }

  /// Creates a [GithubRepository] from a string in the format `owner/name`.
  ///
  /// See [GithubRepository.owner] and [GithubRepository.name] for requirements.
  ///
  /// Throws [FormatException] if the input or either segment is invalid.
  factory GithubRepository.parse(String fullName) {
    if (fullName.split('/') case [final owner, final name]) {
      return GithubRepository.from(owner, name);
    }
    throw FormatException('Invalid format', fullName);
  }

  const GithubRepository._(this.owner, this.name);

  /// Owner of the repository, such as `flutter` or `google`.
  ///
  /// Must be:
  /// - 1 to 39 characters
  /// - Can only contain alphanmeric characters and hyphen
  /// - Cannot begin or end with a hyphen
  /// - Cannot have consecutive hyphens
  final String owner;
  static const _maxOwnerChars = 39;
  static final _validOwner = RegExp(
    r'^[a-zA-Z0-9](?:[a-zA-Z0-9]|-(?=[a-zA-Z0-9]))*$',
  );

  /// Name of the repository, such as `flutter` or `cocoon`.
  ///
  /// Must be:
  /// - 1 to 100 characters
  /// - Can only contain alphanmeric characters, hyphens, underscores, and periods
  /// - Cannot start with a hyphen
  /// - Cannot be exactly `.` or `..`
  final String name;
  static const _maxNameChars = 100;
  static final _validName = RegExp(
    r'^(?!^\.\.?$)[a-zA-Z0-9_.][a-zA-Z0-9_.-]*$',
  );

  @override
  bool operator ==(Object other) {
    return other is GithubRepository &&
        owner == other.owner &&
        name == other.name;
  }

  @override
  int get hashCode => Object.hash(owner, name);

  /// Repository formatted as `$owner/$name`.
  ///
  /// This is the inverse of [GithubRepository.parse].
  String get fullName => '$owner/$name';

  @override
  String toString() => 'GithubReposotitory <$fullName>';
}
