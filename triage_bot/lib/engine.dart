// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:appengine/appengine.dart' show authClientService, runAppEngine, withAppEngineServices;
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:github/github.dart';
import 'package:googleapis/secretmanager/v1.dart';
import 'package:http/http.dart' as http show Client;
import 'package:nyxx/nyxx.dart';

import 'bytes.dart';
import 'discord.dart';
import 'json.dart';
import 'utils.dart';

const int port = 8213; // used only when not using appengine
const int maxLogLength = 1024;

sealed class GitHubSettings {
  static const String organization = 'flutter';
  static const String teamName = 'flutter-hackers';
  static final RepositorySlug primaryRepository = RepositorySlug(organization, 'flutter');
  static const String teamPrefix = 'team-';
  static const String triagedPrefix = 'triaged-';
  static const String fyiPrefix = 'fyi-';
  static const String designDoc = 'design doc';
  static const String permanentlyLocked = 'permanently locked';
  static const String thumbsUpLabel = ':+1:';
  static const String staleIssueLabel = ':hourglass_flowing_sand:';
  static const Set<String> priorities = <String>{ 'P0', 'P1', 'P2', 'P3' };
  static const String staleP1Message = 'This issue is marked P1 but has had no recent status updates.\n'
     '\n'
     'The P1 label indicates high-priority issues that are at the top of the work list. '
     'This is the highest priority level a bug can have '
     'if it isn\'t affecting a top-tier customer or breaking the build. '
     'Bugs marked P1 are generally actively being worked on '
     'unless the assignee is dealing with a P0 bug (or another P1 bug). '
     'Issues at this level should be resolved in a matter of months and should have monthly updates on GitHub.\n'
     '\n'
     'Please consider where this bug really falls in our current priorities, and label it or assign it accordingly. '
     'This allows people to have a clearer picture of what work is actually planned. Thanks!';
  static const String willNeedAdditionalTriage = 'will need additional triage';
  static const Set<String> teams = <String>{
    // these are the teams that the self-test issue is assigned to
    'android',
    'codelabs',
    'design',
    'ecosystem',
    'engine',
    'framework',
    'games',
    'go_router',
    'infra',
    'ios',
    'linux',
    'macos',
    'news',
    'release',
    'text-input',
    'tool',
    'web',
    'windows',
  };
  static const int thumbsMinimum = 100; // an issue needs at least this many thumbs up to trigger retriage
  static const double thumbsThreshold = 2.0; // and the count must have increased by this factor since last triage
  static const Set<String> knownBots = <String>{ // we don't report events from bots to Discord
    'auto-submit[bot]',
    'DartDevtoolWorkflowBot',
    'dependabot[bot]',
    'engine-flutter-autoroll',
    'flutter-dashboard[bot]',
    'flutter-triage-bot[bot]', // that's us!
    'fluttergithubbot',
    'github-actions[bot]',
    'google-cla[bot]',
    'google-ospo-administrator[bot]',
    'skia-flutter-autoroll',
  };

  static bool isRelevantLabel(String label, { bool ignorePriorities = false }) {
    return label.startsWith(GitHubSettings.teamPrefix)
        || label.startsWith(GitHubSettings.triagedPrefix)
        || label.startsWith(GitHubSettings.fyiPrefix)
        || label == GitHubSettings.designDoc
        || label == GitHubSettings.permanentlyLocked
        || label == GitHubSettings.thumbsUpLabel
        || label == GitHubSettings.staleIssueLabel
        || (!ignorePriorities && GitHubSettings.priorities.contains(label));
  }
}

sealed class Timings {
  static const Duration backgroundUpdatePeriod = Duration(seconds: 1); // how long to wait between issues when scanning in the background
  static const Duration cleanupUpdateDelay = Duration(minutes: 45); // how long to wait for an issue to be idle before cleaning it up
  static const Duration cleanupUpdatePeriod = Duration(seconds: 60); // time between attempting to clean up the pending cleanup issues
  static const Duration longTermTidyingPeriod = Duration(hours: 5); // time between attempting to run long-term tidying of all issues
  static const Duration credentialsUpdatePeriod = Duration(minutes: 45); // how often to update GitHub credentials
  static const Duration timeUntilStale = Duration(days: 18 * 7); // how long since the last team interaction before considering an issue stale
  static const Duration timeUntilReallyStale = Duration(days: 29 * 7); // how long since the last team interaction before unassigning an issue
  static const Duration timeUntilUnlock = Duration(days: 28); // how long to leave open issues locked
  static const Duration selfTestPeriod = Duration(days: 6 * 7); // how often to file an issue to test the triage process
  static const Duration selfTestWindow = Duration(days: 18); // how long to leave the self-test issue open before assigning it to critical triage
  static const Duration refeedDelay = Duration(hours: 24); // how long between times we mark an issue as needing retriage (max 7 a week per team)
}

final class Secrets {
  Future<List<int>> get serverCertificate => _getSecret('server.cert.pem');
  Future<DateTime> get serverCertificateModificationDate => _getSecretModificationDate('server.cert.pem');
  Future<List<int>> get serverIntermediateCertificates => _getSecret('server.intermediates.pem');
  Future<DateTime> get serverIntermediateCertificatesModificationDate => _getSecretModificationDate('server.intermediates.pem');
  Future<List<int>> get serverKey => _getSecret('server.key.pem');
  Future<DateTime> get serverKeyModificationDate => _getSecretModificationDate('server.key.pem');
  Future<String> get discordToken async => utf8.decode(await _getSecret('discord.token'));
  Future<int> get discordAppId async => int.parse(utf8.decode(await _getSecret('discord.appid')));
  Future<List<int>> get githubWebhookSecret => _getSecret('github.webhook.secret');
  Future<String> get githubAppKey async => utf8.decode(await _getSecret('github.app.key.pem'));
  Future<String> get githubAppId async => utf8.decode(await _getSecret('github.app.id'));
  Future<String> get githubInstallationId async => utf8.decode(await _getSecret('github.installation.id'));
  final File store = File('store.db');

  static const String _projectId = 'xxxxx?????xxxxx'; // TODO(ianh): we should update this appropriately

  static File asFile(String name) => File('secrets/$name');

  static String asKey(String name) => 'projects/$_projectId/secrets/$name/versions/latest';

  static Future<List<int>> _getSecret(String name) async {
    final File file = asFile(name);
    if (await file.exists()) {
      return file.readAsBytes();
    }
    // authClientService is https://pub.dev/documentation/gcloud/latest/http/authClientService.html
    final SecretManagerApi secretManager = SecretManagerApi(authClientService);
    final String key = asKey(name);
    final AccessSecretVersionResponse response = await secretManager.projects.secrets.versions.access(key);
    return response.payload!.dataAsBytes;
  }

  static Future<DateTime> _getSecretModificationDate(String name) async {
    final File file = asFile(name);
    if (await file.exists()) {
      return file.lastModified();
    }
    // authClientService is https://pub.dev/documentation/gcloud/latest/http/authClientService.html
    final SecretManagerApi secretManager = SecretManagerApi(authClientService);
    final String key = asKey(name);
    final SecretVersion response = await secretManager.projects.secrets.versions.get(key);
    return DateTime.parse(response.createTime!);
  }
}

class IssueStats {
  IssueStats({
    this.lastContributorTouch,
    this.lastAssigneeTouch,
    Set<String>? labels,
    this.openedAt,
    this.lockedAt,
    this.assignedAt,
    this.assignedToTeamMemberReporter = false,
    this.triagedAt,
    this.thumbsAtTriageTime,
    this.thumbs = 0,
  }) : labels = labels ?? <String>{};

  factory IssueStats.read(FileReader reader) {
    return IssueStats(
      lastContributorTouch: reader.readNullOr<DateTime>(reader.readDateTime),
      lastAssigneeTouch: reader.readNullOr<DateTime>(reader.readDateTime),
      labels: reader.readSet<String>(reader.readString),
      openedAt: reader.readNullOr<DateTime>(reader.readDateTime),
      lockedAt: reader.readNullOr<DateTime>(reader.readDateTime),
      assignedAt: reader.readNullOr<DateTime>(reader.readDateTime),
      assignedToTeamMemberReporter: reader.readBool(),
      triagedAt: reader.readNullOr<DateTime>(reader.readDateTime),
      thumbsAtTriageTime: reader.readNullOr<int>(reader.readInt),
      thumbs: reader.readInt(),
    );
  }

  static void write(FileWriter writer, IssueStats value) {
    writer.writeNullOr<DateTime>(value.lastContributorTouch, writer.writeDateTime);
    writer.writeNullOr<DateTime>(value.lastAssigneeTouch, writer.writeDateTime);
    writer.writeSet<String>(writer.writeString, value.labels);
    writer.writeNullOr<DateTime>(value.openedAt, writer.writeDateTime);
    writer.writeNullOr<DateTime>(value.lockedAt, writer.writeDateTime);
    writer.writeNullOr<DateTime>(value.assignedAt, writer.writeDateTime);
    writer.writeBool(value.assignedToTeamMemberReporter);
    writer.writeNullOr<DateTime>(value.triagedAt, writer.writeDateTime);
    writer.writeNullOr<int>(value.thumbsAtTriageTime, writer.writeInt);
    writer.writeInt(value.thumbs);
  }

  DateTime? lastContributorTouch;
  DateTime? lastAssigneeTouch;
  Set<String> labels;
  DateTime? openedAt;
  DateTime? lockedAt;
  DateTime? assignedAt;
  bool assignedToTeamMemberReporter = false;
  DateTime? triagedAt;
  int? thumbsAtTriageTime;
  int thumbs;

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer();
    buffer.write('{${(labels.toList()..sort()).join(', ')}} and $thumbs 👍');
    if (openedAt != null) {
      buffer.write('; openedAt: $openedAt');
    }
    if (lastContributorTouch != null) {
      buffer.write('; lastContributorTouch: $lastContributorTouch');
    } else {
      buffer.write('; lastContributorTouch: never');
    }
    if (assignedAt != null) {
      buffer.write('; assignedAt: $assignedAt');
      if (assignedToTeamMemberReporter) {
        buffer.write(' (to team-member reporter)');
      }
      if (lastAssigneeTouch != null) {
        buffer.write('; lastAssigneeTouch: $lastAssigneeTouch');
      } else {
        buffer.write('; lastAssigneeTouch: never');
      }
    } else {
      if (lastAssigneeTouch != null) {
        buffer.write('; lastAssigneeTouch: $lastAssigneeTouch (?!)');
      }
      if (assignedToTeamMemberReporter) {
        buffer.write('; assigned to team-member reporter (?!)');
      }
    }
    if (lockedAt != null) {
      buffer.write('; lockedAt: $lockedAt');
    }
    if (triagedAt != null) {
      buffer.write('; triagedAt: $triagedAt');
      if (thumbsAtTriageTime != null) {
        buffer.write(' with $thumbsAtTriageTime 👍');
      }
    } else {
      if (thumbsAtTriageTime != null) {
        buffer.write('; not triaged with $thumbsAtTriageTime 👍 when triaged (?!)');
      }
    }
    return buffer.toString();
  }
}

typedef StoreFields = ({
  Map<int, IssueStats> issues,
  Map<int, DateTime> pendingCleanupIssues,
  int? selfTestIssue,
  DateTime? selfTestClosedDate,
  int currentBackgroundIssue,
  int highestKnownIssue,
  Map<String, DateTime> lastRefeedByTime,
  DateTime? lastCleanupStart,
  DateTime? lastCleanupEnd,
  DateTime? lastTidyStart,
  DateTime? lastTidyEnd,
});

class Engine {
  Engine._({
    required this.webhookSecret,
    required this.discord,
    required this.github,
    required this.secrets,
    required Set<String> contributors,
    required StoreFields? store,
  }) : _contributors = contributors,
       _issues = store?.issues ?? <int, IssueStats>{},
       _pendingCleanupIssues = store?.pendingCleanupIssues ?? <int, DateTime>{},
       _selfTestIssue = store?.selfTestIssue,
       _selfTestClosedDate = store?.selfTestClosedDate,
       _currentBackgroundIssue = store?.currentBackgroundIssue ?? 1,
       _highestKnownIssue = store?.highestKnownIssue ?? 1,
       _lastRefeedByTime = store?.lastRefeedByTime ?? <String, DateTime>{},
       _lastCleanupStart = store?.lastCleanupStart,
       _lastCleanupEnd = store?.lastCleanupEnd,
       _lastTidyStart = store?.lastTidyStart,
       _lastTidyEnd = store?.lastTidyEnd {
    _startup = DateTime.timestamp();
    scheduleMicrotask(_updateStoreInBackground);
    _nextCleanup = (_lastCleanupEnd ?? _startup).add(Timings.cleanupUpdatePeriod);
    _cleanupTimer = Timer(_nextCleanup.difference(_startup), _performCleanups);
    _nextTidy = (_lastTidyEnd ?? _startup).add(Timings.longTermTidyingPeriod);
    _tidyTimer = Timer(_nextTidy.difference(_startup), _performLongTermTidying);
    log('Startup');
  }

  static Future<Engine> initialize({
    required List<int> webhookSecret,
    required INyxx discord,
    required GitHub github,
    void Function()? onChange,
    required Secrets secrets,
  }) async {
    return Engine._(
      webhookSecret: webhookSecret,
      discord: discord,
      github: github,
      secrets: secrets,
      contributors: await _loadContributors(github),
      store: await _read(secrets),
    );
  }

  final List<int> webhookSecret;
  final INyxx discord;
  final GitHub github;
  final Secrets secrets;

  // data this is stored on local disk
  final Set<String> _contributors;
  final Map<int, IssueStats> _issues;
  final Map<int, DateTime> _pendingCleanupIssues;
  int? _selfTestIssue;
  DateTime? _selfTestClosedDate;
  int _currentBackgroundIssue;
  int _highestKnownIssue;
  final Map<String, DateTime> _lastRefeedByTime; // last time we forced an otherwise normal issue to get retriaged by each team

  final Set<String> _recentIds = <String>{}; // used to detect duplicate messages and discard them
  final List<String> _log = <String>[];
  late final DateTime _startup;
  DateTime? _lastCleanupStart;
  DateTime? _lastCleanupEnd;
  late DateTime _nextCleanup;
  Timer? _cleanupTimer;
  DateTime? _lastTidyStart;
  DateTime? _lastTidyEnd;
  late DateTime _nextTidy;
  Timer? _tidyTimer;

  void log(String message) {
    stderr.writeln(message);
    _log.add('${DateTime.timestamp().toIso8601String()} $message');
    while (_log.length > maxLogLength) {
      _log.removeAt(0);
    }
  }

  int _actives = 0;
  bool _shuttingDown = false;
  Completer<void> _pendingIdle = Completer<void>();
  Future<void> shutdown(Future<void> Function() shutdownCallback) async {
    assert(!_shuttingDown, 'shutdown called reentrantly');
    _shuttingDown = true;
    while (_actives > 0) {
      await _pendingIdle.future;
    }
    return shutdownCallback();
  }

  static Future<Set<String>> _loadContributors(GitHub github) async {
    final int teamId = (await github.organizations.getTeamByName(GitHubSettings.organization, GitHubSettings.teamName)).id!;
    return github.organizations.listTeamMembers(teamId).map((TeamMember member) => member.login!).toSet();
  }

  static Future<StoreFields?> _read(Secrets secrets) async {
    if (await secrets.store.exists()) {
      try {
        final FileReader reader = FileReader((await secrets.store.readAsBytes()).buffer.asByteData());
        return (
          issues: reader.readMap<int, IssueStats>(reader.readInt, reader.readerForCustom<IssueStats>(IssueStats.read)),
          pendingCleanupIssues: reader.readMap<int, DateTime>(reader.readInt, reader.readDateTime),
          selfTestIssue: reader.readNullOr<int>(reader.readInt),
          selfTestClosedDate: reader.readNullOr<DateTime>(reader.readDateTime),
          currentBackgroundIssue: reader.readInt(),
          highestKnownIssue: reader.readInt(),
          lastRefeedByTime: reader.readMap<String, DateTime>(reader.readString, reader.readDateTime),
          lastCleanupStart: reader.readNullOr<DateTime>(reader.readDateTime),
          lastCleanupEnd: reader.readNullOr<DateTime>(reader.readDateTime),
          lastTidyStart: reader.readNullOr<DateTime>(reader.readDateTime),
          lastTidyEnd: reader.readNullOr<DateTime>(reader.readDateTime),
        );
      } catch (e) {
        print('Error loading issue store, consider deleting ${secrets.store.path} file.');
        rethrow;
      }
    }
    return null;
  }

  bool _writing = false;
  bool _dirty = false;
  Future<void> _write() async {
    if (_writing) {
      _dirty = true;
      return;
    }
    try {
      _writing = true;
      final FileWriter writer = FileWriter();
      writer.writeMap<int, IssueStats>(writer.writeInt, writer.writerForCustom<IssueStats>(IssueStats.write), _issues);
      writer.writeMap<int, DateTime>(writer.writeInt, writer.writeDateTime, _pendingCleanupIssues);
      writer.writeNullOr<int>(_selfTestIssue, writer.writeInt);
      writer.writeNullOr<DateTime>(_selfTestClosedDate, writer.writeDateTime);
      writer.writeInt(_currentBackgroundIssue);
      writer.writeInt(_highestKnownIssue);
      writer.writeMap<String, DateTime>(writer.writeString, writer.writeDateTime, _lastRefeedByTime);
      writer.writeNullOr<DateTime>(_lastCleanupStart, writer.writeDateTime);
      writer.writeNullOr<DateTime>(_lastCleanupEnd, writer.writeDateTime);
      writer.writeNullOr<DateTime>(_lastTidyStart, writer.writeDateTime);
      writer.writeNullOr<DateTime>(_lastTidyEnd, writer.writeDateTime);
      await writer.write(secrets.store);
    } finally {
      _writing = false;
    }
    if (_dirty) {
      _dirty = false;
      return _write();
    }
  }

  // the maxFraction argument represents the fraction of the total rate limit that is allowed to be
  // used before waiting.
  //
  // the background update code sets it to 0.5 so that there is still a buffer for the other calls,
  // otherwise the background update code could just use it all up and then stall everything else.
  Future<void> _githubReady([double maxFraction = 0.95]) async {
    if (github.rateLimitRemaining != null && github.rateLimitRemaining! < (github.rateLimitLimit! * (1.0 - maxFraction)).round()) {
      assert(github.rateLimitReset != null);
      await _until(github.rateLimitReset!);
    }
  }

  static Future<void> _until(DateTime target) {
    final DateTime now = DateTime.timestamp();
    if (!now.isBefore(target)) {
      return Future<void>.value();
    }
    final Duration delta = target.difference(now);
    return Future<void>.delayed(delta);
  }

  Future<void> handleRequest(HttpRequest request) async {
    _actives += 1;
    try {
      try {
        if (await _handleDebugRequests(request)) {
          return;
        }
        final List<int> bytes = await request.expand((Uint8List sublist) => sublist).toList();
        final String expectedSignature = 'sha256=${Hmac(sha256, webhookSecret).convert(bytes).bytes.map(hex).join()}';
        final List<String> actualSignatures = request.headers['X-Hub-Signature-256'] ?? const <String>[];
        final List<String> eventKind = request.headers['X-GitHub-Event'] ?? const <String>[];
        final List<String> eventId = request.headers['X-GitHub-Delivery'] ?? const <String>[];
        if (actualSignatures.length != 1 || expectedSignature != actualSignatures.single ||
            eventKind.length != 1 || eventId.length != 1) {
          request.response.writeln('Invalid metadata.');
          return;
        }
        if (_recentIds.contains(eventId.single)) {
          request.response.writeln('I got that one already.');
          return;
        }
        _recentIds.add(eventId.single);
        while (_recentIds.length > 50) {
          _recentIds.remove(_recentIds.first);
        }
        final dynamic payload = Json.parse(utf8.decode(bytes));
        await _updateModelFromWebhook(eventKind.single, payload);
        await _updateDiscordFromWebhook(eventKind.single, payload);
        request.response.writeln('Acknowledged.');
      } catch (e, s) {
        log('Failed to handle ${request.uri}: $e (${e.runtimeType})\n$s');
      } finally {
        await request.response.close();
      }
    } finally {
      _actives -= 1;
      if (_shuttingDown && _actives == 0) {
        _pendingIdle.complete();
        _pendingIdle = Completer<void>();
      }
    }
  }

  Future<bool> _handleDebugRequests(HttpRequest request) async {
    if (request.uri.path == '/debug') {
      final DateTime now = DateTime.timestamp();
      request.response.writeln('FLUTTER TRIAGE BOT');
      request.response.writeln('==================');
      request.response.writeln();
      request.response.writeln('Current time: $now');
      request.response.writeln('Uptime: ${now.difference(_startup)} (startup at $_startup).');
      request.response.writeln('Cleaning: ${_cleaning ? "active" : "pending"} (${_pendingCleanupIssues.length} issue${s(_pendingCleanupIssues.length)}); last started $_lastCleanupStart, last ended $_lastCleanupEnd, next in ${_nextCleanup.difference(now)}.');
      request.response.writeln('Tidying: ${_tidying ? "active" : "pending"}; last started $_lastTidyStart, last ended $_lastTidyEnd, next in ${_nextTidy.difference(now)}.');
      request.response.writeln('Background scan: currently fetching issue #$_currentBackgroundIssue, highest known issue #$_highestKnownIssue.');
      request.response.writeln('${_contributors.length} known contributor${s(_contributors.length)}.');
      request.response.writeln('GitHub Rate limit status: ${github.rateLimitRemaining}/${github.rateLimitLimit} (reset at ${github.rateLimitReset})');
      if (_selfTestIssue != null) {
        request.response.writeln('Current self test issue: #$_selfTestIssue');
      }
      if (_selfTestClosedDate != null) {
        request.response.writeln('Self test last closed on: $_selfTestClosedDate (${now.difference(_selfTestClosedDate!)} ago, next in ${_selfTestClosedDate!.add(Timings.selfTestPeriod).difference(now)})');
      }
      request.response.writeln();
      request.response.writeln('Last refeeds (refeed delay: ${Timings.refeedDelay}):');
      for (final String team in _lastRefeedByTime.keys.toList()..sort((String a, String b) => _lastRefeedByTime[a]!.compareTo(_lastRefeedByTime[b]!))) {
        final Duration delta = now.difference(_lastRefeedByTime[team]!);
        final String annotation = delta > Timings.refeedDelay
                                ? ''
                                : '; blocking immediate refeeds';
        request.response.writeln('${team.padRight(30, '.')}.${_lastRefeedByTime[team]} ($delta ago$annotation)');
      }
      request.response.writeln();
      request.response.writeln('Tracking ${_issues.length} issue${s(_issues.length)}:');
      for (final int number in _issues.keys.toList()..sort()) {
        String cleanup = '';
        if (_pendingCleanupIssues.containsKey(number)) {
          final Duration delta = Timings.cleanupUpdateDelay - now.difference(_pendingCleanupIssues[number]!);
          if (delta < Duration.zero) {
            cleanup = ' [cleanup pending]';
          } else if (delta.inMinutes <= 1) {
            cleanup = ' [cleanup soon]';
          } else {
            cleanup = ' [cleanup in ${delta.inMinutes} minute${s(delta.inMinutes)}]';
          }
        }
        request.response.writeln('  #${number.toString().padLeft(6, "0")}: ${_issues[number]}$cleanup');
      }
      request.response.writeln();
      request.response.writeln('LOG');
      _log.forEach(request.response.writeln);
      return true;
    }
    if (request.uri.path == '/force-update') {
      final int number = int.parse(request.uri.query); // if input is not an integer, this'll throw
      await _updateStoreInBackgroundForIssue(number);
      request.response.writeln('${_issues[number]}');
      return true;
    }
    if (request.uri.path == '/force-cleanup') {
      log('User-triggered forced cleanup');
      await _performCleanups();
      _log.forEach(request.response.writeln);
      return true;
    }
    if (request.uri.path == '/force-tidy') {
      log('User-triggered forced tidy');
      await _performLongTermTidying();
      _log.forEach(request.response.writeln);
      return true;
    }
    return false;
  }

  // Called when we get a webhook message.
  Future<void> _updateModelFromWebhook(String event, dynamic payload) async {
    final DateTime now = DateTime.timestamp();
    switch (event) {
      case 'issue_comment':
        if (!payload.issue.hasKey('pull_request') && payload.repository.full_name.toString() == GitHubSettings.primaryRepository.fullName) {
          _updateIssueFromWebhook(payload.sender.login.toString(), payload.issue, now);
        }
      case 'issues':
        if (payload.repository.full_name.toString() != GitHubSettings.primaryRepository.fullName) {
          return;
        }
        if (payload.action.toString() == 'closed') {
          final int number = payload.issue.number.toInt();
          _issues.remove(number);
          _pendingCleanupIssues.remove(number);
          if (number == _selfTestIssue) {
            _selfTestIssue = null;
            _selfTestClosedDate = now;
          }
        } else {
          final IssueStats? issue = _updateIssueFromWebhook(payload.sender.login.toString(), payload.issue, now);
          if (issue != null) {
            if (payload.action.toString() == 'assigned') {
              // if we are adding a second assignee, _updateIssueFromWebhook won't update the assignedAt timestamp
              _issues[payload.issue.number.toInt()]!.assignedAt = now;
            } else if (payload.action.toString() == 'opened' || payload.action.toString() == 'reopened') {
              _issues[payload.issue.number.toInt()]!.openedAt = now;
            } else if (payload.action.toString() == 'labeled') {
              final String label = payload.label.name.toString();
              final String? team = getTeamFor(GitHubSettings.triagedPrefix, label);
              if (team != null) {
                final Set<String> teams = getTeamsFor(GitHubSettings.teamPrefix, issue.labels);
                if (teams.length == 1) {
                  if (teams.single == team) {
                    issue.triagedAt = now;
                  }
                }
              }
            }
          }
        }
      case 'membership':
        if (payload.team.slug.toString() == '${GitHubSettings.organization}/${GitHubSettings.teamName}') {
          switch (payload.action.toString()) {
            case 'added':
              _contributors.add(payload.member.login.toString());
            case 'removed':
              _contributors.remove(payload.member.login.toString());
          }
        }
    }
    await _write();
  }

  // Called when we get a webhook message that we've established is an
  // interesting update to an issue.
  // Attempts to build up and/or update the data for an issue based on
  // the data in a change event. This will be approximate until we can actually
  // scan the issue properly in _updateStoreInBackground.
  IssueStats? _updateIssueFromWebhook(String user, dynamic data, DateTime now) {
    final int number = data.number.toInt();
    if (number > _highestKnownIssue) {
      _highestKnownIssue = number;
    }
    if (data.state.toString() == 'closed') {
      _issues.remove(number);
      _pendingCleanupIssues.remove(number);
      if (number == _selfTestIssue) {
        _selfTestIssue = null;
        _selfTestClosedDate = now;
      }
      return null;
    }
    final IssueStats issue = _issues.putIfAbsent(number, IssueStats.new);
    final Set<String> newLabels = <String>{};
    for (final dynamic label in data.labels.asIterable()) {
      final String name = label.name.toString();
      if (GitHubSettings.isRelevantLabel(name)) {
        newLabels.add(name);
      }
    }
    issue.labels = newLabels;
    final Set<String> assignees = <String>{};
    for (final dynamic assignee in data.assignees.asIterable()) {
      assignees.add(assignee.login.toString());
    }
    final String reporter = data.user.login.toString();
    if (assignees.isEmpty) {
      issue.lastAssigneeTouch = null;
      issue.assignedAt = null;
      issue.assignedToTeamMemberReporter = false;
    } else {
      issue.assignedAt ??= now;
      if (assignees.contains(user)) {
        issue.lastAssigneeTouch = now;
      }
      issue.assignedToTeamMemberReporter = assignees.contains(reporter) && _contributors.contains(reporter);
    }
    if (_contributors.contains(user)) {
      issue.lastContributorTouch = now;
    }
    if (!data.locked.toBoolean()) {
      issue.lockedAt = null;
    } else {
      issue.lockedAt ??= now;
    }
    final Set<String> teams = getTeamsFor(GitHubSettings.triagedPrefix, newLabels);
    if (teams.isEmpty) {
      issue.thumbsAtTriageTime = null;
      issue.triagedAt = null;
    }
    _pendingCleanupIssues[number] = now;
    return issue;
  }

  Future<void> _updateDiscordFromWebhook(String event, dynamic payload) async {
    if (GitHubSettings.knownBots.contains(payload.sender.login.toString())) {
      return;
    }
    switch (event) {
      case 'star':
        switch (payload.action.toString()) {
          case 'created':
            await sendDiscordMessage(
              discord: discord,
              body: '**@${payload.sender.login}** starred ${payload.repository.full_name}',
              channel: DiscordChannels.github2,
              emoji: UnicodeEmoji('🌟'),
              log: log,
            );
        }
      case 'label':
        switch (payload.action.toString()) {
          case 'created':
            String message;
            if (payload.label.description.toString().isEmpty) {
              message = '**@${payload.sender.login}** created a new label in ${payload.repository.full_name}, `${payload.label.name}`, but did not give it a description!';
            } else {
              message = '**@${payload.sender.login}** created a new label in ${payload.repository.full_name}, `${payload.label.name}`, with the description "${payload.label.description}".';
            }
            await sendDiscordMessage(
              discord: discord,
              body: message,
              channel: DiscordChannels.hiddenChat,
              embedTitle: '${payload.label.name}',
              embedDescription: '${payload.label.description}',
              embedColor: '${payload.label.color}',
              log: log,
            );
        }
      case 'pull_request':
        switch (payload.action.toString()) {
          case 'closed':
            final bool merged = payload.pull_request.merged_at.toScalar() != null;
            await sendDiscordMessage(
              discord: discord,
              body: '**@${payload.sender.login}** ${ merged ? "merged" : "closed" } *${payload.pull_request.title}* (${payload.pull_request.html_url})',
              channel: DiscordChannels.github2,
              log: log,
            );
          case 'opened':
            await sendDiscordMessage(
              discord: discord,
              body: '**@${payload.sender.login}** submitted a new pull request: **${payload.pull_request.title}** (${payload.repository.full_name} #${payload.pull_request.number.toInt()})\n${stripBoilerplate(payload.pull_request.body.toString())}',
              suffix: '*${payload.pull_request.html_url}*',
              channel: DiscordChannels.github2,
              log: log,
            );
        }
      case 'pull_request_review':
        switch (payload.action.toString()) {
          case 'submitted':
            switch (payload.review.state.toString()) {
              case 'approved':
                await sendDiscordMessage(
                  discord: discord,
                  body: payload.review.body.toString().isEmpty ?
                    '**@${payload.sender.login}** gave **LGTM** for *${payload.pull_request.title}* (${payload.pull_request.html_url})' :
                    '**@${payload.sender.login}** gave **LGTM** for *${payload.pull_request.title}* (${payload.pull_request.html_url}): ${stripBoilerplate(payload.review.body.toString(), inline: true)}',
                  channel: DiscordChannels.github2,
                  log: log,
                );
            }
        }
      case 'pull_request_review_comment':
        await sendDiscordMessage(
          discord: discord,
          body: '**@${payload.sender.login}** wrote: ${stripBoilerplate(payload.comment.body.toString(), inline: true)}',
          suffix: '*${payload.comment.html_url} ${payload.pull_request.title}*',
          channel: DiscordChannels.github2,
          log: log,
        );
      case 'issue_comment':
        switch (payload.action.toString()) {
          case 'created':
            await sendDiscordMessage(
              discord: discord,
              body: '**@${payload.sender.login}** wrote: ${stripBoilerplate(payload.comment.body.toString(), inline: true)}',
              suffix: '*${payload.comment.html_url} ${payload.issue.title}*',
              channel: DiscordChannels.github2,
              log: log,
            );
        }
      case 'issues':
        switch (payload.action.toString()) {
          case 'closed':
            await sendDiscordMessage(
              discord: discord,
              body: '**@${payload.sender.login}** closed *${payload.issue.title}* (${payload.issue.html_url})',
              channel: DiscordChannels.github2,
              log: log,
            );
          case 'reopened':
            await sendDiscordMessage(
              discord: discord,
              body: '**@${payload.sender.login}** reopened *${payload.issue.title}* (${payload.issue.html_url})',
              channel: DiscordChannels.github2,
              log: log,
            );
          case 'opened':
            await sendDiscordMessage(
              discord: discord,
              body: '**@${payload.sender.login}** filed a new issue: **${payload.issue.title}** (${payload.repository.full_name} #${payload.issue.number.toInt()})\n${stripBoilerplate(payload.issue.body.toString())}',
              suffix: '*${payload.issue.html_url}*',
              channel: DiscordChannels.github2,
              log: log,
            );
            bool isDesignDoc = false;
            for (final dynamic label in payload.issue.labels.asIterable()) {
              final String name = label.name.toString();
              if (name == GitHubSettings.designDoc) {
                isDesignDoc = true;
                break;
              }
            }
            if (isDesignDoc) {
              await sendDiscordMessage(
                discord: discord,
                body: '**@${payload.sender.login}** wrote a new design doc: **${payload.issue.title}**\n${stripBoilerplate(payload.issue.body.toString())}',
                suffix: '*${payload.issue.html_url}*',
                channel: DiscordChannels.hiddenChat,
                log: log,
              );
            }
          case 'locked':
          case 'unlocked':
            await sendDiscordMessage(
              discord: discord,
              body: '**@${payload.sender.login}** ${payload.action} ${payload.issue.html_url} - ${payload.issue.title}',
              channel: DiscordChannels.github2,
              log: log,
            );
        }
      case 'membership':
        await sendDiscordMessage(
          discord: discord,
          body: '**@${payload.sender.login}** ${payload.action} user **@${payload.member.login}** (${payload.team.name})',
          channel: DiscordChannels.github2,
          log: log,
        );
      case 'gollum':
        for (final dynamic page in payload.pages.asIterable()) {
          // sadly the commit message doesn't get put into the event payload
          await sendDiscordMessage(
            discord: discord,
            body: '**@${payload.sender.login}** ${page.action} the **${page.title}** wiki page',
            suffix: '*${page.html_url}*',
            channel: DiscordChannels.github2,
            log: log,
          );
        }
    }
  }

  // This is called every few seconds to update one issue in our store.
  // We do this because (a) initially, we don't have any data so we need
  // to fill our database somehow, and (b) thereafter, we might go out of
  // sync if we miss an event, e.g. due to network issues.
  Future<void> _updateStoreInBackground() async {
    await _updateStoreInBackgroundForIssue(_currentBackgroundIssue);
    _currentBackgroundIssue -= 1;
    if (_currentBackgroundIssue <= 0) {
      _currentBackgroundIssue = _highestKnownIssue;
    }
    await _write();
    await Future<void>.delayed(Timings.backgroundUpdatePeriod);
    scheduleMicrotask(_updateStoreInBackground);
  }

  Future<void> _updateStoreInBackgroundForIssue(int number) async {
    try {
      await _githubReady(0.5);
      final Issue githubIssue = await github.issues.get(GitHubSettings.primaryRepository, number);
      if (githubIssue.pullRequest == null && githubIssue.isOpen) {
        final String? reporter = githubIssue.user?.login;
        bool open = true;
        final Set<String> assignees = <String>{};
        final Set<String> labels = <String>{};
        DateTime? lastContributorTouch;
        DateTime? lastAssigneeTouch;
        DateTime? openedAt = githubIssue.createdAt;
        DateTime? lockedAt;
        DateTime? assignedAt;
        DateTime? triagedAt;
        DateTime? lastChange;
        await _githubReady();
        await for (final TimelineEvent event in github.issues.listTimeline(GitHubSettings.primaryRepository, number)) {
          String? user;
          DateTime? time;
          // event.actor could be null if the original user was deleted (shows as "ghost" in GitHub's web UI)
          // see e.g. https://github.com/flutter/flutter/issues/93070
          switch (event.event) {
            case 'renamed': // The issue or pull request title was changed.
            case 'commented':
              user = event.actor?.login;
              time = event.createdAt;
            case 'locked': // The issue or pull request was locked.
              user = event.actor?.login;
              time = event.createdAt;
              lockedAt = time;
            case 'unlocked': // The issue was unlocked.
              user = event.actor?.login;
              time = event.createdAt;
              lockedAt = null;
            case 'assigned':
              event as AssigneeEvent;
              if (event.assignee != null && event.assignee!.login != null) {
                user = event.actor?.login;
                time = event.createdAt;
                assignees.add(event.assignee!.login!);
                assignedAt = time;
              }
            case 'unassigned':
              event as AssigneeEvent;
              user = event.actor?.login;
              time = event.createdAt;
              if (event.assignee != null) {
                assignees.remove(event.assignee!.login);
                if (assignees.isEmpty) {
                  assignedAt = null;
                  lastAssigneeTouch = null;
                }
              }
            case 'labeled':
              event as LabelEvent;
              user = event.actor?.login;
              time = event.createdAt;
              final String label = event.label!.name;
              if (GitHubSettings.isRelevantLabel(label, ignorePriorities: true)) {
                // we add the priority labels later to avoid confusion from the renames
                labels.add(label);
              }
              final String? triagedTeam = getTeamFor(GitHubSettings.triagedPrefix, label);
              if (triagedTeam != null) {
                final Set<String> teams = getTeamsFor(GitHubSettings.teamPrefix, labels);
                if (teams.length == 1 && teams.single == triagedTeam) {
                  triagedAt = event.createdAt;
                }
              }
            case 'unlabeled':
              event as LabelEvent;
              user = event.actor?.login;
              time = event.createdAt;
              final String label = event.label!.name;
              labels.remove(label);
              final Set<String> teams = getTeamsFor(GitHubSettings.teamPrefix, labels);
              final Set<String> triagedTeams = getTeamsFor(GitHubSettings.triagedPrefix, labels);
              if (teams.intersection(triagedTeams).isEmpty) {
                triagedAt = null;
              }
            case 'closed':
              user = event.actor?.login;
              time = event.createdAt;
              open = false;
            case 'reopened':
              user = event.actor?.login;
              time = event.createdAt;
              openedAt = event.createdAt;
              open = true;
          }
          if (user != null) {
            assert(time != null);
            if (_contributors.contains(user)) {
              lastContributorTouch = time;
            }
            if (assignees.contains(user)) {
              lastAssigneeTouch = time;
            }
          }
          if (lastChange == null || (time != null && time.isAfter(lastChange))) {
            lastChange = time;
          }
          await _githubReady();
        }
        if (open) {
          // Because we renamed some of the labels, we can't trust the
          // historical names we get from the timeline. We have to use the
          // actual current labels from the githubIssue.
          // Also, there might be missing labels because the timeline doesn't
          // include the issue's original labels from when the issue was filed.
          final Set<String> actualLabels = githubIssue.labels
            .map<String>((IssueLabel label) => label.name)
            .where(GitHubSettings.isRelevantLabel)
            .toSet();
          for (final String label in actualLabels.difference(labels)) {
            // could have been renamed, but let's assume it was added when the issue was created (and never removed).
            final String? triagedTeam = getTeamFor(GitHubSettings.triagedPrefix, label);
            if (triagedTeam != null) {
              final Set<String> teams = getTeamsFor(GitHubSettings.teamPrefix, actualLabels);
              if (teams.length == 1 && teams.single == triagedTeam) {
                triagedAt = openedAt;
              }
            }
          }
          final IssueStats issue = _issues.putIfAbsent(number, IssueStats.new);
          issue.lastContributorTouch = lastContributorTouch;
          issue.lastAssigneeTouch = lastAssigneeTouch;
          issue.labels = actualLabels;
          issue.openedAt = openedAt;
          issue.lockedAt = lockedAt;
          assert((assignedAt != null) == (assignees.isNotEmpty));
          issue.assignedAt = assignedAt;
          issue.assignedToTeamMemberReporter = reporter != null && assignees.contains(reporter) && _contributors.contains(reporter);
          issue.thumbs = githubIssue.reactions?.plusOne ?? 0;
          issue.triagedAt = triagedAt;
          if (triagedAt != null) {
            if (issue.thumbsAtTriageTime == null) {
              int thumbsAtTriageTime = 0;
              await _githubReady();
              await for (final Reaction reaction in github.issues.listReactions(GitHubSettings.primaryRepository, number)) {
                if (reaction.createdAt != null && reaction.createdAt!.isAfter(triagedAt)) {
                  break;
                }
                if (reaction.content == '+1') {
                  thumbsAtTriageTime += 1;
                }
                await _githubReady();
              }
              issue.thumbsAtTriageTime = thumbsAtTriageTime;
            }
          } else {
            issue.thumbsAtTriageTime = null;
          }
        } else {
          _issues.remove(number);
          _pendingCleanupIssues.remove(number);
        }
        if (!_pendingCleanupIssues.containsKey(number)) {
          _pendingCleanupIssues[number] = lastChange ?? DateTime.timestamp();
        }
      } else {
        if (_selfTestIssue == number) {
          _selfTestIssue = null;
          _selfTestClosedDate = githubIssue.closedAt;
        }
      }
    } on NotFound {
      _issues.remove(number);
      _pendingCleanupIssues.remove(number);
    } catch (e, s) {
      log('Failed to perform background update of issue #$number: $e (${e.runtimeType})\n$s');
    }
  }

  bool _cleaning = false;
  // This is called periodically to look at recently-updated issues.
  // This lets us enforce invariants but only after humans have had a chance
  // to do whatever it is they are doing on the issue.
  Future<void> _performCleanups([Timer? timer]) async {
    final DateTime now = DateTime.timestamp();
    _cleanupTimer?.cancel();
    _nextCleanup = now.add(Timings.cleanupUpdatePeriod);
    _cleanupTimer = Timer(Timings.cleanupUpdatePeriod, _performCleanups);
    if (_cleaning) {
      return;
    }
    try {
      _cleaning = true;
      _lastCleanupStart = now;
      final DateTime refeedThreshold = now.subtract(Timings.refeedDelay);
      final DateTime cleanupThreshold = now.subtract(Timings.cleanupUpdateDelay);
      final DateTime staleThreshold = now.subtract(Timings.timeUntilStale);
      final List<int> issues = _pendingCleanupIssues.keys.toList();
      for (final int number in issues) {
        try {
          if (_pendingCleanupIssues.containsKey(number) && _pendingCleanupIssues[number]!.isBefore(cleanupThreshold)) {
            assert(_issues.containsKey(number));
            final IssueStats issue = _issues[number]!;
            final Set<String> labelsToRemove = <String>{};
            final List<String> messages = <String>[];
            // PRIORITY LABELS
            final Set<String> priorities = issue.labels.intersection(GitHubSettings.priorities);
            if (priorities.length > 1) {
              // When an issue has multiple priorities, remove all but the highest.
              for (final String priority in GitHubSettings.priorities.toList().reversed) {
                if (priorities.contains(priority)) {
                  labelsToRemove.add(priority);
                  priorities.remove(priority);
                }
                if (priorities.length == 1) {
                  break;
                }
              }
            }
            // TEAM LABELS
            final Set<String> teams = getTeamsFor(GitHubSettings.teamPrefix, issue.labels);
            final Set<String> triaged = getTeamsFor(GitHubSettings.triagedPrefix, issue.labels);
            final Set<String> fyi = getTeamsFor(GitHubSettings.fyiPrefix, issue.labels);
            if (teams.length > 1 && number != _selfTestIssue) {
              // Issues should only have a single "team-foo" label.
              // When this is violated, we remove all of them to send the issue back to front-line triage.
              messages.add(
                'Issue is assigned to multiple teams (${teams.join(", ")}). '
                'Please ensure the issue has only one `${GitHubSettings.teamPrefix}*` label at a time. '
                'Use `${GitHubSettings.fyiPrefix}*` labels to have another team look at the issue without reassigning it.'
              );
              for (final String team in teams) {
                labelsToRemove.add('${GitHubSettings.teamPrefix}$team');
                // Also remove the labels we'd end up removing below, to avoid having confusing messages.
                if (triaged.contains(team)) {
                  labelsToRemove.add('${GitHubSettings.triagedPrefix}$team');
                  triaged.remove(team);
                }
                if (fyi.contains(team)) {
                  labelsToRemove.add('${GitHubSettings.fyiPrefix}$team');
                  fyi.remove(team);
                }
              }
              teams.clear();
            }
            for (final String team in fyi.toList()) {
              if (teams.contains(team)) {
                // Remove redundant fyi-* labels.
                messages.add('The `${GitHubSettings.fyiPrefix}$team` label is redundant with the `${GitHubSettings.teamPrefix}$team` label.');
                labelsToRemove.add('${GitHubSettings.fyiPrefix}$team');
                fyi.remove(team);
              } else if (triaged.contains(team)) {
                // If an fyi-* label has been acknowledged by a triaged-* label, we can remove them both.
                labelsToRemove.add('${GitHubSettings.fyiPrefix}$team');
                labelsToRemove.add('${GitHubSettings.triagedPrefix}$team');
                fyi.remove(team);
                triaged.remove(team);
              }
            }
            for (final String team in triaged.toList()) {
              // Remove redundant triaged-* labels.
              if (!teams.contains(team)) {
                messages.add(
                  'The `${GitHubSettings.triagedPrefix}$team` label is irrelevant if '
                  'there is no `${GitHubSettings.teamPrefix}$team` label or `${GitHubSettings.fyiPrefix}$team` label.'
                );
                labelsToRemove.add('${GitHubSettings.triagedPrefix}$team');
                triaged.remove(team);
              }
            }
            assert(teams.length <= 1 || number == _selfTestIssue);
            assert(triaged.length <= teams.length);
            if (triaged.isNotEmpty && priorities.isEmpty && number != _selfTestIssue) {
              assert(triaged.length == 1);
              final String team = triaged.single;
              if (!_lastRefeedByTime.containsKey(team) || _lastRefeedByTime[team]!.isBefore(refeedThreshold)) {
                messages.add(
                  'This issue is missing a priority label. '
                  'Please set a priority label when adding the `${GitHubSettings.triagedPrefix}$team` label.'
                );
                _lastRefeedByTime[team] = now;
                labelsToRemove.add('${GitHubSettings.triagedPrefix}$team');
                triaged.remove(team);
                assert(triaged.isEmpty);
              }
            }
            // STALE THUMBS UP LABEL
            if (triaged.isNotEmpty && issue.labels.contains(GitHubSettings.thumbsUpLabel)) {
              labelsToRemove.add(GitHubSettings.thumbsUpLabel);
            }
            // STALE STALE ISSUE LABEL
            if (issue.labels.contains(GitHubSettings.staleIssueLabel) &&
                ((issue.lastContributorTouch != null && issue.lastContributorTouch!.isAfter(staleThreshold)) ||
                 (issue.assignedAt == null))) {
              labelsToRemove.add(GitHubSettings.staleIssueLabel);
            }
            // LOCKED STATUS
            final bool shouldUnlock = issue.openedAt != null && issue.lockedAt != null && issue.lockedAt!.isBefore(issue.openedAt!);
            // APPLY PENDING CHANGES
            if ((labelsToRemove.isNotEmpty || messages.isNotEmpty || shouldUnlock) && await isActuallyOpen(number)) {
              for (final String label in labelsToRemove) {
                log('Removing label "$label" on issue #$number');
                await _githubReady();
                await github.issues.removeLabelForIssue(GitHubSettings.primaryRepository, number, label);
                issue.labels.remove(label);
              }
              if (messages.isNotEmpty) {
                log('Posting message on issue #$number:\n  ${messages.join("\n  ")}');
                await _githubReady();
                await github.issues.createComment(GitHubSettings.primaryRepository, number, messages.join('\n'));
              }
              if (shouldUnlock) {
                log('Unlocking issue #$number (reopened after being locked)');
                await _githubReady();
                await github.issues.unlock(GitHubSettings.primaryRepository, number);
              }
            }
            _pendingCleanupIssues.remove(number);
          }
        } catch (e, s) {
          log('Failure in cleanup for #$number: $e (${e.runtimeType})\n$s');
        }
      }
    } finally {
      _cleaning = false;
      _lastCleanupEnd = DateTime.timestamp();
    }
  }

  bool _tidying = false;
  // This is called periodically to enforce long-term policies (things that
  // only apply after an issue has been in a particular state for weeks).
  Future<void> _performLongTermTidying([Timer? timer]) async {
    _tidyTimer?.cancel();
    final DateTime now = DateTime.timestamp();
    _nextTidy = now.add(Timings.longTermTidyingPeriod);
    _tidyTimer = Timer(Timings.longTermTidyingPeriod, _performLongTermTidying);
    if (_tidying) {
      return;
    }
    try {
      _tidying = true;
      _lastTidyStart = now;
      final DateTime staleThreshold = now.subtract(Timings.timeUntilStale);
      final DateTime reallyStaleThreshold = now.subtract(Timings.timeUntilReallyStale);
      final DateTime unlockThreshold = now.subtract(Timings.timeUntilUnlock);
      final DateTime refeedThreshold = now.subtract(Timings.refeedDelay);
      int number = 1;
      while (number < _highestKnownIssue) {
        try {
          if (_issues.containsKey(number) && !_pendingCleanupIssues.containsKey(number) && number != _selfTestIssue) {
            // Tidy the issue.
            final IssueStats issue = _issues[number]!;
            final Set<String> triagedTeams = getTeamsFor(GitHubSettings.triagedPrefix, issue.labels);
            final Set<String> assignedTeams = getTeamsFor(GitHubSettings.teamPrefix, issue.labels);
            // Check for assigned issues that aren't making progress.
            if (issue.assignedAt != null &&
                issue.lastContributorTouch != null &&
                issue.lastContributorTouch!.isBefore(staleThreshold) &&
                (!issue.assignedToTeamMemberReporter || issue.labels.contains(GitHubSettings.designDoc))) {
              await _githubReady();
              final Issue actualIssue = await github.issues.get(GitHubSettings.primaryRepository, number);
              if (actualIssue.assignees != null && actualIssue.assignees!.isNotEmpty && isActuallyOpenFromRawIssue(actualIssue)) {
                final String assignee = actualIssue.assignees!.map((User user) => '@${user.login}').join(' and ');
                if (!issue.labels.contains(GitHubSettings.staleIssueLabel)) {
                  log('Issue #$number is assigned to $assignee but not making progress; adding comment.');
                  await _githubReady();
                  await github.issues.addLabelsToIssue(GitHubSettings.primaryRepository, number, <String>[GitHubSettings.staleIssueLabel]);
                  issue.labels.add(GitHubSettings.staleIssueLabel);
                  await _githubReady();
                  await github.issues.createComment(GitHubSettings.primaryRepository, number,
                    'This issue is assigned to $assignee but has had no recent status updates. '
                    'Please consider unassigning this issue if it is not going to be addressed in the near future. '
                    'This allows people to have a clearer picture of what work is actually planned. Thanks!',
                  );
                } else if (issue.lastContributorTouch!.isBefore(reallyStaleThreshold)) {
                  bool skip = false;
                  String team = 'primary triage';
                  if (assignedTeams.length == 1) { // if it's more, then cleanup will take care of it
                    team = assignedTeams.single;
                    if (!_lastRefeedByTime.containsKey(team) || _lastRefeedByTime[team]!.isBefore(refeedThreshold)) {
                      _lastRefeedByTime[team] = now;
                    } else {
                      skip = true;
                    }
                  }
                  if (!skip) {
                    log('Issue #$number is assigned to $assignee but still not making progress (for ${now.difference(issue.lastContributorTouch!)}); sending back to triage (for $team team).');
                    for (final String triagedTeam in triagedTeams) {
                      await _githubReady();
                      await github.issues.removeLabelForIssue(GitHubSettings.primaryRepository, number, '${GitHubSettings.triagedPrefix}$triagedTeam');
                      issue.labels.remove('${GitHubSettings.triagedPrefix}$triagedTeam');
                    }
                    await _githubReady();
                    await github.issues.edit(GitHubSettings.primaryRepository, number, IssueRequest(assignees: const <String>[]));
                    await _githubReady();
                    await github.issues.createComment(GitHubSettings.primaryRepository, number,
                      'This issue was assigned to $assignee but has had no status updates in a long time. '
                      'To remove any ambiguity about whether the issue is being worked on, the assignee was removed.',
                    );
                    await _githubReady();
                    await github.issues.removeLabelForIssue(GitHubSettings.primaryRepository, number, GitHubSettings.staleIssueLabel);
                    issue.labels.remove(GitHubSettings.staleIssueLabel);
                  }
                }
              }
            }
            // Check for P1 issues that aren't making progress.
            // We currently rate-limit this to only a few per week so that teams don't get overwhelmed.
            if (issue.assignedAt == null &&
                issue.labels.contains('P1') &&
                issue.lastContributorTouch != null &&
                issue.lastContributorTouch!.isBefore(staleThreshold) &&
                triagedTeams.length == 1) {
              final String team = triagedTeams.single;
              if ((!_lastRefeedByTime.containsKey(team) || _lastRefeedByTime[team]!.isBefore(refeedThreshold)) && await isActuallyOpen(number)) {
                log('Issue #$number is P1 but not assigned and not making progress; removing triage label and adding comment.');
                await _githubReady();
                await github.issues.removeLabelForIssue(GitHubSettings.primaryRepository, number, '${GitHubSettings.triagedPrefix}${triagedTeams.single}');
                issue.labels.remove('${GitHubSettings.triagedPrefix}${triagedTeams.single}');
                await _githubReady();
                await github.issues.createComment(GitHubSettings.primaryRepository, number, GitHubSettings.staleP1Message);
                _lastRefeedByTime[team] = now;
              }
            }
            // Unlock issues after a timeout.
            if (issue.lockedAt != null && issue.lockedAt!.isBefore(unlockThreshold) &&
                !issue.labels.contains(GitHubSettings.permanentlyLocked) &&
                await isActuallyOpen(number)) {
              log('Issue #$number has been locked for too long, unlocking.');
              await _githubReady();
              await github.issues.unlock(GitHubSettings.primaryRepository, number);
            }
            // Flag issues that have gained a lot of thumbs-up.
            // We don't consider refeedThreshold for this because it should be relatively rare and
            // is always noteworthy when it happens.
            if (issue.thumbsAtTriageTime != null && triagedTeams.length == 1 &&
                issue.thumbs >= issue.thumbsAtTriageTime! * GitHubSettings.thumbsThreshold &&
                issue.thumbs >= GitHubSettings.thumbsMinimum &&
                await isActuallyOpen(number)) {
              log('Issue #$number has gained a lot of thumbs-up, flagging for retriage.');
              await _githubReady();
              await github.issues.removeLabelForIssue(GitHubSettings.primaryRepository, number, '${GitHubSettings.triagedPrefix}${triagedTeams.single}');
              issue.labels.remove('${GitHubSettings.triagedPrefix}${triagedTeams.single}');
              await _githubReady();
              await github.issues.addLabelsToIssue(GitHubSettings.primaryRepository, number, <String>[GitHubSettings.thumbsUpLabel]);
              issue.labels.add(GitHubSettings.thumbsUpLabel);
            }
          }
        } catch (e, s) {
          log('Failure in tidying for #$number: $e (${e.runtimeType})\n$s');
        }
        number += 1;
      }
      try {
        if (_selfTestIssue == null) {
          if (_selfTestClosedDate == null || _selfTestClosedDate!.isBefore(now.subtract(Timings.selfTestPeriod))) {
            await _githubReady();
            final Issue issue = await github.issues.create(GitHubSettings.primaryRepository, IssueRequest(
              title: 'Triage process self-test',
              body: 'This is a test of our triage processes.\n'
                '\n'
                'Please handle this issue the same way you would a normal valid but low-priority issue.\n'
                '\n'
                'For more details see https://github.com/flutter/flutter/blob/master/docs/triage/README.md',
              labels: <String>[
                ...GitHubSettings.teams.map((String team) => '${GitHubSettings.teamPrefix}$team'),
                'P2',
              ],
            ));
            _selfTestIssue = issue.number;
            _selfTestClosedDate = null;
            log('Filed self-test issue #$_selfTestIssue.');
          }
        } else if (_issues.containsKey(_selfTestIssue)) {
          final IssueStats issue = _issues[_selfTestIssue]!;
          if (!issue.labels.contains(GitHubSettings.willNeedAdditionalTriage) &&
              issue.lastContributorTouch!.isBefore(now.subtract(Timings.selfTestWindow)) &&
              await isActuallyOpen(_selfTestIssue!)) {
            log('Flagging self-test issue #$_selfTestIssue for critical triage.');
            for (final String team in getTeamsFor(GitHubSettings.triagedPrefix, issue.labels)) {
              await _githubReady();
              await github.issues.removeLabelForIssue(GitHubSettings.primaryRepository, _selfTestIssue!, '${GitHubSettings.teamPrefix}$team');
              issue.labels.remove('${GitHubSettings.teamPrefix}$team');
              await _githubReady();
              await github.issues.removeLabelForIssue(GitHubSettings.primaryRepository, _selfTestIssue!, '${GitHubSettings.triagedPrefix}$team');
              issue.labels.remove('${GitHubSettings.triagedPrefix}$team');
            }
            await _githubReady();
            await github.issues.addLabelsToIssue(GitHubSettings.primaryRepository, _selfTestIssue!, <String>[GitHubSettings.willNeedAdditionalTriage]);
            issue.labels.add(GitHubSettings.willNeedAdditionalTriage);
          }
        }
      } catch (e, s) {
        log('Failure in self-test logic: $e (${e.runtimeType})\n$s');
      }
    } finally {
      _tidying = false;
      _lastTidyEnd = DateTime.timestamp();
    }
  }

  Future<bool> isActuallyOpen(int number) async {
    if (!_issues.containsKey(number)) {
      return false;
    }
    await _githubReady();
    final Issue rawIssue = await github.issues.get(GitHubSettings.primaryRepository, number);
    return isActuallyOpenFromRawIssue(rawIssue);
  }

  bool isActuallyOpenFromRawIssue(Issue rawIssue) {
    if (rawIssue.isClosed) {
      log('Issue #${rawIssue.number} was unexpectedly found to be closed when doing cleanup.');
      _issues.remove(rawIssue.number);
      _pendingCleanupIssues.remove(rawIssue.number);
      if (rawIssue.number == _selfTestIssue) {
        _selfTestIssue = null;
      }
      return false;
    }
    return true;
  }

  static String? getTeamFor(String prefix, String label) {
    if (label.startsWith(prefix)) {
      return label.substring(prefix.length);
    }
    return null;
  }

  static Set<String> getTeamsFor(String prefix, Set<String> labels) {
    if (labels.isEmpty) {
      return const <String>{};
    }
    Set<String>? result;
    for (final String label in labels) {
      final String? team = getTeamFor(prefix, label);
      if (team != null) {
        result ??= <String>{};
        result.add(team);
      }
    }
    return result ?? const <String>{};
  }
}

int secondsSinceEpoch(DateTime time) => time.millisecondsSinceEpoch ~/ 1000;

Future<String> obtainGitHubCredentials(Secrets secrets, http.Client client) async {
  // https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-json-web-token-jwt-for-a-github-app
  final DateTime now = DateTime.timestamp();
  final String jwt = JWT(<String, dynamic>{
    'iat': secondsSinceEpoch(now.subtract(const Duration(seconds: 60))),
    'exp': secondsSinceEpoch(now.add(const Duration(minutes: 10))),
    'iss': await secrets.githubAppId,
  }).sign(
    RSAPrivateKey(await secrets.githubAppKey),
    algorithm: JWTAlgorithm.RS256,
    noIssueAt: true,
  );
  final String installation = await secrets.githubInstallationId;
  final dynamic response = Json.parse((await client.post(
    Uri.parse('https://api.github.com/app/installations/$installation/access_tokens'),
    body: '{}',
    headers: <String, String>{
      'Accept': 'application/vnd.github+json',
      'Authorization': 'Bearer $jwt', // should not need escaping, base64 is safe in a header value
      'X-GitHub-Api-Version': '2022-11-28',
    },
  )).body);
  return response.token.toString();
}

Future<void> maintainGitHubCredentials(GitHub github, Secrets secrets, Engine engine, http.Client client) async {
  try {
    await Future<void>.delayed(Timings.credentialsUpdatePeriod);
    github.auth = Authentication.withToken(await obtainGitHubCredentials(secrets, client));
  } catch (e, s) {
    engine.log('Failed to maintain GitHub credentials: $e (${e.runtimeType})\n$s');
  }
}

DateTime _laterOf(DateTime a, DateTime b) {
  if (a.isAfter(b)) {
    return a;
  }
  return b;
}

Future<DateTime> getCertificateTimestamp(Secrets secrets) async {
  return _laterOf(
    _laterOf(
      await secrets.serverCertificateModificationDate,
      await secrets.serverIntermediateCertificatesModificationDate,
    ),
    await secrets.serverKeyModificationDate,
  );
}

Future<SecurityContext> loadCertificates(Secrets secrets) async {
  return SecurityContext()
    ..useCertificateChainBytes(
      await secrets.serverCertificate +
      await secrets.serverIntermediateCertificates,
    )
    ..usePrivateKeyBytes(await secrets.serverKey);
}

final bool usingAppEngine = Platform.environment.containsKey('APPENGINE_RUNTIME');

Future<Engine> startEngine(void Function()? onChange) async {
  final Secrets secrets = Secrets();

  final INyxx discord = NyxxFactory.createNyxxRest(
    await secrets.discordToken,
    GatewayIntents.none,
    Snowflake.value(await secrets.discordAppId),
  );
  await discord.connect();

  final http.Client httpClient = http.Client();

  final GitHub github = GitHub(
    client: httpClient,
    auth: Authentication.withToken(await obtainGitHubCredentials(secrets, httpClient)),
  );

  final Engine engine = await Engine.initialize(
    webhookSecret: await secrets.githubWebhookSecret,
    discord: discord,
    github: github,
    onChange: onChange,
    secrets: secrets,
  );

  if (usingAppEngine) {
    await withAppEngineServices(() async {
      runAppEngine(engine.handleRequest); // ignore: unawaited_futures
      while (true) {
        await maintainGitHubCredentials(github, secrets, engine, httpClient);
      }
    });
  } else {
    scheduleMicrotask(() async {
      DateTime activeCertificateTimestamp = await getCertificateTimestamp(secrets);
      SecurityContext securityContext = await loadCertificates(secrets);
      while (true) {
        final HttpServer server = await HttpServer.bindSecure(InternetAddress.anyIPv4, port, securityContext);
        server.listen(engine.handleRequest);
        DateTime pendingCertificateTimestamp = activeCertificateTimestamp;
        do {
          await maintainGitHubCredentials(github, secrets, engine, httpClient);
          pendingCertificateTimestamp = await getCertificateTimestamp(secrets);
        } while (pendingCertificateTimestamp == activeCertificateTimestamp);
        activeCertificateTimestamp = pendingCertificateTimestamp;
        engine.log('Updating TLS credentials...');
        securityContext = await loadCertificates(secrets);
        await engine.shutdown(server.close);
        // There's a race condition here where we might miss messages because the server is down.
      }
    });
  }

  return engine;
}
