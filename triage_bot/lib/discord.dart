// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:nyxx/nyxx.dart';

sealed class DiscordChannels {
  static const Snowflake botTest = Snowflake.value(945411053179764736);
  static const Snowflake hiddenChat = Snowflake.value(610574672865656952);
  static const Snowflake github2 = Snowflake.value(
      1116095786657267722); // this value is >2^53 and thus cannot be used in JS mode
}

List<Pattern> get boilerplates => <Pattern>[
      '\r',
      r'### Is there an existing issue for this?',
      RegExp(
          r'- \[[ xX]] I have searched the \[existing issues]\(https://github\.com/flutter/flutter/issues\)'),
      RegExp(
          r'- \[[ xX]] I have read the \[guide to filing a bug]\(https://flutter\.dev/docs/resources/bug-reports\)'),
      r'*Replace this paragraph with a description of what this PR is changing or adding, and why. Consider including before/after screenshots.*',
      r'*List which issues are fixed by this PR. You must list at least one issue.*',
      r'*If you had to change anything in the [flutter/tests] repo, include a link to the migration guide as per the [breaking change policy].*',
      r'## Pre-launch Checklist',
      RegExp(
          r'- \[[ xX]] I read the \[Contributor Guide] and followed the process outlined there for submitting PRs\.'),
      RegExp(
          r'- \[[ xX]] I read the \[Tree Hygiene] wiki page, which explains my responsibilities\.'),
      RegExp(
          r'- \[[ xX]] I read and followed the \[Flutter Style Guide], including \[Features we expect every widget to implement]\.'),
      RegExp(
          r'- \[[ xX]] I read the \[Flutter Style Guide] _recently_, and have followed its advice\.'),
      RegExp(
          r'- \[[ xX]] I read and followed the \[Flutter Style Guide] and the \[C\+\+, Objective-C, Java style guides]\.'),
      RegExp(
          r'- \[[ xX]] I read and followed the \[relevant style guides] and ran the auto-formatter\. \(Unlike the flutter/flutter repo, the flutter/packages repo does use `dart format`\.\)'),
      RegExp(r'- \[[ xX]] I signed the \[CLA]\.'),
      RegExp(
          r'- \[[ xX]] I listed at least one issue that this PR fixes in the description above\.'),
      RegExp(
          r'- \[[ xX]] I updated/added relevant documentation \(doc comments with `///`\)\.'),
      RegExp(
          r'- \[[ xX]] I added new tests to check the change I am making, or this PR is \[test-exempt]\.'),
      RegExp(
          r'- \[[ xX]] I added new tests to check the change I am making or feature I am adding, or @test-exemption-reviewers said the PR is test-exempt\. See \[testing the engine] for instructions on writing and running engine tests\.'),
      RegExp(r'- \[[ xX]] All existing and new tests are passing\.'),
      RegExp(
          r'- \[[ xX]] The title of the PR starts with the name of the package surrounded by square brackets, e\.g\. `\[shared_preferences]`'),
      RegExp(
          r'- \[[ xX]] I updated `pubspec.yaml` with an appropriate new version according to the \[pub versioning philosophy], or this PR is \[exempt from version changes]\.'),
      RegExp(
          r'- \[[ xX]] I updated `CHANGELOG.md` to add a description of the change, \[following repository CHANGELOG style]\.'),
      r'If you need help, consider asking for advice on the #hackers-new channel on [Discord].',
      r'<!-- Links -->',
      r'[Contributor Guide]: https://github.com/flutter/flutter/blob/master/docs/contributing/Tree-hygiene.md#overview',
      r'[Contributor Guide]: https://github.com/flutter/packages/blob/main/CONTRIBUTING.md',
      r'[Tree Hygiene]: https://github.com/flutter/flutter/blob/master/docs/contributing/Tree-hygiene.md',
      r'[test-exempt]: https://github.com/flutter/flutter/blob/master/docs/contributing/Tree-hygiene.md#tests',
      r'[Flutter Style Guide]: https://github.com/flutter/flutter/blob/master/docs/contributing/Style-guide-for-Flutter-repo.md',
      r'[Features we expect every widget to implement]: https://github.com/flutter/flutter/blob/master/docs/contributing/Style-guide-for-Flutter-repo.md#features-we-expect-every-widget-to-implement',
      r'[C++, Objective-C, Java style guides]: https://github.com/flutter/engine/blob/main/CONTRIBUTING.md#style',
      r'[relevant style guides]: https://github.com/flutter/packages/blob/main/CONTRIBUTING.md#style',
      r'[testing the engine]: https://github.com/flutter/engine/blob/main/docs/testing/Testing-the-engine.md',
      r'[CLA]: https://cla.developers.google.com/',
      r'[flutter/tests]: https://github.com/flutter/tests',
      r'[breaking change policy]: https://github.com/flutter/flutter/blob/master/docs/contributing/Tree-hygiene.md#handling-breaking-changes',
      r'[Discord]: https://github.com/flutter/flutter/blob/master/docs/contributing/Chat.md',
      r'[pub versioning philosophy]: https://dart.dev/tools/pub/versioning',
      r'[exempt from version changes]: https://github.com/flutter/flutter/blob/master/docs/ecosystem/contributing/README.md#version-and-changelog-updates',
      '### Screenshots or Video\n\n<details>\n<summary>Screenshots / Video demonstration</summary>\n\n[Upload media here]\n\n</details>',
      '### Logs\n\n<details><summary>Logs</summary>\n\n```console\n[Paste your logs here]\n```\n\n</details>',
      '### Code sample\n\n<details><summary>Code sample</summary>\n\n```dart\n[Paste your code here]\n```\n\n</details>',
      '<!--  Thank you for contributing to Flutter!\n\n      If you are filing a bug, please add the steps to reproduce, expected and actual results.\n\n      If you are filing a feature request, please describe the use case and a proposal.\n\n      If you are requesting a small infra task with P0 or P1 priority, please add it to the\n      "Infra Ticket Queue" project with "New" column, explain why the task is needed and what\n      actions need to perform (if you happen to know). No need to set an assignee; the infra oncall\n      will triage and process the infra ticket queue.\n-->',
      r'<details>',
      r'<summary>',
      r'</details>',
      r'</summary>',
    ];

String stripBoilerplate(String message, {bool inline = false}) {
  String current = message;
  for (final Pattern candidate in boilerplates) {
    current = current.replaceAll(candidate, '');
  }
  current = current.replaceAll(RegExp(r'\n( *\n)+'), '\n\n').trim();
  if (current.isEmpty) {
    return '<blank>';
  }
  if (current.contains('\n') && inline) {
    return '\n$current';
  }
  return current;
}

const int _maxLength = 2000;
const String _truncationMarker = '\n**[...truncated]**';
const String _padding = '\n╰╴ ';
final RegExp _imagePattern = RegExp(r'!\[[^\]]*]\(([^)]+)\)$');

Future<void> sendDiscordMessage({
  required INyxx discord,
  required String body,
  String suffix = '',
  required Snowflake channel,
  IEmoji? emoji,
  String? embedTitle,
  String? embedDescription,
  String? embedColor,
  required void Function(String) log,
}) async {
  assert(
      _maxLength > _truncationMarker.length + _padding.length + suffix.length);
  assert((embedTitle == null) == (embedDescription == null) &&
      (embedDescription == null) == (embedColor == null));
  final String content;
  final List<String> embeds = <String>[];
  body = body.replaceAllMapped(_imagePattern, (Match match) {
    // this replaces a trailing markdown image with actually showing that image in discord
    embeds.add(match.group(1)!);
    return '';
  });
  if (body.length + _padding.length + suffix.length > _maxLength) {
    content = body.substring(
            0,
            _maxLength -
                _truncationMarker.length -
                _padding.length -
                suffix.length) +
        _truncationMarker +
        _padding +
        suffix;
  } else if (suffix.isNotEmpty) {
    content = body + _padding + suffix;
  } else {
    content = body;
  }
  final MessageBuilder messageBuilder = MessageBuilder(
    content: content,
    embeds: <EmbedBuilder>[
      for (final String url in embeds)
        EmbedBuilder(
          imageUrl: url,
        ),
      if (embedDescription != null)
        EmbedBuilder(
          title: embedTitle,
          description: embedDescription,
          color: DiscordColor.fromHexString(embedColor!),
        ),
    ],
  )..flags = (MessageFlagBuilder()
    ..suppressEmbeds = embeds.isEmpty && embedDescription == null);
  try {
    final IMessage message =
        await discord.httpEndpoints.sendMessage(channel, messageBuilder);
    if (emoji != null) {
      await message.createReaction(emoji);
    }
  } catch (e) {
    log('Discord error: $e (${e.runtimeType})');
  }
}
