// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

/// Provides the ability to query a PR for the files changed.
///
/// This abstraction exists to simplify testing, and to swap out the
/// implementation details; for example between using [GithubApiGetFilesChanged]
/// and a hypothetical future `ActionsArtifactGetFilesChanged`.
abstract interface class GetFilesChanged {
  /// Returns a future that comples with [FilesChanged].
  ///
  /// There are two possible outcomes:
  /// - [InconclusiveFilesChanged] an error state that is non-fatal;
  /// - [SuccessfulFilesChanged] a success state, see [SuccessfulFilesChanged.filesChanged].
  Future<FilesChanged> get(
    RepositorySlug slug,
    int pullRequestNumber,
  );
}

/// Uses []"List pull requests files"](https://docs.github.com/en/rest/pulls/pulls?apiVersion=2022-11-28#list-pull-requests-files).
///
/// This implementation has a limitation where if 30 files are returned we
/// consider the result [InconclusiveFilesChanged], as there are unknown
/// additional pages of results that could exceed our GitHub burst API capacity
/// to retrieve.
///
/// See <https://github.com/flutter/flutter/issues/161462>.
final class GithubApiGetFilesChanged implements GetFilesChanged {
  /// Creates from [GithubService].
  const GithubApiGetFilesChanged(this._config);
  final Config _config;

  @override
  Future<FilesChanged> get(
    RepositorySlug slug,
    int pullRequestNumber,
  ) async {
    final List<String> files;
    try {
      final githubService = await _config.createGithubService(slug);
      files = await githubService.listFiles(
        slug,
        pullRequestNumber,
      );
    } on GitHubError catch (e) {
      return InconclusiveFilesChanged(
        pullRequestNumber: pullRequestNumber,
        reason: 'An error occurred: $e',
      );
    }
    // As currently implemented, the GitHub REST API returns a
    // maximum of 30 changed files, meaning that if we get 30 files, there is a
    // good chance *more* file were changed, we just do not know which ones.
    //
    // As a result, it's unsafe to filter out targets based on runIf. It actually
    // might even be unsafe for smaller amounts of files if the patch diffs are
    // really big, but for now just using the number of files.
    if (files.length >= 30) {
      return InconclusiveFilesChanged(
        pullRequestNumber: pullRequestNumber,
        reason: '>= 30 files were changed, not confident about result size.',
      );
    }
    return SuccessfulFilesChanged(
      pullRequestNumber: pullRequestNumber,
      filesChanged: files,
    );
  }
}

/// Represents the result of requesting the files changed at a PR number.
@immutable
sealed class FilesChanged {
  const FilesChanged({required this.pullRequestNumber});

  /// Which pull request was queried.
  final int pullRequestNumber;
}

/// An inconclusive request: assume that all files were changed.
///
/// For debugging, [reason] contains details on why the reuslt was inconclusive.
final class InconclusiveFilesChanged extends FilesChanged {
  const InconclusiveFilesChanged({
    required super.pullRequestNumber,
    required this.reason,
  });

  /// Why files changed could not be retrieved or cannot be safely used.
  ///
  /// Common reasons could include:
  /// - An HTTP exception or network connectivity issues;
  /// -
  final String reason;
}

/// A successful request for files changed.
final class SuccessfulFilesChanged extends FilesChanged {
  SuccessfulFilesChanged({
    required super.pullRequestNumber,
    required Iterable<String> filesChanged,
  }) : filesChanged = Set.unmodifiable(filesChanged);

  /// A set of files changed, in no particular order.
  ///
  /// This list is unmodifiable.
  final Set<String> filesChanged;
}
