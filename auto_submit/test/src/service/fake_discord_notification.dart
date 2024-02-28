import 'package:auto_submit/service/discord_notification.dart';

class FakeDiscordNotification extends DiscordNotification {
  FakeDiscordNotification({required super.targetUri});

  @override
  notifyDiscordChannelWebhook(String jsonMessageString) {
    // do nothing
  }
}
