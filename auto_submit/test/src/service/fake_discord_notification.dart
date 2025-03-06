// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/service/discord_notification.dart';

class FakeDiscordNotification extends DiscordNotification {
  FakeDiscordNotification({required super.targetUri});

  @override
  Future<void> notifyDiscordChannelWebhook(String jsonMessageString) async {
    // do nothing
  }
}
