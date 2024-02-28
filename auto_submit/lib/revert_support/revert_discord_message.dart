import 'package:auto_submit/service/discord_notification.dart';

class RevertDiscordMessage {
  final String _username = 'Revert bot';

  Message message(String originalPrUrl, String revertPrUrl, String initiatingAuthor, String reasonForRevert) {
    final String content = '''
Pull Request $originalPrUrl has been reverted by $initiatingAuthor here: $revertPrUrl.
Reason for Revert:$reasonForRevert''';
    return Message(content: content, username: _username);
  }
}