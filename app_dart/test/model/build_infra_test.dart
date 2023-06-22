import 'dart:convert';

import 'package:cocoon_service/src/model/luci/build_infra.dart';
import 'package:test/test.dart';


void main() {
  const String agentJson = '''
{
  "input": {
          "data": {
                  "bbagent_utility_packages": {
                          "cipd": {
                                  "server": "chrome-infra-packages.appspot.com",
                                  "specs": [
                                          {
                                                  "package": "infra/tools/luci/cas/platform",
                                                  "version": "git_revision:fe9985447e6b95f4907774f05e9774f031700775"
                                          }
                                  ]
                          },
                          "onPath": [
                                  "bbagent_utility_packages",
                                  "bbagent_utility_packages/bin"
                          ]
                  },
                  "cipd_bin_packages": {
                          "cipd": {
                                  "server": "chrome-infra-packages.appspot.com",
                                  "specs": [
                                          {
                                                  "package": "infra/3pp/tools/git/platform",
                                                  "version": "latest"
                                          },
                                          {
                                                  "package": "infra/tools/git/platform",
                                                  "version": "latest"
                                          },
                                          {
                                                  "package": "infra/tools/luci/git-credential-luci/platform",
                                                  "version": "latest"
                                          },
                                          {
                                                  "package": "infra/tools/luci/docker-credential-luci/platform",
                                                  "version": "latest"
                                          },
                                          {
                                                  "package": "infra/tools/luci/vpython3/platform",
                                                  "version": "latest"
                                          },
                                          {
                                                  "package": "infra/tools/luci/lucicfg/platform",
                                                  "version": "latest"
                                          },
                                          {
                                                  "package": "infra/tools/luci-auth/platform",
                                                  "version": "latest"
                                          },
                                          {
                                                  "package": "infra/tools/bb/platform",
                                                  "version": "latest"
                                          },
                                          {
                                                  "package": "infra/tools/cloudtail/platform",
                                                  "version": "latest"
                                          },
                                          {
                                                  "package": "infra/tools/prpc/platform",
                                                  "version": "latest"
                                          },
                                          {
                                                  "package": "infra/tools/rdb/platform",
                                                  "version": "latest"
                                          },
                                          {
                                                  "package": "infra/tools/luci/led/platform",
                                                  "version": "latest"
                                          }
                                  ]
                          },
                          "onPath": [
                                  "cipd_bin_packages",
                                  "cipd_bin_packages/bin"
                          ]
                  },
                  "cipd_bin_packages/cpython3": {
                          "cipd": {
                                  "server": "chrome-infra-packages.appspot.com",
                                  "specs": [
                                          {
                                                  "package": "infra/3pp/tools/cpython3/platform",
                                                  "version": "version:2@3.8.10.chromium.26"
                                          }
                                  ]
                          },
                          "onPath": [
                                  "cipd_bin_packages/cpython3",
                                  "cipd_bin_packages/cpython3/bin"
                          ]
                  },
                  "kitchen-checkout": {
                          "cipd": {
                                  "server": "chrome-infra-packages.appspot.com",
                                  "specs": [
                                          {
                                                  "package": "infra/recipe_bundles/chromium.googlesource.com/chromium/tools/build",
                                                  "version": "refs/heads/main"
                                          }
                                  ]
                          }
                  }
          }
  },
  "source": {
          "cipd": {
                  "package": "infra/tools/luci/bbagent/platform",
                  "version": "latest",
                  "server": "chrome-infra-packages.appspot.com"
          }
  },
  "purposes": {
          "bbagent_utility_packages": "PURPOSE_BBAGENT_UTILITY",
          "kitchen-checkout": "PURPOSE_EXE_PAYLOAD"
  }
}
''';

  // test('Agent', () {
  //   final Agent agent = Agent.fromJson(jsonDecode(agentJson));
  //   expect(agent, isNotNull);
  //   expect(agent.input, isNotNull);
  //   print(agent.source!.cipd!.package);
  // });

  test('InputDataRefCipd', () {
    const String inputDataRefCipdJson = '''
{
  "server": "chrome-infra-packages.appspot.com",
  "specs": [
    {
            "package": "infra/tools/luci/cas/platform",
            "version": "git_revision:fe9985447e6b95f4907774f05e9774f031700775"
    }
  ]
}
''';

    final InputDataRefCipd inputDataRefCipd = InputDataRefCipd.fromJson(jsonDecode(inputDataRefCipdJson));
    expect(inputDataRefCipd.server, 'chrome-infra-packages.appspot.com');
  });
}