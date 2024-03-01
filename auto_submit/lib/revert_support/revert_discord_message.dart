// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/service/discord_notification.dart';

class RevertDiscordMessage extends Message {
  static const String _username = 'Revert bot';
  static const int discordMessageLength = 2000;
  static const int elipsesOffset = 3;

  RevertDiscordMessage({super.content, super.username, super.avatarUrl});

  static RevertDiscordMessage generateMessage(
    String originalPrUrl,
    String revertPrUrl,
    String initiatingAuthor,
    String reasonForRevert,
  ) {
    final String content = '''
Pull Request $originalPrUrl has been reverted by $initiatingAuthor here: $revertPrUrl.
Reason for Revert: $reasonForRevert''';

    final String truncatedContent = content.length <= discordMessageLength
        ? content
        : '${content.substring(0, discordMessageLength - elipsesOffset)}...';

    return RevertDiscordMessage(content: truncatedContent, username: _username);
  }
}
