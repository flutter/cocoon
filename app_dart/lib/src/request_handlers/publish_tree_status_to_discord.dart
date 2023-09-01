// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:meta/meta.dart';
import 'package:nyxx/nyxx.dart';

import '../../cocoon_service.dart';
import '../model/appengine/github_build_status_update.dart';
import '../request_handling/api_request_handler.dart';
import '../service/build_status_provider.dart';
import '../service/datastore.dart';
import '../service/logging.dart';
import '../service/secrets.dart';

@immutable
class PublishTreeStatusToDiscord extends ApiRequestHandler<Body> {
  const PublishTreeStatusToDiscord({
    required super.config,
    required super.authenticationProvider,
    @visibleForTesting DatastoreServiceProvider? datastoreProvider,
    @visibleForTesting BuildStatusServiceProvider? buildStatusServiceProvider,
  })  : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        buildStatusServiceProvider = buildStatusServiceProvider ?? BuildStatusService.defaultProvider;

  final BuildStatusServiceProvider buildStatusServiceProvider;
  final DatastoreServiceProvider datastoreProvider;
  static const String fullNameRepoParam = 'repo';

  static const String kDiscordTokenKey = 'DISCORD_BOT_TOKEN';

  static const kChanIdFlutterTreeStatus = 613398423093116959;
  static const kChanIdTestChannel = 613398423093116959; // Test channel on test server.

  @override
  Future<Body> get() async {
    if (authContext!.clientContext.isDevelopmentEnvironment) {
      // Don't push GitHub status from the local dev server.
      log.fine('Discord statuses are not pushed from local dev environments');
      return Body.empty;
    }

    final String repository = request!.uri.queryParameters[fullNameRepoParam] ?? 'flutter/flutter';
    final RepositorySlug slug = RepositorySlug.full(repository);
    final DatastoreService datastore = datastoreProvider(config.db);
    final BuildStatusService buildStatusService = buildStatusServiceProvider(datastore);

    final BuildStatus status = (await buildStatusService.calculateCumulativeStatus(slug))!;
    await _publishIfChanged(slug, status.githubStatus, datastore);

    return Body.empty;
  }

  void sendMessageToDiscord(int chanId, String msg) {
    // Create new bot instance
    final CloudSecretManager secretManager = CloudSecretManager();
    final kDiscordToken = secretManager.get(kDiscordTokenKey);

    final bot = NyxxFactory.createNyxxWebsocket(kDiscordToken as String, GatewayIntents.allUnprivileged)
      ..registerPlugin(Logging()) // Default logging plugin
      ..registerPlugin(CliIntegration()) // Cli integration for nyxx allows stopping application via SIGTERM and SIGKILl
      ..registerPlugin(IgnoreExceptions()) // Plugin that handles uncaught exceptions that may occur
      ..connect();

    bot.httpEndpoints.sendMessage(Snowflake(chanId), MessageBuilder.content(msg));
  }

  Future<void> _publishIfChanged(
    RepositorySlug slug,
    String status,
    DatastoreService datastore, [
    int chanId = kChanIdTestChannel,
  ]) async {
    final GitHub github = await config.createGitHubClient(slug: slug);

    await for (PullRequest pr in github.pullRequests.list(slug)) {
      final GithubBuildStatusUpdate update = await datastore.queryLastStatusUpdate(slug, pr);

      /// Do not publish if status has not changed.
      if (update.status == status) {
        return;
      }

      try {
        String msg = "";
        if (update.status == GithubBuildStatusUpdate.statusSuccess) {
          msg = "${slug.name} went GREEN";
        } else if (update.status == GithubBuildStatusUpdate.statusFailure) {
          msg = "${slug.name} went RED";
        }

        log.fine('Publishing ($msg) in channel ($chanId)');
        sendMessageToDiscord(chanId, msg);
      } catch (error) {
        log.severe('Failed to post tree status (${update.status}) of ${slug.name} to discord: $error');
      }
    }
  }
}
