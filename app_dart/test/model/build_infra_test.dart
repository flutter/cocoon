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

  test('Agent', () {
    final Agent agent = Agent.fromJson(jsonDecode(agentJson));
    expect(agent, isNotNull);
    expect(agent.input, isNotNull);
    expect(agent.source, isNotNull);
    expect(agent.purposes, isNotNull);
  });

const String buildBucketV2Json = '''
{
  "requestedProperties": {},
  "hostname": "cr-buildbucket-dev.appspot.com",
  "experimentReasons": {
    "luci.buildbucket.agent.cipd_installation": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
    "luci.buildbucket.agent.start_build": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
    "luci.buildbucket.backend_alt": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
    "luci.buildbucket.backend_go": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
    "luci.buildbucket.bbagent_getbuild": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
    "luci.buildbucket.bq_exporter_go": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
    "luci.buildbucket.canary_software": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
    "luci.buildbucket.omit_default_packages": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
    "luci.buildbucket.parent_tracking": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
    "luci.buildbucket.use_bbagent": "EXPERIMENT_REASON_BUILDER_CONFIG",
    "luci.buildbucket.use_bbagent_race": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
    "luci.buildbucket.wait_for_capacity_in_slices": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
    "luci.non_production": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
    "luci.recipes.use_python3": "EXPERIMENT_REASON_BUILDER_CONFIG"
  },
  "agent": $agentJson,
  "knownPublicGerritHosts": [
    "android.googlesource.com",
    "aomedia.googlesource.com",
    "boringssl.googlesource.com",
    "chromium.googlesource.com",
    "dart.googlesource.com",
    "dawn.googlesource.com",
    "fuchsia.googlesource.com",
    "gn.googlesource.com",
    "go.googlesource.com",
    "llvm.googlesource.com",
    "pdfium.googlesource.com",
    "quiche.googlesource.com",
    "skia.googlesource.com",
    "swiftshader.googlesource.com",
    "webrtc.googlesource.com"
  ],
  "buildNumber": true
}
''';

  test('BuildBucketV2', () {
    final BuildBucket buildBucket = BuildBucket.fromJson(jsonDecode(buildBucketV2Json));
  });

const String swarmingJson = '''
{
  "hostname": "chromium-swarm-dev.appspot.com",
  "taskId": "62f2e84ef8411d10",
  "taskServiceAccount": "chromium-ci-builder-dev@chops-service-accounts.iam.gserviceaccount.com",
  "priority": 30,
  "taskDimensions": [
    {
      "key": "cpu",
      "value": "arm64"
    },
    {
      "key": "os",
      "value": "Mac-13"
    },
    {
      "key": "pool",
      "value": "luci.chromium.ci"
    }
  ],
  "caches": [
    {
      "name": "builder_1b2b6e615f25d48545b2db3de147e58b8bea002f690605063288929bc1781d28_v2",
      "path": "builder",
      "waitForWarmCache": "240s"
    },
    {
      "name": "git",
      "path": "git"
    },
    {
      "name": "goma",
      "path": "goma"
    },
    {
      "name": "vpython",
      "path": "vpython",
      "envVar": "VPYTHON_VIRTUALENV_ROOT"
    }
  ]
}
''';

  test('Swarming', () {
    final Swarming swarming = Swarming.fromJson(jsonDecode(swarmingJson));
    expect(swarming, isNotNull);
  });

  test('BuildInfra', () {
    final BuildInfra buildInfra = BuildInfra();
  });
}