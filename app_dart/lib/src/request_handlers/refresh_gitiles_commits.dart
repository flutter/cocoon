// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:googleapis/bigquery/v2.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';

/// Queries `gitiles` for the list of recent commits of different repos,
/// and creates corresponding rows in the `BigQuery` for any new commits.
/// For parent repo roll commits, obtains its sub-repo commits and inserts
/// them to `BigQuery`.
@immutable
class RefreshGitilesCommits extends ApiRequestHandler<Body> {
  const RefreshGitilesCommits(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting this.httpClientProvider = Providers.freshHttpClient,
    @visibleForTesting this.rollHttpClientProvider = Providers.freshHttpClient,
  })  : assert(httpClientProvider != null),
        super(config: config, authenticationProvider: authenticationProvider);

  final HttpClientProvider httpClientProvider;
  final HttpClientProvider rollHttpClientProvider;

  static const String projectId = 'flutter-dashboard';
  static const String dataset = 'roller';

  static const Map<String, String> monthMap = <String, String>{
    'Jan': '01',
    'Feb': '02',
    'Mar': '03',
    'Apr': '04',
    'May': '05',
    'Jun': '06',
    'Jul': '07',
    'Aug': '08',
    'Sep': '09',
    'Oct': '10',
    'Nov': '11',
    'Dec': '12'
  };
  static const Map<String, RepoUrl> repoMap = <String, RepoUrl>{
    'skia': RepoUrl('skia.googlesource.com', '/skia.git/+log/'),
    'dart': RepoUrl('dart.googlesource.com', '/sdk.git/+log/'),
    'engine': RepoUrl('chromium.googlesource.com',
        '/external/github.com/flutter/engine/+log/'),
    'flutter': RepoUrl('chromium.googlesource.com',
        '/external/github.com/flutter/flutter/+log/'),
  };
  static const String refs = 'refs/heads/master';

  @override
  Future<Body> get() async {
    final HttpClient httpClient = httpClientProvider();
    for (String repo in repoMap.keys) {
      final List<Map<String, dynamic>> list = await _getCommitList(
          httpClient, repoMap[repo].address, '${repoMap[repo].path}$refs');
      await _insertBigquery(list, repo);
    }

    return Body.empty;
  }

  int _getMilliseconds(String time) {
    /// [time] is with format `Fri Apr 17 11:58:29 2020 -0500`.
    final List<String> timeParts = time.split(' ');
    final String newCommitTime =
        '${timeParts[4]}-${monthMap[timeParts[1]]}-${timeParts[2]} ${timeParts[3]}';
    return DateTime.parse(newCommitTime).millisecondsSinceEpoch;
  }

  Future<List<Map<String, dynamic>>> _getCommitList(
      final HttpClient client, String address, String path) async {
    final Uri url =
        Uri.https(address, path, <String, String>{'format': 'JSON'});
    //final HttpClient client = httpClientProvider();
    final HttpClientRequest clientRequest = await client.getUrl(url);
    final HttpClientResponse clientResponse = await clientRequest.close();
    final int status = clientResponse.statusCode;

    String content;

    if (status == HttpStatus.ok) {
      content = await utf8.decoder.bind(clientResponse).join();
    } else {
      log.warning(
          'Attempt to retrieve $address commit list failed (HTTP $status)');
      return const <Map<String, dynamic>>[];
    }
    final Map<String, dynamic> map =
        json.decode(content.substring(content.indexOf('{')))
            as Map<String, dynamic>;
    return (map['log'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> _insertBigquery(
      List<Map<String, dynamic>> list, String repo) async {
    final String table = '${repo}Commit';
    final TabledataResourceApi tabledataResourceApi =
        await config.createTabledataResourceApi();
    final List<Map<String, Object>> commitRequestRows = <Map<String, Object>>[];
    final List<Map<String, Object>> skiaRollCommitRequestRows =
        <Map<String, Object>>[];
    final List<Map<String, Object>> dartRollCommitRequestRows =
        <Map<String, Object>>[];
    final List<Map<String, Object>> engineRollCommitRequestRows =
        <Map<String, Object>>[];
    final int lastCommitedTime =
        await _getLastCommitedTime(tabledataResourceApi, table, 'CommitTime');

    //log.debug('lastCommitedTime: $lastCommitedTime');
    for (Map<String, dynamic> commit in list) {
      final String message = commit['message'] as String;
      final String subject = message.split('\n')[0];
      final bool newCommitflag = await _appendNewCommit(
          commit, commitRequestRows, lastCommitedTime, subject, repo);
      if (!newCommitflag) {
        break;
      }

      /// Insert roll commits if any.
      final String priorRepo = _getPriorRepo(subject);
      if (priorRepo.isNotEmpty) {
        await _appendRollCommit(
            skiaRollCommitRequestRows,
            dartRollCommitRequestRows,
            engineRollCommitRequestRows,
            subject,
            priorRepo,
            commit);
      }
    }

    if (commitRequestRows.isEmpty) {
      log.debug('no new commits found for repo $repo');
      return;
    }

    await _insertCommit(commitRequestRows, tabledataResourceApi, table);
    if (skiaRollCommitRequestRows.isNotEmpty) {
      await _insertCommit(
          skiaRollCommitRequestRows, tabledataResourceApi, 'skiaRoller');
    }
    if (dartRollCommitRequestRows.isNotEmpty) {
      await _insertCommit(
          dartRollCommitRequestRows, tabledataResourceApi, 'dartRoller');
    }
    if (engineRollCommitRequestRows.isNotEmpty) {
      await _insertCommit(
          engineRollCommitRequestRows, tabledataResourceApi, 'engineRoller');
    }
  }

  Future<int> _getLastCommitedTime(TabledataResourceApi tabledataResourceApi,
      String table, String selectedFields) async {
    final TableDataList tableDataList = await tabledataResourceApi
        .list(projectId, dataset, table, selectedFields: selectedFields);
    int lastCommitedTime = 0;
    if (tableDataList.rows != null) {
      final List<int> commitTimeList =
          (tableDataList.rows.map((TableRow e) => e.f).toList())
              .map((List<TableCell> e) => int.parse(e[0].v as String))
              .toList();
      lastCommitedTime = commitTimeList.reduce(math.max);
    }
    return lastCommitedTime;
  }

  Future<void> _insertCommit(List<Map<String, Object>> requestRows,
      TabledataResourceApi tabledataResourceApi, String table) async {
    /// [rows] to be inserted to [BigQuery]
    final TableDataInsertAllRequest request =
        TableDataInsertAllRequest.fromJson(
            <String, Object>{'rows': requestRows});

    try {
      await tabledataResourceApi.insertAll(request, projectId, dataset, table);
      log.debug(
          'successfully inserted ${requestRows.length} new commits to table $table');
    } catch (ApiRequestError) {
      log.warning('Failed to add data to $table in BigQuery: $ApiRequestError');
    }
  }

  Future<bool> _appendNewCommit(
    Map<String, dynamic> commit,
    List<Map<String, Object>> requestRows,
    int lastCommitedTime,
    String subject,
    String repo,
  ) async {
    final Map<String, dynamic> author =
        commit['author'] as Map<String, dynamic>;
    final Map<String, dynamic> committer =
        commit['committer'] as Map<String, dynamic>;
    final int commitTime = _getMilliseconds(committer['time'] as String);
    //log.debug('Time for commit: ${commit['commit'] as String} is $commitTime (${committer['time'] as String})');
    if (commitTime <= lastCommitedTime) {
      log.debug('found ${requestRows.length} new commits for repo $repo');
      return false;
    }
    requestRows.add(<String, Object>{
      'json': <String, Object>{
        'Sha': commit['commit'] as String,
        'CommitTime': commitTime,
        'Subject': subject,
        'Author': author['name'] as String,
      },
    });
    return true;
  }

  String _getPriorRepo(String subject) {
    String priorRepo = '';
    if (subject.startsWith('Roll src\/third_party\/dart')) {
      priorRepo = 'dart';
    } else if (subject.startsWith('Roll src\/third_party\/skia')) {
      priorRepo = 'skia';
    } else if (subject.startsWith('Roll engine')) {
      priorRepo = 'engine';
    }
    return priorRepo;
  }

  Future<void> _appendRollCommit(
      List<Map<String, Object>> skiaRollCommitRequestRows,
      List<Map<String, Object>> dartRollCommitRequestRows,
      List<Map<String, Object>> engineRollCommitRequestRows,
      String subject,
      String priorRepo,
      Map<String, dynamic> rollCommit) async {
    final Map<String, dynamic> committer =
        rollCommit['committer'] as Map<String, dynamic>;
    final int commitTime = _getMilliseconds(committer['time'] as String);

    List<Map<String, Object>> rollCommitRequestRows;
    if (priorRepo == 'skia') {
      rollCommitRequestRows = skiaRollCommitRequestRows;
    } else if (priorRepo == 'dart') {
      rollCommitRequestRows = dartRollCommitRequestRows;
    } else {
      rollCommitRequestRows = engineRollCommitRequestRows;
    }

    final List<String> subjectSplit = subject.split(' ');
    final HttpClient rollHttpClient = rollHttpClientProvider();
    final List<Map<String, dynamic>> rollCommitList = await _getCommitList(
        rollHttpClient,
        repoMap[priorRepo].address,
        '${repoMap[priorRepo].path}${subjectSplit[2]}');
    log.debug('$subject, ${rollCommitList.length}');

    for (Map<String, dynamic> commit in rollCommitList) {
      rollCommitRequestRows.add(<String, Object>{
        'json': <String, Object>{
          'RollFromSha': commit['commit'] as String,
          'RollToSha': rollCommit['commit'] as String,
          'RollTime': commitTime,
        },
      });
    }
  }
}

class RepoUrl {
  const RepoUrl(this.address, this.path)
      : assert(address != null),
        assert(path != null);

  final String address;
  final String path;
}
