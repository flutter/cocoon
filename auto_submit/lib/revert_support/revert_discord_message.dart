// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/service/discord_notification.dart';

class RevertDiscordMessage {
  final String _username = 'Revert bot';
  final int discordMessageLength = 2000;
  final int elipsesOffset = 3;

  Message message(String originalPrUrl, String revertPrUrl, String initiatingAuthor, String reasonForRevert) {
    final String content = '''
Pull Request $originalPrUrl has been reverted by $initiatingAuthor here: $revertPrUrl.
Reason for Revert: $reasonForRevert''';
    final String truncatedContent = content.length <= discordMessageLength
        ? content
        : '${content.substring(0, discordMessageLength - elipsesOffset)}...';
    return Message(content: truncatedContent, username: _username);
  }
}
