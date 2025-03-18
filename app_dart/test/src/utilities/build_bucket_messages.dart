// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_service/src/model/luci/pubsub_message.dart';
import 'package:cocoon_service/src/model/luci/user_data.dart';
import 'package:fixnum/fixnum.dart';

PushMessage createPushMessage(
  Int64 id, {
  String? project = 'flutter',
  String? bucket = 'try',
  String? builder = 'Windows Engine Drone',
  int number = 259942,
  bbv2.Status? status = bbv2.Status.SCHEDULED,
  Map<String, dynamic>? userData = const {},
  bool? addBuildSet = true,
  List<bbv2.StringPair> extraTags = const [],
}) {
  final pubSubCallBack = createPubSubCallBack(
    id,
    project: project,
    bucket: bucket,
    builder: builder,
    number: number,
    status: status,
    userData: userData,
    extraTags: extraTags,
  );

  final pubSubCallBackMap =
      pubSubCallBack.toProto3Json() as Map<String, dynamic>;

  final pubSubCallBackString = jsonEncode(pubSubCallBackMap);

  return PushMessage(data: pubSubCallBackString);
}

bbv2.PubSubCallBack createPubSubCallBack(
  Int64 id, {
  String? project = 'flutter',
  String? bucket = 'try',
  String? builder = 'Windows Engine Drone',
  int number = 259942,
  bbv2.Status? status = bbv2.Status.SCHEDULED,
  Map<String, dynamic>? userData = const {},
  List<bbv2.StringPair> extraTags = const [],
}) {
  // this contains BuildsV2PubSub and UserData (List<int>).
  final buildsPubSub = createBuild(
    id,
    project: project,
    bucket: bucket,
    builder: builder,
    number: number,
    status: status,
    extraTags: extraTags,
  );
  final userDataBytes = UserData.encodeUserDataToBytes(userData!);
  return bbv2.PubSubCallBack(
    buildPubsub: buildsPubSub,
    userData: userDataBytes,
  );
}

bbv2.BuildsV2PubSub createBuild(
  Int64 id, {
  String? project = 'flutter',
  String? bucket = 'try',
  String? builder = 'Windows Engine Drone',
  int number = 259942,
  bbv2.Status? status = bbv2.Status.SCHEDULED,
  List<bbv2.StringPair> extraTags = const [],
}) {
  final build = bbv2.BuildsV2PubSub().createEmptyInstance();
  build.mergeFromProto3Json(
    jsonDecode(
          createBuildString(
            id,
            project: project,
            bucket: bucket,
            builder: builder,
            number: number,
            status: status,
          ),
        )
        as Map<String, dynamic>,
  );
  if (extraTags.isNotEmpty) {
    build.build.tags.addAll(extraTags);
  }
  return build;
}

String createBuildString(
  Int64 id, {
  String? project = 'flutter',
  String? bucket = 'try',
  String? builder = 'Windows Engine Drone',
  int number = 259942,
  bbv2.Status? status = bbv2.Status.SCHEDULED,
}) {
  return '''
  {
  "build":  {
    "id":  "$id",
    "builder":  {
      "project":  "${project ?? 'flutter'}",
      "bucket":  "${bucket ?? 'try'}",
      "builder":  "${builder ?? 'Linux web_long_running_tests_1_5'}"
    },
    "number":  $number,
    "createdBy":  "user:flutter-dashboard@appspot.gserviceaccount.com",
    "createTime":  "2024-06-03T15:48:25.490485466Z",
    "startTime":  "2024-06-03T15:48:35.560843535Z",
    "endTime":  "2024-06-03T16:05:18.072809938Z",
    "updateTime":  "2024-06-03T16:05:18.072809938Z",
    "status":  "${status?.name ?? 'SUCCESS'}",
    "input":  {
      "experiments":  [
        "luci.buildbucket.agent.cipd_installation",
        "luci.buildbucket.agent.start_build",
        "luci.buildbucket.backend_alt",
        "luci.buildbucket.backend_go",
        "luci.buildbucket.bbagent_getbuild",
        "luci.buildbucket.bq_exporter_go",
        "luci.buildbucket.parent_tracking",
        "luci.buildbucket.use_bbagent",
        "luci.recipes.use_python3"
      ]
    },
    "output":  {
      "logs":  [
        {
          "name":  "stdout",
          "viewUrl":  "https://logs.chromium.org/logs/flutter/buildbucket/cr-buildbucket/8746138145094216865/+/u/stdout",
          "url":  "logdog://logs.chromium.org/flutter/buildbucket/cr-buildbucket/8746138145094216865/+/u/stdout"
        },
        {
          "name":  "stderr",
          "viewUrl":  "https://logs.chromium.org/logs/flutter/buildbucket/cr-buildbucket/8746138145094216865/+/u/stderr",
          "url":  "logdog://logs.chromium.org/flutter/buildbucket/cr-buildbucket/8746138145094216865/+/u/stderr"
        }
      ],
      "status":  "SUCCESS"
    },
    "infra":  {
      "buildbucket":  {
        "requestedProperties":  {
          "bringup":  false,
          "cores":  8,
          "dependencies":  [
            {
              "dependency":  "curl",
              "version":  "version:7.64.0"
            },
            {
              "dependency":  "android_sdk",
              "version":  "version:34v3"
            },
            {
              "dependency":  "chrome_and_driver",
              "version":  "version:119.0.6045.9"
            },
            {
              "dependency":  "goldctl",
              "version":  "git_revision:720a542f6fe4f92922c3b8f0fdcc4d2ac6bb83cd"
            }
          ],
          "device_type":  "none",
          "exe_cipd_version":  "refs/heads/main",
          "git_branch":  "master",
          "git_ref":  "refs/pull/149147/head",
          "git_url":  "https://github.com/flutter/flutter",
          "os":  "Ubuntu",
          "presubmit_max_attempts":  2,
          "recipe":  "flutter/flutter_drone",
          "shard":  "web_long_running_tests",
          "subshard":  "1_5",
          "tags":  [
            "framework",
            "hostonly",
            "shard",
            "linux"
          ]
        },
        "requestedDimensions":  [
          {
            "key":  "os",
            "value":  "Ubuntu"
          },
          {
            "key":  "device_type",
            "value":  "none"
          },
          {
            "key":  "cores",
            "value":  "8"
          }
        ],
        "hostname":  "cr-buildbucket.appspot.com",
        "experimentReasons":  {
          "luci.best_effort_platform":  "EXPERIMENT_REASON_GLOBAL_DEFAULT",
          "luci.buildbucket.agent.cipd_installation":  "EXPERIMENT_REASON_GLOBAL_DEFAULT",
          "luci.buildbucket.agent.start_build":  "EXPERIMENT_REASON_GLOBAL_DEFAULT",
          "luci.buildbucket.backend_alt":  "EXPERIMENT_REASON_GLOBAL_DEFAULT",
          "luci.buildbucket.backend_go":  "EXPERIMENT_REASON_GLOBAL_DEFAULT",
          "luci.buildbucket.bbagent_getbuild":  "EXPERIMENT_REASON_GLOBAL_DEFAULT",
          "luci.buildbucket.bq_exporter_go":  "EXPERIMENT_REASON_GLOBAL_DEFAULT",
          "luci.buildbucket.canary_software":  "EXPERIMENT_REASON_GLOBAL_DEFAULT",
          "luci.buildbucket.parent_tracking":  "EXPERIMENT_REASON_GLOBAL_DEFAULT",
          "luci.buildbucket.use_bbagent":  "EXPERIMENT_REASON_BUILDER_CONFIG",
          "luci.buildbucket.use_bbagent_race":  "EXPERIMENT_REASON_GLOBAL_DEFAULT",
          "luci.non_production":  "EXPERIMENT_REASON_GLOBAL_DEFAULT",
          "luci.recipes.use_python3":  "EXPERIMENT_REASON_BUILDER_CONFIG"
        },
        "agent":  {
          "input":  {
            "data":  {
              "bbagent_utility_packages":  {
                "cipd":  {
                  "server":  "chrome-infra-packages.appspot.com",
                  "specs":  [
                  {
                  "package":  "infra/tools/luci/cas/\${platform}",
                  "version":  "git_revision:2aba496613f92a5b06d577f82b5d028225d3d577"
                  }
                  ]
                },
                "onPath":  [
                  "bbagent_utility_packages",
                  "bbagent_utility_packages/bin"
                ]
              },
              "cipd_bin_packages":  {
                "cipd":  {
                  "server":  "chrome-infra-packages.appspot.com",
                  "specs":  [
                  {
                  "package":  "infra/3pp/tools/git/\${platform}",
                  "version":  "version:2@2.42.0.chromium.11"
                  },
                  {
                  "package":  "infra/tools/git/\${platform}",
                  "version":  "git_revision:2aba496613f92a5b06d577f82b5d028225d3d577"
                  },
                  {
                  "package":  "infra/tools/luci/git-credential-luci/\${platform}",
                  "version":  "git_revision:2aba496613f92a5b06d577f82b5d028225d3d577"
                  },
                  {
                  "package":  "infra/tools/luci/docker-credential-luci/\${platform}",
                  "version":  "git_revision:2aba496613f92a5b06d577f82b5d028225d3d577"
                  },
                  {
                  "package":  "infra/tools/luci/vpython3/\${platform}",
                  "version":  "git_revision:2aba496613f92a5b06d577f82b5d028225d3d577"
                  },
                  {
                  "package":  "infra/tools/luci/lucicfg/\${platform}",
                  "version":  "git_revision:2aba496613f92a5b06d577f82b5d028225d3d577"
                  },
                  {
                  "package":  "infra/tools/luci-auth/\${platform}",
                  "version":  "git_revision:2aba496613f92a5b06d577f82b5d028225d3d577"
                  },
                  {
                  "package":  "infra/tools/bb/\${platform}",
                  "version":  "git_revision:2aba496613f92a5b06d577f82b5d028225d3d577"
                  },
                  {
                  "package":  "infra/tools/cloudtail/\${platform}",
                  "version":  "git_revision:2aba496613f92a5b06d577f82b5d028225d3d577"
                  },
                  {
                  "package":  "infra/tools/prpc/\${platform}",
                  "version":  "git_revision:2aba496613f92a5b06d577f82b5d028225d3d577"
                  },
                  {
                  "package":  "infra/tools/rdb/\${platform}",
                  "version":  "git_revision:069157ce739832ec1a0a3fe11b2e37e632de50e9"
                  },
                  {
                  "package":  "infra/tools/luci/led/\${platform}",
                  "version":  "git_revision:037d7079cf3faced3842e597c9dfcc7475b2ddca"
                  }
                  ]
                },
                "onPath":  [
                  "cipd_bin_packages",
                  "cipd_bin_packages/bin"
                ]
              },
              "cipd_bin_packages/cpython3":  {
                "cipd":  {
                  "server":  "chrome-infra-packages.appspot.com",
                  "specs":  [
                  {
                  "package":  "infra/3pp/tools/cpython3/\${platform}",
                  "version":  "version:2@3.8.10.chromium.34"
                  }
                  ]
                },
                "onPath":  [
                  "cipd_bin_packages/cpython3",
                  "cipd_bin_packages/cpython3/bin"
                ]
              },
              "kitchen-checkout":  {
                "cipd":  {
                  "server":  "chrome-infra-packages.appspot.com",
                  "specs":  [
                  {
                  "package":  "flutter/recipe_bundles/flutter.googlesource.com/recipes",
                  "version":  "refs/heads/main"
                  }
                  ]
                }
              }
            },
            "cipdSource":  {
              "cipd":  {
                "cipd":  {
                  "server":  "chrome-infra-packages.appspot.com",
                  "specs":  [
                  {
                  "package":  "infra/tools/cipd/\${platform}",
                  "version":  "git_revision:215bc891d3d06dd49b11109abc9319a38aa66f0a"
                  }
                  ]
                },
                "onPath":  [
                  "cipd",
                  "cipd/bin"
                ]
              }
            }
          },
          "output":  {
            "resolvedData":  {
              "":  {
                "cipd":  {
                  "specs":  [
                  {
                  "package":  "infra/tools/luci/bbagent/linux-amd64",
                  "version":  "6tIw2DHVEcYg5xt0ETPIUzriHt6IfBcQp8ji-SvXcH8C"
                  }
                  ]
                }
              },
              "bbagent_utility_packages":  {
                "cipd":  {
                  "specs":  [
                  {
                  "package":  "infra/tools/luci/cas/linux-amd64",
                  "version":  "pGapntrQBvOpG_fzREhX19L2a7rLGwyZEB4VqXDfBzgC"
                  }
                  ]
                }
              },
              "cipd_bin_packages":  {
                "cipd":  {
                  "specs":  [
                  {
                  "package":  "infra/3pp/tools/git/linux-amd64",
                  "version":  "L93GSopVoB8RNkV6raxVg1eXHQmZdcYTrXgZoSTLWFEC"
                  },
                  {
                  "package":  "infra/tools/git/linux-amd64",
                  "version":  "Xqu_HXC1MH-P79yv4Su2jDHjdlBlV_so9HF3ax8_YSsC"
                  },
                  {
                  "package":  "infra/tools/luci/git-credential-luci/linux-amd64",
                  "version":  "f6M4HQ7vio2mfNQBCsVxBBugrsqd3p46Wvgb77mPakwC"
                  },
                  {
                  "package":  "infra/tools/luci/docker-credential-luci/linux-amd64",
                  "version":  "kAqKupATGDUHCyutoNNS4eO4BQoAW9flmdKLzAs5gX4C"
                  },
                  {
                  "package":  "infra/tools/luci/vpython3/linux-amd64",
                  "version":  "oe3aQL5rg2k6c6SGSFhCImGfhnl2zDPAFhdaCpruw_AC"
                  },
                  {
                  "package":  "infra/tools/luci/lucicfg/linux-amd64",
                  "version":  "fLMtVWN-baUP3k_0YQt9dvY1_nBaHbju4g605ds38NEC"
                  },
                  {
                  "package":  "infra/tools/luci-auth/linux-amd64",
                  "version":  "n4LZf93sXiBgdmdasB5L90v-usbwR4bRfrTU1TRNWzUC"
                  },
                  {
                  "package":  "infra/tools/bb/linux-amd64",
                  "version":  "z6fapR2_VkZiA0KVeKLa1IhNpE49LLMR0Wj8-GbKMNQC"
                  },
                  {
                  "package":  "infra/tools/cloudtail/linux-amd64",
                  "version":  "nhss9Uy2MR1OjQpgxCPE-p7kSOObNvgRnm9sBCIciQMC"
                  },
                  {
                  "package":  "infra/tools/prpc/linux-amd64",
                  "version":  "vo1eow0ro1pQ5h-LjJ17Ra2EwTnt3C3U7rsSDwTrDAcC"
                  },
                  {
                  "package":  "infra/tools/rdb/linux-amd64",
                  "version":  "zujGNFHlaTKRZBiMD_ypyXTeX8ypJfRDTkI3Rhx2AtEC"
                  },
                  {
                  "package":  "infra/tools/luci/led/linux-amd64",
                  "version":  "9MscsPmNzDEXsue8XFb0B8fENKbCp9tkjo4EGsSV0IEC"
                  }
                  ]
                }
              },
              "cipd_bin_packages/cpython3":  {
                "cipd":  {
                  "specs":  [
                  {
                  "package":  "infra/3pp/tools/cpython3/linux-amd64",
                  "version":  "3p-c2NpZEJWyv4KiHJopTR1ScaHxDKBRMfXlzpre-IwC"
                  }
                  ]
                }
              },
              "kitchen-checkout":  {
                "cipd":  {
                  "specs":  [
                  {
                  "package":  "flutter/recipe_bundles/flutter.googlesource.com/recipes",
                  "version":  "PUKnbYmIYQbnhME2pu4sISywm3vPYbxQjRL3CnRv0HMC"
                  }
                  ]
                }
              }
            },
            "status":  "SUCCESS",
            "agentPlatform":  "linux-amd64",
            "totalDuration":  "4s"
          },
          "source":  {
            "cipd":  {
              "package":  "infra/tools/luci/bbagent/\${platform}",
              "version":  "git_revision:2aba496613f92a5b06d577f82b5d028225d3d577",
              "server":  "chrome-infra-packages.appspot.com"
            }
          },
          "purposes":  {
            "bbagent_utility_packages":  "PURPOSE_BBAGENT_UTILITY",
            "kitchen-checkout":  "PURPOSE_EXE_PAYLOAD"
          },
          "cipdClientCache":  {
            "name":  "cipd_client_f970720a374db65e431d9836bdd8bc091f12dd8c12a454b5a67f5b163006301e",
            "path":  "cipd_client"
          },
          "cipdPackagesCache":  {
            "name":  "cipd_cache_9237a0836331b01a61cb7a5ed59c6f7b1fa85bf7f14cc136be4a6237cbd59011",
            "path":  "cipd_cache"
          }
        },
        "knownPublicGerritHosts":  [
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
        "buildNumber":  true
      },
      "logdog":  {
        "hostname":  "logs.chromium.org",
        "project":  "flutter",
        "prefix":  "buildbucket/cr-buildbucket/8746138145094216865"
      },
      "resultdb":  {
        "hostname":  "results.api.cr.dev"
      },
      "bbagent":  {
        "payloadPath":  "kitchen-checkout",
        "cacheDir":  "cache"
      },
      "backend":  {
        "config":  {
          "agent_binary_cipd_filename":  "bbagent\${EXECUTABLE_SUFFIX}",
          "agent_binary_cipd_pkg":  "infra/tools/luci/bbagent/\${platform}",
          "agent_binary_cipd_server":  "chrome-infra-packages.appspot.com",
          "agent_binary_cipd_vers":  "git_revision:2aba496613f92a5b06d577f82b5d028225d3d577",
          "priority":  30,
          "service_account":  "flutter-try-builder@chops-service-accounts.iam.gserviceaccount.com"
        },
        "task":  {
          "id":  {
            "target":  "swarming://chromium-swarm",
            "id":  "69f79b2ca0f23910"
          },
          "link":  "https://chromium-swarm.appspot.com/task?id=69f79b2ca0f23910&o=true&w=true",
          "status":  "SUCCESS",
          "details":  {
            "bot_dimensions":  {
              "bot_config":  [
                "bot_config.py"
              ],
              "caches":  [
                "cipd_cache_9237a0836331b01a61cb7a5ed59c6f7b1fa85bf7f14cc136be4a6237cbd59011",
                "cipd_client_f970720a374db65e431d9836bdd8bc091f12dd8c12a454b5a67f5b163006301e",
                "engine_main_builder",
                "engine_main_git",
                "flutter_main_android_sdk_version_34v3_legacy",
                "flutter_main_chrome_and_driver_version_119_0_6045_9_legacy",
                "flutter_main_open_jdk_version_17_legacy",
                "gradle",
                "packages_main_android_sdk_version_33v6_legacy",
                "packages_main_chrome_and_driver_version_114_0_legacy",
                "packages_main_open_jdk_version_11_legacy"
              ],
              "cipd_platform":  [
                "linux-amd64"
              ],
              "cores":  [
                "8"
              ],
              "cpu":  [
                "x86",
                "x86-64",
                "x86-64-Broadwell_GCE",
                "x86-64-avx2"
              ],
              "device_os":  [
                "none"
              ],
              "device_type":  [
                "none"
              ],
              "display_attached":  [
                "0"
              ],
              "gce":  [
                  "1"
              ],
              "gcp":  [
                "flutter-machines-prod"
              ],
              "gpu":  [
                "none"
              ],
              "id":  [
                "flutter-try-flutterprj-ubuntu-us-central1-b-2-s2lu"
              ],
              "image":  [
                "dart-focal-24052600-54a1aca43d9"
              ],
              "inside_docker":  [
                "0"
              ],
              "kernel":  [
                "5.15.0-1060-gcp"
              ],
              "kvm":  [
                "1"
              ],
              "locale":  [
                "en_US.UTF-8"
              ],
              "machine_type":  [
                "n1-standard-8"
              ],
              "os":  [
                "Linux",
                "Ubuntu",
                "Ubuntu-20",
                "Ubuntu-20.04",
                "Ubuntu-20.04.6"
              ],
              "pool":  [
                "luci.flutter.try"
              ],
              "puppet_env":  [
                "production"
              ],
              "python":  [
                "3",
                "3.8",
                "3.8.10+chromium.23"
              ],
              "server_version":  [
                "7672-d26f562"
              ],
              "ssd":  [
                "1"
              ],
              "zone":  [
                "us",
                "us-central",
                "us-central1",
                "us-central1-b"
              ]
            }
          },
          "updateId":  "1717430716453135104"
        },
        "caches":  [
          {
            "name":  "pub_cache",
            "path":  ".pub-cache"
          },
          {
            "name":  "flutter_main_android_sdk_version_34v3_legacy",
            "path":  "android"
          },
          {
            "name":  "flutter_main_android_sdk_version_34v3",
            "path":  "android_sdk"
          },
          {
            "name":  "flutter_main_builder",
            "path":  "builder"
          },
          {
            "name":  "flutter_main_chrome_and_driver_version_119_0_6045_9_legacy",
            "path":  "chrome"
          },
          {
            "name":  "flutter_main_chrome_and_driver_version_119_0_6045_9",
            "path":  "chrome_and_driver"
          },
          {
            "name":  "flutter_main_curl_version_7_64_0",
            "path":  "curl"
          },
          {
            "name":  "flutter_main_git",
            "path":  "git"
          },
          {
            "name":  "flutter_main_goldctl_git_revision_720a542f6fe4f92922c3b8f0fdcc4d2ac6bb83cd",
            "path":  "goldctl"
          },
          {
            "name":  "gradle",
            "path":  "gradle"
          },
          {
            "name":  "vpython",
            "path":  "vpython",
            "envVar":  "VPYTHON_VIRTUALENV_ROOT"
          }
        ],
        "taskDimensions":  [
          {
            "key":  "cores",
            "value":  "8"
          },
          {
            "key":  "device_type",
            "value":  "none"
          },
          {
            "key":  "os",
            "value":  "Ubuntu"
          },
          {
            "key":  "pool",
            "value":  "luci.flutter.try"
          }
        ],
        "hostname":  "chromium-swarm.appspot.com"
      }
    },
    "tags":  [
      {
        "key":  "buildset",
        "value":  "pr/git/149147"
      },
      {
        "key":  "buildset",
        "value":  "sha/git/5bbe0ce383e7ed77c68911a20358bbdc2f4c69dd"
      },
      {
        "key":  "cipd_version",
        "value":  "refs/heads/main"
      },
      {
        "key":  "github_checkrun",
        "value":  "25743375958"
      },
      {
        "key":  "github_link",
        "value":  "https://github.com/flutter/flutter/pull/149147"
      },
      {
        "key":  "user_agent",
        "value":  "flutter-cocoon"
      }
    ],
    "exe":  {
      "cipdPackage":  "flutter/recipe_bundles/flutter.googlesource.com/recipes",
      "cipdVersion":  "refs/heads/main",
      "cmd":  [
        "luciexe"
      ]
    },
    "schedulingTimeout":  "21600s",
    "executionTimeout":  "3600s",
    "gracePeriod":  "30s"
  },
  "buildLargeFields":  "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"
  }
  ''';
}
