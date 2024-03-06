// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/revert/revert_discord_message.dart';
import 'package:test/test.dart';

void main() {
  void checkExpectedOutput(
    String originalPrUrl,
    String originalPrDisplayText,
    String revertPrUrl,
    String revertPrDisplayText,
    String initiatingAuthor,
    String reasonForRevert,
    String realOutput,
  ) {
    final String expectedFormattedOutput = '''
Pull Request [$originalPrDisplayText](<$originalPrUrl>) has been reverted by $initiatingAuthor. 
Please see the revert PR here: [$revertPrDisplayText](<$revertPrUrl>).
Reason for reverting: $reasonForRevert''';
    expect(expectedFormattedOutput, equals(realOutput));
  }

  test('generateMessage truncates content when necessary', () {
    const String originalPrUrl = 'https://example.com/pr/1';
    const String originalPrDisplayText = 'flutter/coconut#1234';
    const String revertPrUrl = 'https://example.com/pr/2';
    const String revertPrDisplayText = 'flutter/coconut#1235';
    const String initiatingAuthor = 'John Doe';
    const String reasonForRevert = '''Test failed very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     very long reason that will exceed the character limit
     ''';

    final RevertDiscordMessage message = RevertDiscordMessage.generateMessage(
      originalPrUrl,
      originalPrDisplayText,
      revertPrUrl,
      revertPrDisplayText,
      initiatingAuthor,
      reasonForRevert,
    );

    expect(message.content!.contains('...'), isTrue);
  });

  test('generateMessage does not truncate short content', () {
    const String originalPrUrl = 'https://example.com/pr/1';
    const String originalPrDisplayText = 'flutter/coconut#1234';
    const String revertPrUrl = 'https://example.com/pr/2';
    const String revertPrDisplayText = 'flutter/coconut#1235';
    const String initiatingAuthor = 'John Doe';
    const String reasonForRevert = 'Test failed';

    final RevertDiscordMessage message = RevertDiscordMessage.generateMessage(
      originalPrUrl,
      originalPrDisplayText,
      revertPrUrl,
      revertPrDisplayText,
      initiatingAuthor,
      reasonForRevert,
    );

    checkExpectedOutput(
      originalPrUrl,
      originalPrDisplayText,
      revertPrUrl,
      revertPrDisplayText,
      initiatingAuthor,
      reasonForRevert,
      message.content!,
    );
  });

  test('RevertDiscordMessage generates a RevertDiscordMessage', () {
    const String originalPrUrl = 'https://example.com/pr/1';
    const String originalPrDisplayText = 'flutter/coconut#1234';
    const String revertPrUrl = 'https://example.com/pr/2';
    const String revertPrDisplayText = 'flutter/coconut#1235';
    const String initiatingAuthor = 'John Doe';
    const String reasonForRevert = 'Test failed';

    final RevertDiscordMessage message = RevertDiscordMessage.generateMessage(
      originalPrUrl,
      originalPrDisplayText,
      revertPrUrl,
      revertPrDisplayText,
      initiatingAuthor,
      reasonForRevert,
    );

    checkExpectedOutput(
      originalPrUrl,
      originalPrDisplayText,
      revertPrUrl,
      revertPrDisplayText,
      initiatingAuthor,
      reasonForRevert,
      message.content!,
    );
  });
}
