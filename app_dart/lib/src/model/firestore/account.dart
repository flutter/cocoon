// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:googleapis/firestore/v1.dart' as g;
import 'package:path/path.dart' as p;

import '../../service/firestore.dart';
import 'base.dart';

/// Describes an authenticated account.
final class Account extends AppDocument<Account> {
  /// Description of the document in Firestore.
  static final metadata = AppDocumentMetadata(
    collectionId: 'elevated_accounts',
    fromDocument: Account.fromDocument,
  );

  @override
  AppDocumentMetadata<Account> get runtimeMetadata => Account.metadata;

  /// Retrieves the account by email.
  ///
  /// Returns `null` if the account does not exist.
  static Future<Account?> getByEmail(
    FirestoreService firestore, {
    required String email,
  }) async {
    final g.Document document;
    try {
      document = await firestore.getDocument(
        p.posix.join(kDatabase, 'documents', metadata.collectionId, email),
      );
    } on g.DetailedApiRequestError catch (e) {
      if (e.status == HttpStatus.notFound) {
        return null;
      }
      rethrow;
    }
    return Account.fromDocument(document);
  }

  /// Creates a new account with the given [email].
  factory Account({required String email, required Permission permission}) {
    return Account.fromDocument(
      g.Document(
        name: p.posix.join(
          kDatabase,
          'documents',
          metadata.collectionId,
          email,
        ),
        fields: {_fieldPermission: g.Value(stringValue: permission.name)},
      ),
    );
  }

  Account.fromDocument(super.document);

  /// Email address of the account.
  String get email => p.posix.basename(name!);

  /// The permission level of the account.
  Permission get permission {
    return Permission.values.byName(fields[_fieldPermission]!.stringValue!);
  }

  /// The permission level of the account.
  static final _fieldPermission = 'permission';
}

/// The permission level of the account.
enum Permission implements Comparable<Permission> {
  /// Default permission level, only public APIs are available.
  none,

  /// Elevated permission level, all non-admin APIs are available.
  elevated,

  /// Admin permission level, all APIs are available.
  admin;

  @override
  int compareTo(Permission other) {
    return index.compareTo(other.index);
  }

  /// Whether the permission level is elevated or higher.
  bool get isElevated => index >= Permission.elevated.index;

  /// Whether the permission level is admin or higher.
  bool get isAdmin => index >= Permission.admin.index;
}
