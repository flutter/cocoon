// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/service/get_files_changed.dart';
import 'package:github/src/common/model/repos.dart';

/// A fake implementation of [GetFilesChanged] that always returned [cannedFiles].
final class FakeGetFilesChanged implements GetFilesChanged {
  FakeGetFilesChanged({this.cannedFiles});

  /// Files to return on [get].
  ///
  /// If this is `null`, returns [InconclusiveFilesChanged].
  List<String>? cannedFiles;

  @override
  Future<FilesChanged> get(RepositorySlug slug, int pullRequestNumber) async {
    if (cannedFiles case final cannedFiles?) {
      return SuccessfulFilesChanged(
        pullRequestNumber: pullRequestNumber,
        filesChanged: cannedFiles,
      );
    }
    return InconclusiveFilesChanged(
      pullRequestNumber: pullRequestNumber,
      reason: 'No files were provided to FakeGetFilesChanged',
    );
  }
}
