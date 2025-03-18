// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/revert/revert_discord_message.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  void checkExpectedOutput(
    String originalPrUrl,
    String originalPrDisplayText,
    String revertPrUrl,
    String revertPrDisplayText,
    String initiatingAuthor,
    String reasonForRevert,
    String realOutput,
  ) {
    final expectedFormattedOutput = '''
Pull Request [$originalPrDisplayText](<$originalPrUrl>) has been reverted by $initiatingAuthor.
Please see the revert PR here: [$revertPrDisplayText](<$revertPrUrl>).
Reason for reverting: $reasonForRevert''';
    expect(expectedFormattedOutput, equals(realOutput));
  }

  test('generateMessage truncates content when necessary', () {
    const originalPrUrl = 'https://example.com/pr/1';
    const originalPrDisplayText = 'flutter/coconut#1234';
    const revertPrUrl = 'https://example.com/pr/2';
    const revertPrDisplayText = 'flutter/coconut#1235';
    const initiatingAuthor = 'John Doe';
    const reasonForRevert =
        '''Test failed very long reason that will exceed the character limit
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

    final message = RevertDiscordMessage.generateMessage(
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
    const originalPrUrl = 'https://example.com/pr/1';
    const originalPrDisplayText = 'flutter/coconut#1234';
    const revertPrUrl = 'https://example.com/pr/2';
    const revertPrDisplayText = 'flutter/coconut#1235';
    const initiatingAuthor = 'John Doe';
    const reasonForRevert = 'Test failed';

    final message = RevertDiscordMessage.generateMessage(
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
    const originalPrUrl = 'https://example.com/pr/1';
    const originalPrDisplayText = 'flutter/coconut#1234';
    const revertPrUrl = 'https://example.com/pr/2';
    const revertPrDisplayText = 'flutter/coconut#1235';
    const initiatingAuthor = 'John Doe';
    const reasonForRevert = 'Test failed';

    final message = RevertDiscordMessage.generateMessage(
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
