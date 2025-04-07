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
    collectionId: 'accounts',
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
  factory Account({required String email}) {
    return Account.fromDocument(
      g.Document(
        name: p.posix.join(
          kDatabase,
          'documents',
          metadata.collectionId,
          email,
        ),
      ),
    );
  }

  Account.fromDocument(super.document);

  /// Email address of the account.
  String get email => p.posix.basename(name!);
}
