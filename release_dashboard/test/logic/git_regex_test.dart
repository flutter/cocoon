// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/logic/git_regex.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String empty = '';
  const String validGitHash1 = '5f9a38fc310908c832810f9d875ed8b56ecc7f75';
  const String validGitHash2 = 'bfadad702e9f699f4ab024c335e7498152d26e34';
  const String invalidGitHash1 = 'bfadad702e9f699f4abb24c335e7498152d26ea@';
  const String invalidGitHash2 = 'bfadad702e9f699f4abq24c335e7498152d26eza';
  const String invalidGitHash3 = 'bfadad702e9f699f4ab024c335e7498152d26e34123';
  const String invalidGitHash4 = 'bfadad702e9f699f4ab024c335e7498152d26e3';
  group('Single Git hash pattern tests', () {
    test('Git hash pattern accepts an empty string', () {
      expect(gitHashRegex.hasMatch(empty), true);
    });

    test('Git hash pattern accepts valid git hashses', () {
      expect(gitHashRegex.hasMatch(validGitHash1), true);
      expect(gitHashRegex.hasMatch(validGitHash2), true);
    });

    test('Git hash pattern rejects a git hash that contains unauthorized characters', () {
      expect(gitHashRegex.hasMatch(invalidGitHash1), false);
      expect(gitHashRegex.hasMatch(invalidGitHash2), false);
    });

    test('Git hash pattern rejects a git hash that is too long or too short', () {
      expect(gitHashRegex.hasMatch(invalidGitHash3), false);
      expect(gitHashRegex.hasMatch(invalidGitHash4), false);
    });
  });

  group('Multi Git hash pattern tests', () {
    String validMultiHash1 = '$validGitHash1,$validGitHash2';
    String validMultiHash2 = '$validGitHash1,$validGitHash2,$validGitHash2';
    String validMultiHash3 = '$validGitHash1';
    String invalidMultiHash1 = '$validGitHash1,$validGitHash2,$validGitHash2,';
    String invalidMultiHash2 = '$validGitHash1,$invalidGitHash1,$validGitHash2';
    String invalidMultiHash3 = '$invalidGitHash1';
    test('Multi Git hash pattern accepts an empty string', () {
      expect(multiGitHashRegex.hasMatch(empty), true);
    });

    test('Multi Git hash pattern accepts a single valid hash', () {
      expect(multiGitHashRegex.hasMatch(validMultiHash3), true);
    });

    test('Multi Git hash pattern accepts multiple valid hashes delimited by a comma', () {
      expect(multiGitHashRegex.hasMatch(validMultiHash1), true);
      expect(multiGitHashRegex.hasMatch(validMultiHash2), true);
    });

    test('Multi Git hashes cannot end with a comma', () {
      expect(multiGitHashRegex.hasMatch(invalidMultiHash1), false);
    });

    test('Multi Git hash pattern rejects if there is an invalid hash', () {
      expect(multiGitHashRegex.hasMatch(invalidMultiHash2), false);
    });

    test('Multi Git hash pattern rejects a single invalid hash', () {
      expect(multiGitHashRegex.hasMatch(invalidMultiHash3), false);
    });
  });

  group('Candidate branch regex test', () {
    String validCandidateBranch1 = 'flutter-2.7-candidate.3';
    String validCandidateBranch2 = 'flutter-5.7-candidate.310';
    String invalidCandidateBranch1 = 'flutter-5.c-candidate.3';
    String invalidCandidateBranch2 = 'flutter-5.c-candidate.34';
    test('Candidate branch regex does not accept an empty string', () {
      expect(candidateBranchRegex.hasMatch(empty), false);
    });

    test('Candidate branch regex accepts correctly-formatted branches', () {
      expect(candidateBranchRegex.hasMatch(validCandidateBranch1), true);
      expect(candidateBranchRegex.hasMatch(validCandidateBranch2), true);
    });

    test('Candidate branch regex does not accept badly-formatted branches', () {
      expect(candidateBranchRegex.hasMatch(invalidCandidateBranch1), false);
      expect(candidateBranchRegex.hasMatch(invalidCandidateBranch2), false);
    });
  });
}
