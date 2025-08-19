// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/model/github/checks.dart' as cocoon_checks;
import 'package:github/github.dart';

CheckRun createGithubCheckRun({
  int id = 1,
  String sha = '1234',
  String? name = 'Linux unit_test',
  String conclusion = 'success',
  String owner = 'flutter',
  String repo = 'flutter',
  String headBranch = 'master',
  CheckRunStatus status = CheckRunStatus.completed,
  int checkSuiteId = 668083231,
}) {
  final checkRunJson = checkRunFor(
    id: id,
    sha: sha,
    name: name,
    conclusion: conclusion,
    owner: owner,
    repo: repo,
    headBranch: headBranch,
    status: status,
    checkSuiteId: checkSuiteId,
  );
  return CheckRun.fromJson(jsonDecode(checkRunJson) as Map<String, dynamic>);
}

cocoon_checks.CheckRun createCocoonCheckRun({
  int id = 1,
  String sha = '1234',
  String? name = 'Linux unit_test',
  String conclusion = 'success',
  String owner = 'flutter',
  String repo = 'flutter',
  String headBranch = 'master',
  CheckRunStatus status = CheckRunStatus.completed,
  int checkSuiteId = 668083231,
}) {
  final checkRunJson = checkRunFor(
    id: id,
    sha: sha,
    name: name,
    conclusion: conclusion,
    owner: owner,
    repo: repo,
    headBranch: headBranch,
    status: status,
    checkSuiteId: checkSuiteId,
  );
  return cocoon_checks.CheckRun.fromJson(
    jsonDecode(checkRunJson) as Map<String, dynamic>,
  );
}

String checkRunFor({
  int id = 1,
  String sha = '1234',
  String? name = 'Linux unit_test',
  String conclusion = 'success',
  String owner = 'flutter',
  String repo = 'flutter',
  String headBranch = 'master',
  CheckRunStatus status = CheckRunStatus.completed,
  int checkSuiteId = 668083231,
}) {
  final externalId = id * 2;
  return '''{
  "id": $id,
  "external_id": "{$externalId}",
  "head_sha": "$sha",
  "name": "$name",
  "conclusion": "$conclusion",
  "started_at": "2020-05-10T02:49:31Z",
  "completed_at": "2020-05-10T03:11:08Z",
  "status": "$status",
  "check_suite": {
    "id": $checkSuiteId,
    "pull_requests": [],
    "conclusion": "$conclusion",
    "head_branch": "$headBranch"
  }
}''';
}

String checkRunEventFor({
  String action = 'completed',
  String sha = '1234',
  String test = 'Linux unit_test',
  String conclusion = 'success',
  String owner = 'flutter',
  String repo = 'flutter',
  String headBranch = 'master',
}) =>
    '''{
  "action": "$action",
  "check_run": ${checkRunFor(name: test, sha: sha, conclusion: conclusion, owner: owner, repo: repo, headBranch: headBranch)},
  "repository": ${repositoryFor(owner: owner, repo: repo)}
}''';

String repositoryFor({String owner = 'flutter', String repo = 'flutter'}) =>
    '''{
  "name": "$repo",
  "full_name": "$owner/$repo",
  "owner": {
    "avatar_url": "",
    "html_url": "",
    "login": "$owner",
    "id": 54371434
  }
}''';

Repository createGithubRepository({
  String owner = 'flutter',
  String repo = 'flutter',
}) {
  final repositoryJson = repositoryFor(owner: owner, repo: repo);
  return Repository.fromJson(
    jsonDecode(repositoryJson) as Map<String, dynamic>,
  );
}
