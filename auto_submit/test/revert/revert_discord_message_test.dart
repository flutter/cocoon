// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/revert/revert_discord_message.dart';
import 'package:test/test.dart';

void main() {
  test('generateMessage truncates content when necessary', () {
    const String originalPrUrl = 'https://example.com/pr/1';
    const String revertPrUrl = 'https://example.com/pr/2';
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
      revertPrUrl,
      initiatingAuthor,
      reasonForRevert,
    );

    expect(message.content!.contains('...'), isTrue);
  });

  test('generateMessage does not truncate short content', () {
    const originalPrUrl = 'https://example.com/pr/1';
    const revertPrUrl = 'https://example.com/pr/2';
    const initiatingAuthor = 'John Doe';
    const reasonForRevert = 'Test failed';
    const expectedContent = '''
Pull Request $originalPrUrl has been reverted by $initiatingAuthor here: $revertPrUrl.
Reason for Revert: $reasonForRevert''';

    final RevertDiscordMessage message = RevertDiscordMessage.generateMessage(
      originalPrUrl,
      revertPrUrl,
      initiatingAuthor,
      reasonForRevert,
    );

    expect(message.content, equals(expectedContent));
  });

  test('RevertDiscordMessage generates a RevertDiscordMessage', () {
    const originalPrUrl = 'https://example.com/pr/1';
    const revertPrUrl = 'https://example.com/pr/2';
    const initiatingAuthor = 'John Doe';
    const reasonForRevert = 'Test failed';
    const expectedContent = '''
Pull Request $originalPrUrl has been reverted by $initiatingAuthor here: $revertPrUrl.
Reason for Revert: $reasonForRevert''';

    final RevertDiscordMessage message = RevertDiscordMessage.generateMessage(
      originalPrUrl,
      revertPrUrl,
      initiatingAuthor,
      reasonForRevert,
    );

    expect(message.content, equals(expectedContent));
  });
}
