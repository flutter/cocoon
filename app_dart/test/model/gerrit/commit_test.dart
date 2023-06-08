import 'dart:convert';

import 'package:cocoon_service/src/model/gerrit/commit.dart';
import 'package:test/test.dart';

void main() {
  group(GerritCommit, () {
    test('fromJson', () {
      const String json = '''{
      "commit": "c80a772eebe7f47d12ad1b21bc48fbd9521519aa",
      "tree": "ee444f607795706641aedbc7c43a578b001aec5e",
      "parents": [
        "3770382108d17154bbacce45dd18e475718cd904"
      ],
      "author": {
        "name": "recipe-roller",
        "email": "flutter-prod-builder@chops-service-accounts.iam.gserviceaccount.com",
        "time": "Wed Jun 07 22:54:06 2023 +0000"
      },
      "committer": {
        "name": "CQ Bot Account",
        "email": "flutter-scoped@luci-project-accounts.iam.gserviceaccount.com",
        "time": "Wed Jun 07 22:54:06 2023 +0000"
      },
      "message": "Roll recipe dependencies (trivial)\\n\\nThis is an automated CL created by the recipe roller."
    }''';
      final GerritCommit commit = GerritCommit.fromJson(jsonDecode(json));
      expect(commit.author, isNotNull);
      expect(commit.author!.name, 'recipe-roller');
      expect(commit.author!.time, DateTime(2023, 06, 07, 22, 54));
    });
  });
}
