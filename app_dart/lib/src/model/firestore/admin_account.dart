// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:googleapis/firestore/v1.dart' as g;
import 'package:path/path.dart' as p;

import '../../service/firestore.dart';
import 'base.dart';

/// Describes an authenticated account.
final class AdminAccount extends AppDocument<AdminAccount> {
  /// Description of the document in Firestore.
  static final metadata = AppDocumentMetadata(
    collectionId: 'admin_accounts',
    fromDocument: AdminAccount.fromDocument,
  );

  @override
  AppDocumentMetadata<AdminAccount> get runtimeMetadata =>
      AdminAccount.metadata;

  /// Retrieves the account by email.
  ///
  /// Returns `null` if the account does not exist.
  static Future<AdminAccount?> getByEmail(
    FirestoreService firestore, {
    required String email,
  }) async {
    final document = await firestore.getDocumentOrNull(
      p.posix.join(kDatabase, 'documents', metadata.collectionId, email),
    );
    return document == null ? null : AdminAccount.fromDocument(document);
  }

  /// Creates a new account with the given [email].
  factory AdminAccount({required String email}) {
    return AdminAccount.fromDocument(
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

  AdminAccount.fromDocument(super.document);

  /// Email address of the account.
  String get email => p.posix.basename(name!);
}
