// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:github/github.dart';

import 'cache.dart';
import 'utils.dart';

class TeamRoster {
  TeamRoster(this.teams);

  static Future<TeamRoster> load({
    required final Directory cache,
    required final GitHub github,
    required final String orgName,
    required final DateTime cacheEpoch,
  }) async {
    final Map<String?, Map<String, User>> roster = <String?, Map<String, User>>{};
    final String teamsData =
        await loadFromCache(cache, github, <String>['org', orgName, 'teams'], cacheEpoch, () async {
      final StringBuffer cacheData = StringBuffer();
      await for (final Team team in github.organizations.listTeams(orgName)) {
        verifyStringSanity(team.name!, const <String>{'\n', ' '});
        cacheData.writeln('${team.name} ${team.id!}');
      }
      return cacheData.toString().trimRight();
    });
    Map<String, User> parseTeamData(final String teamData) {
      final Map<String, User> users = <String, User>{};
      for (final String line in teamData.split('\n')) {
        final List<String> components = line.split(' ');
        final User member = User(
          login: components[0],
          id: int.parse(components[1]),
          siteAdmin: components[2] == 'true',
          htmlUrl: components[3],
          avatarUrl: components[4],
        );
        users[member.login!] = member;
      }
      return users;
    }

    for (final String teamLine in teamsData.split('\n')) {
      final List<String> components = teamLine.split(' ');
      final String teamName = components[0];
      final int teamId = int.parse(components[1]);
      final String teamData =
          await loadFromCache(cache, github, <String>['team', orgName, '$teamId'], cacheEpoch, () async {
        final StringBuffer cacheData = StringBuffer();
        await for (final TeamMember member in github.organizations.listTeamMembers(teamId)) {
          verifyStringSanity(member.login!, const <String>{'\n', ' '});
          verifyStringSanity(member.htmlUrl!, const <String>{'\n', ' '});
          verifyStringSanity(member.avatarUrl!, const <String>{'\n', ' '});
          cacheData.writeln('${member.login} ${member.id!} ${member.siteAdmin} ${member.htmlUrl} ${member.avatarUrl}');
        }
        return cacheData.toString().trimRight();
      });
      roster[teamName] = parseTeamData(teamData);
    }
    final String teamData = await loadFromCache(cache, github, <String>['org', orgName, 'users'], cacheEpoch, () async {
      final StringBuffer cacheData = StringBuffer();
      await for (final User member in github.organizations.listUsers(orgName)) {
        verifyStringSanity(member.login!, const <String>{'\n', ' '});
        verifyStringSanity(member.htmlUrl!, const <String>{'\n', ' '});
        verifyStringSanity(member.avatarUrl!, const <String>{'\n', ' '});
        cacheData.writeln('${member.login} ${member.id!} ${member.siteAdmin} ${member.htmlUrl} ${member.avatarUrl}');
      }
      return cacheData.toString().trimRight();
    });
    roster[null] = parseTeamData(teamData);
    return TeamRoster(roster);
  }

  final Map<String?, Map<String, User>> teams;
}
