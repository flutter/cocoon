// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/model/discord_message.dart';

class RevertDiscordMessage extends Message {
  static const String _username = 'Revert bot';
  static const int discordMessageLength = 2000;
  static const int elipsesOffset = 3;

  RevertDiscordMessage({super.content, super.username, super.avatarUrl});

  static RevertDiscordMessage generateMessage(
    String originalPrUrl,
    String originalPrDisplayText,
    String revertPrUrl,
    String revertPrDisplayText,
    String initiatingAuthor,
    String reasonForRevert,
  ) {
    final String content = '''
Pull Request [$originalPrDisplayText](<$originalPrUrl>) has been reverted by $initiatingAuthor.
Please see the revert PR here: [$revertPrDisplayText](<$revertPrUrl>).
Reason for reverting: $reasonForRevert''';

    final String truncatedContent = content.length <= discordMessageLength
        ? content
        : '${content.substring(0, discordMessageLength - elipsesOffset)}...';

    return RevertDiscordMessage(content: truncatedContent, username: _username);
  }
}
