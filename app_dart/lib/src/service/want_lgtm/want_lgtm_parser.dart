// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'want_lgtm_models.dart';

/// Matches `WANT_LGTM=<tokens>` anchored strictly at column 0 of a line.
///
/// Indented, blockquoted (`> WANT_LGTM=...`), or inline (`<!-- WANT_LGTM=... -->`)
/// occurrences do not start at column 0 and are ignored.
final _kDirectiveLineRegExp = RegExp(
  r'^WANT_LGTM\s*=\s*(.*)$',
  multiLine: true,
  caseSensitive: false,
);

/// Matches a valid GitHub username (after any leading `@` is stripped):
/// - `^[a-z\d]`: must start with an ASCII letter or digit (`caseSensitive: false`).
/// - `(?:[a-z\d]|-(?=[a-z\d])){0,38}$`: up to 38 additional characters (GitHub's
///   39-character limit), allowing ASCII letters, digits, and single internal
///   hyphens (`-(?=[a-z\d])` rejects consecutive `--` and trailing `-`).
/// - `\w` is intentionally avoided because underscores (`_`) are invalid in
///   GitHub usernames.
final _kGitHubLoginRegExp = RegExp(
  r'^[a-z\d](?:[a-z\d]|-(?=[a-z\d])){0,38}$',
  caseSensitive: false,
);

/// Splits directive payloads on commas and whitespace.
final _kTokenSplitRegExp = RegExp(r'[,\s]+');

/// Extracts raw directive tokens from all `^WANT_LGTM=` lines in [body].
({bool hasDirective, List<String> tokens}) _extractDirectives(String body) {
  final matches = _kDirectiveLineRegExp.allMatches(
    body.replaceAll('\r\n', '\n'),
  );
  if (matches.isEmpty) {
    return (hasDirective: false, tokens: const []);
  }

  final tokens = <String>[
    for (final match in matches)
      ...match
          .group(1)!
          .split(_kTokenSplitRegExp)
          .where((token) => token.isNotEmpty),
  ];
  return (hasDirective: true, tokens: tokens);
}

/// Classifies tokens into `requiresAll`, `explicitLogins`, and `invalidTokens`.
({bool requiresAll, List<String> explicitLogins, List<String> invalidTokens})
_classifyTokens(List<String> rawTokens, String normalizedAuthor) {
  var requiresAll = false;
  final explicitLogins = <String>{};
  final invalidTokens = <String>[];

  for (final token in rawTokens) {
    final candidate = token.startsWith('@') ? token.substring(1) : token;
    if (candidate.toLowerCase() == 'all') {
      requiresAll = true;
      continue;
    }

    if (!_kGitHubLoginRegExp.hasMatch(candidate)) {
      invalidTokens.add(token);
      continue;
    }

    final login = candidate.toLowerCase();
    if (login != normalizedAuthor) {
      explicitLogins.add(login);
    }
  }

  return (
    requiresAll: requiresAll,
    explicitLogins: explicitLogins.toList()..sort(),
    invalidTokens: invalidTokens,
  );
}

/// Parses a PR [body] to extract and validate any `WANT_LGTM=` directives.
///
/// Only directives starting at column 0 of a line are matched. The [authorLogin]
/// is excluded from the parsed explicit logins.
ParsedWantLgtmDirective parseWantLgtmDirective(
  String? body, {
  required String authorLogin,
}) {
  if (body == null || body.trim().isEmpty) {
    return const NoWantLgtmDirective();
  }

  final (:hasDirective, :tokens) = _extractDirectives(body);
  if (!hasDirective) {
    return const NoWantLgtmDirective();
  }

  final (:requiresAll, :explicitLogins, :invalidTokens) = _classifyTokens(
    tokens,
    authorLogin.trim().toLowerCase(),
  );

  if (invalidTokens.isNotEmpty) {
    return InvalidWantLgtmDirective(invalidTokens: invalidTokens);
  }

  if (!requiresAll && explicitLogins.isEmpty) {
    return const NoWantLgtmDirective();
  }

  return ValidWantLgtmDirective(
    requiresAll: requiresAll,
    explicitLogins: explicitLogins,
  );
}
