// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';

import '../../cocoon_service.dart';

/// Return a list of commit shas of the latest 5 branches for google3 roll, beta, and stable.
///
/// Branches are sorted based on the version number.
///
/// GET: /api/public/get-release-branches
///
/// Response: Status 200 OK
/// {
///     "Beta":[
///         "7ac27ac8e6a42750c475ba8a2a3c7047b93fd949",
///         "d952ca86d64772b1b9b0df27cf9ea145e80c38e5",
///         "f90da9b1672f7d006ba760fbb8fd1aa17af1a82a",
///         "bcea432bce54a83306b3c00a7ad0ed98f777348d",
///         "f28e570c8cb12a004fae2d796d0d9cd46603bde9"
///     ],
///     "Stable":[
///         "f1875d570e39de09040c8f79aa13cc56baab8db1",
///         "85684f9300908116a78138ea4c6036c35c9a1236",
///         "676cefaaff197f27424942307668886253e1ec35",
///         "cd41fdd495f6944ecd3506c21e94c6567b073278",
///         "fb57da5f945d02ef4f98dfd9409a72b7cce74268"
///     ],
///     "googleBraches":[
///         "647cb29a1373852c26ac426c2c584850aeb7613c",
///         "64c35607041b77ed326f4dfec7274325001d4a61",
///         "a8580fbfb2e2089314541dd8030418678e863f6f",
///         "18575321bb0d134fe3145095362479708855bc1d",
///         "c8578570cdcd2f0b75acfc091450eabeb0fd3831"
///     ]
/// }

class GetReleaseBranches extends RequestHandler<Body> {
  GetReleaseBranches(
    Config config,
  ) : super(config: config);

  @override
  Future<Body> get() async {
    final GitHub github = await config.createGitHubClient(slug: Config.flutterSlug);
    List<List<String>> betaAndStableBranches =
        await _getBetaAndStableBranches(github: github, slug: Config.flutterSlug);
    List<String> betaBranches = betaAndStableBranches[0];
    List<String> stableBranches = betaAndStableBranches[1];
    List<String> googleThreeBranches = await _getGoogleThreeBranches(github: github, slug: Config.flutterSlug);
    //some JSONNNN
    return Body.forJson(<String, List<String>>{
      'Beta': betaBranches,
      'Stable': stableBranches,
      'googleBraches': googleThreeBranches,
    });
  }

  int _versionSum(String tagOrBranchName) {
    List<String> digits = tagOrBranchName.replaceAll(r'flutter|candidate', '0').split(RegExp(r'\.|\-'));
    int versionSum = 0;
    for (String digit in digits) {
      int? d = int.tryParse(digit);
      if (d == null) {
        continue;
      }
      versionSum = versionSum * 10 + d;
    }
    return versionSum;
  }

  Future<List<String>> _getGoogleThreeBranches({required GitHub github, required RepositorySlug slug}) async {
    final RegExp candidateBranchName = RegExp(r'flutter-\d+\.\d+-candidate\.\d+');
    List<Branch> branches = await github.repositories.listBranches(slug).toList();
    List<Branch> googleThreeBranches = branches.where((Branch b) => candidateBranchName.hasMatch(b.name!)).toList();
    googleThreeBranches.sort((b, a) => (_versionSum(b.name!)).compareTo(_versionSum(a.name!)));
    List<String> googleThreeShas = googleThreeBranches.take(5).map((Branch b) => b.commit!.sha!).toList();
    return googleThreeShas;
  }

  Future<List<List<String>>> _getBetaAndStableBranches({required GitHub github, required RepositorySlug slug}) async {
    List<String> betaShaList = <String>[];
    List<String> stableShaList = <String>[];

    List<Tag> betaTagList = <Tag>[];
    List<Tag> stableTagList = <Tag>[];
    // current page count is 17
    for (int pageNum = 1; pageNum < 100; ++pageNum) {
      List<Tag> tags = await github.repositories.listTags(slug, page: pageNum).toList();
      if (tags.isEmpty) {
        break;
      }

      List<Tag> betaTags = tags.where((Tag t) => t.name.endsWith("pre")).toList();
      betaTagList.addAll(betaTags);

      List<Tag> stableTags =
          tags.where((Tag t) => !(t.name.startsWith("v"))).where((Tag t) => !(t.name.endsWith("pre"))).toList();
      stableTagList.addAll(stableTags);
    }

    betaTagList.sort((b, a) => (_versionSum(a.name)).compareTo(_versionSum(b.name)));
    List<String> betaShas = betaTagList.take(5).map((Tag t) => t.commit.sha!).toList();
    betaShaList.addAll(betaShas);

    stableTagList.sort((b, a) => (_versionSum(a.name)).compareTo(_versionSum(b.name)));
    List<String> stableShas = stableTagList.take(5).map((Tag t) => t.commit.sha!).toList();
    stableShaList.addAll(stableShas);

    return [betaShaList, stableShaList];
  }
}
