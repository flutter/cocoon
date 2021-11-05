// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_ui/logic/git.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String empty = '';
  const String allWhitespaces = '                   ';
  const String validGitHash1 = '5f9a38fc310908c832810f9d875ed8b56ecc7f75';
  const String validGitHash2 = 'bfadad702e9f699f4ab024c335e7498152d26e34';
  const String invalidGitHash1 = 'bfadad702e9f699f4abb24c335e7498152d26ea@';
  const String invalidGitHash2 = 'bfadad702e9f699f4abq24c335e7498152d26eza';
  const String invalidGitHash3 = 'bfadad702e9f699f4ab024c335e7498152d26e34123';
  const String invalidGitHash4 = 'bfadad702e9f699f4ab024c335e7498152d26e3';

  final GitValidation gitHash = GitHash();
  final GitValidation multiGitHash = MultiGitHash();
  final GitValidation candidateBranch = CandidateBranch();
  final GitValidation gitRemote = GitRemote();
  group('Single Git hash tests', () {
    test('Git hash validaiton accepts an empty string, null or all whitespaces', () {
      expect(gitHash.isValidate(empty), true);
      expect(gitHash.isValidate(allWhitespaces), true);
      expect(gitHash.isValidate(null), true);
    });

    test('Git hash validaiton accepts valid git hashses', () {
      expect(gitHash.isValidate(validGitHash1), true);
      expect(gitHash.isValidate(validGitHash2), true);
    });

    test('Git hash validaiton rejects a git hash that contains unauthorized characters', () {
      expect(gitHash.isValidate(invalidGitHash1), false);
      expect(gitHash.isValidate(invalidGitHash2), false);
    });

    test('Git hash validaiton rejects a git hash that is too long or too short', () {
      expect(gitHash.isValidate(invalidGitHash3), false);
      expect(gitHash.isValidate(invalidGitHash4), false);
    });

    test('GitHash class sanitizes and accepts leading or trailing whitespaces', () {
      final String validGitHash3 = '   $validGitHash2    ';
      expect(gitHash.isValidate(validGitHash3), true);
      expect(gitHash.sanitize(validGitHash3), equals(validGitHash2));
    });
  });

  group('Multi Git hash tests', () {
    String validMultiHash1 = '$validGitHash1,$validGitHash2';
    String validMultiHash2 = '$validGitHash1,$validGitHash2,$validGitHash2';
    String validMultiHash3 = '$validGitHash1';
    String invalidMultiHash1 = '$validGitHash1,$validGitHash2,$validGitHash2,';
    String invalidMultiHash2 = '$validGitHash1,$invalidGitHash1,$validGitHash2';
    String invalidMultiHash3 = '$invalidGitHash1';
    test('Multi Git hash validaiton accepts an empty string, null or all whitespaces', () {
      expect(multiGitHash.isValidate(empty), true);
      expect(multiGitHash.isValidate(allWhitespaces), true);
      expect(multiGitHash.isValidate(null), true);
    });

    test('Multi Git hash validaiton accepts a single valid hash', () {
      expect(multiGitHash.isValidate(validMultiHash3), true);
    });

    test('Multi Git hash validaiton accepts multiple valid hashes delimited by a comma', () {
      expect(multiGitHash.isValidate(validMultiHash1), true);
      expect(multiGitHash.isValidate(validMultiHash2), true);
    });

    test('Multi Git hashes cannot end with a comma', () {
      expect(multiGitHash.isValidate(invalidMultiHash1), false);
    });

    test('Multi Git hash validaiton rejects if there is an invalid hash', () {
      expect(multiGitHash.isValidate(invalidMultiHash2), false);
    });

    test('Multi Git hash validaiton rejects a single invalid hash', () {
      expect(multiGitHash.isValidate(invalidMultiHash3), false);
    });

    test('MultiGitHash class sanitizes and accepts whitespaces anywhere', () {
      String validMultiHash4 = '   $validGitHash1   ,   $validGitHash2,    $validGitHash2       ';
      expect(multiGitHash.isValidate(validMultiHash4), true);
      expect(multiGitHash.sanitize(validMultiHash4), equals('$validGitHash1,$validGitHash2,$validGitHash2'));
    });
  });

  group('Candidate branch tests', () {
    String validCandidateBranch1 = 'flutter-2.7-candidate.3';
    String validCandidateBranch2 = 'flutter-5.7-candidate.310';
    String invalidCandidateBranch1 = 'flutter-5.c-candidate.3';
    String invalidCandidateBranch2 = 'flutter-5.c-candidate.34';
    test('Candidate branch validaiton does not accept an empty string or null', () {
      expect(candidateBranch.isValidate(empty), false);
      expect(candidateBranch.isValidate(null), false);
    });

    test('Candidate branch validaiton accepts correctly-formatted branches', () {
      expect(candidateBranch.isValidate(validCandidateBranch1), true);
      expect(candidateBranch.isValidate(validCandidateBranch2), true);
    });

    test('Candidate branch validaiton does not accept badly-formatted branches', () {
      expect(candidateBranch.isValidate(invalidCandidateBranch1), false);
      expect(candidateBranch.isValidate(invalidCandidateBranch2), false);
    });

    test('Candidate branch sanitizes and accepts leading or trailing whitespaces', () {
      final String validCandidateBranch3 = '   $validCandidateBranch2    ';
      expect(candidateBranch.isValidate(validCandidateBranch3), true);
      expect(candidateBranch.sanitize(validCandidateBranch3), equals(validCandidateBranch2));
    });
  });

  group('Git remote tests', () {
    String validGitRemote1 = 'git@github.com:user/flutter.git';
    String validGitRemote2 = 'https://github.com/user/flutter';
    String invalidGitRemote = 'git@github.com:user/flutter.git@@';
    test('Git remote validation does not accept an empty string or null', () {
      expect(gitRemote.isValidate(empty), false);
      expect(gitRemote.isValidate(null), false);
    });

    test('Git remote validation accepts correctly-formatted branches', () {
      expect(gitRemote.isValidate(validGitRemote1), true);
      expect(gitRemote.isValidate(validGitRemote2), true);
    });

    test('Git remote validation does not accept badly-formatted branches', () {
      expect(gitRemote.isValidate(invalidGitRemote), false);
    });

    test('Git remote sanitizes and accepts leading or trailing whitespaces', () {
      final String validGitRemote3 = '   $validGitRemote2    ';
      expect(gitRemote.isValidate(validGitRemote3), true);
      expect(gitRemote.sanitize(validGitRemote3), equals(validGitRemote2));
    });
  });
}
