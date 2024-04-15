import 'dart:convert';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_service/src/model/luci/user_data.dart';
import 'package:test/test.dart';

void main() {
  test('encode and decode', () {
    final Map<String, dynamic> userDataMap = {};
    userDataMap['test'] = 'value';

    final List<int>? userDataBytes = UserData.encodeUserDataToBytes(userDataMap);
    final String? userDataString = UserData.encodeUserDataToString(userDataMap);
    print(userDataString);
    final returnUserDataMap = UserData.decodeUserDataBytes(userDataBytes!);
    print(returnUserDataMap);
  });

  test('Map test', () {
    final bbv2.Build build = bbv2.Build.create();
    build.mergeFromProto3Json(jsonDecode(sampleBuildNoProperties));
    final bbv2.Struct propertiesStruct =
        (build.input.hasProperties()) ? build.input.properties : bbv2.Struct().createEmptyInstance();
    final Map<String, Object?> properties = propertiesStruct.toProto3Json() as Map<String, Object?>;
    assert(properties.isNotEmpty);
  });
}

String sampleBuild = '''
{
      "id": "8766855135863637953",
      "builder": {
        "project": "flutter",
        "bucket": "try",
        "builder": "Windows Engine Drone"
      },
      "number": 259942,
      "createdBy": "user:flutter-try-builder@chops-service-accounts.iam.gserviceaccount.com",
      "createTime": "2023-10-18T23:40:43.480388983Z",
      "startTime": "2023-10-18T23:40:45.692900Z",
      "updateTime": "2023-10-18T23:47:04.674226745Z",
      "status": "STARTED",
      "input": {
        "properties": {
          "\$flutter/goma": {
            "server": "rbe-prod1.endpoints.fuchsia-infra-goma-prod.cloud.goog"
          },
          "\$flutter/rbe": {
            "instance": "projects/flutter-rbe-prod/instances/default",
            "platform": "container-image=docker://gcr.io/cloud-marketplace/google/debian11@sha256:69e2789c9f3d28c6a0f13b25062c240ee7772be1f5e6d41bb4680b63eae6b304"
          },
          "\$kitchen": {
            "emulate_gce": true
          },
          "\$recipe_engine/isolated": {
            "server": "https://isolateserver.appspot.com"
          },
          "\$recipe_engine/path": {
            "cache_dir": "C:cache",
            "temp_dir": "C:t"
          },
          "\$recipe_engine/swarming": {
            "server": "https://chromium-swarm.appspot.com"
          },
          "add_recipes_cq": true,
          "bot_id": "flutter-try-windows-us-central1-f-16-8a9p",
          "bringup": false,
          "build": {
            "archives": [
              {
                "base_path": "out/host_release_arm64/zip_archives/",
                "include_paths": [
                  "out/host_release_arm64/zip_archives/windows-arm64-release/windows-arm64-flutter.zip"
                ],
                "name": "host_profile_arm64",
                "realm": "production",
                "type": "gcs"
              }
            ],
            "drone_dimensions": [
              "device_type=none",
              "os=Windows-10"
            ],
            "gclient_variables": {
              "download_android_deps": false
            },
            "generators": {},
            "gn": [
              "--runtime-mode",
              "release",
              "--no-lto",
              "--windows-cpu",
              "arm64"
            ],
            "name": "host_release_arm64",
            "ninja": {
              "config": "host_release_arm64",
              "targets": [
                "windows",
                "gen_snapshot",
                "flutter/build/archives:windows_flutter"
              ]
            },
            "recipe": "engine_v2/builder"
          },
          "build_android_aot": false,
          "build_android_debug": false,
          "build_android_jit_release": false,
          "build_android_vulkan": false,
          "build_fuchsia": false,
          "build_host": false,
          "build_ios": false,
          "buildnumber": 13882,
          "clobber": false,
          "config_name": "windows_arm_host_engine",
          "device_type": "none",
          "exe_cipd_version": "refs/heads/main",
          "gclient_variables": {
            "download_android_deps": false
          },
          "gcs_goldens_bucket": "",
          "git_branch": "main",
          "git_ref": "refs/pull/47066/head",
          "git_repo": "engine",
          "git_url": "https://github.com/flutter/engine",
          "gold_tryjob": true,
          "goma_jobs": "200",
          "ios_debug": false,
          "ios_profile": false,
          "ios_release": false,
          "mastername": "client.flutter",
          "no_lto": true,
          "os": "Windows-10",
          "rbe_jobs": "200",
          "recipe": "engine_v2/builder",
          "upload_packages": false,
          "use_cas": true
        },
        "experiments": [
          "luci.buildbucket.agent.cipd_installation",
          "luci.buildbucket.agent.start_build",
          "luci.buildbucket.backend_go",
          "luci.buildbucket.bbagent_getbuild",
          "luci.buildbucket.bq_exporter_go",
          "luci.buildbucket.parent_tracking",
          "luci.buildbucket.use_bbagent",
          "luci.recipes.use_python3"
        ]
      },
      "output": {
        "properties": {
          "git_cache_epoch": "1687554665",
          "got_engine_revision": "4d97460a271ceab7335b4e22110df77e9d3fd9a7"
        },
        "logs": [
          {
            "name": "stdout",
            "viewUrl": "https://logs.chromium.org/logs/flutter/buildbucket/cr-buildbucket/8766855135863637953/+/u/stdout",
            "url": "logdog://logs.chromium.org/flutter/buildbucket/cr-buildbucket/8766855135863637953/+/u/stdout"
          },
          {
            "name": "stderr",
            "viewUrl": "https://logs.chromium.org/logs/flutter/buildbucket/cr-buildbucket/8766855135863637953/+/u/stderr",
            "url": "logdog://logs.chromium.org/flutter/buildbucket/cr-buildbucket/8766855135863637953/+/u/stderr"
          }
        ],
        "status": "STARTED"
      },
      "infra": {
        "buildbucket": {
          "requestedProperties": {
            "\$flutter/goma": {
              "server": "rbe-prod1.endpoints.fuchsia-infra-goma-prod.cloud.goog"
            },
            "\$flutter/rbe": {
              "instance": "projects/flutter-rbe-prod/instances/default",
              "platform": "container-image=docker://gcr.io/cloud-marketplace/google/debian11@sha256:69e2789c9f3d28c6a0f13b25062c240ee7772be1f5e6d41bb4680b63eae6b304"
            },
            "\$kitchen": {
              "emulate_gce": true
            },
            "\$recipe_engine/isolated": {
              "server": "https://isolateserver.appspot.com"
            },
            "\$recipe_engine/path": {
              "cache_dir": "C:cache",
              "temp_dir": "C:t"
            },
            "\$recipe_engine/swarming": {
              "server": "https://chromium-swarm.appspot.com"
            },
            "add_recipes_cq": true,
            "bot_id": "flutter-try-windows-us-central1-f-16-8a9p",
            "bringup": false,
            "build": {
              "archives": [
                {
                  "base_path": "out/host_release_arm64/zip_archives/",
                  "include_paths": [
                    "out/host_release_arm64/zip_archives/windows-arm64-release/windows-arm64-flutter.zip"
                  ],
                  "name": "host_profile_arm64",
                  "realm": "production",
                  "type": "gcs"
                }
              ],
              "drone_dimensions": [
                "device_type=none",
                "os=Windows-10"
              ],
              "gclient_variables": {
                "download_android_deps": false
              },
              "generators": {},
              "gn": [
                "--runtime-mode",
                "release",
                "--no-lto",
                "--windows-cpu",
                "arm64"
              ],
              "name": "host_release_arm64",
              "ninja": {
                "config": "host_release_arm64",
                "targets": [
                  "windows",
                  "gen_snapshot",
                  "flutter/build/archives:windows_flutter"
                ]
              },
              "recipe": "engine_v2/builder"
            },
            "build_android_aot": false,
            "build_android_debug": false,
            "build_android_jit_release": false,
            "build_android_vulkan": false,
            "build_fuchsia": false,
            "build_host": false,
            "build_ios": false,
            "buildnumber": 13882,
            "clobber": false,
            "config_name": "windows_arm_host_engine",
            "device_type": "none",
            "exe_cipd_version": "refs/heads/main",
            "gclient_variables": {
              "download_android_deps": false
            },
            "gcs_goldens_bucket": "",
            "git_branch": "main",
            "git_ref": "refs/pull/47066/head",
            "git_repo": "engine",
            "git_url": "https://github.com/flutter/engine",
            "gold_tryjob": true,
            "goma_jobs": "200",
            "ios_debug": false,
            "ios_profile": false,
            "ios_release": false,
            "mastername": "client.flutter",
            "no_lto": true,
            "os": "Windows-10",
            "rbe_jobs": "200",
            "recipe": "engine_v2/builder",
            "upload_packages": false,
            "use_cas": true
          },
          "requestedDimensions": [
            {
              "key": "device_type",
              "value": "none"
            },
            {
              "key": "os",
              "value": "Windows-10"
            }
          ],
          "hostname": "cr-buildbucket.appspot.com",
          "experimentReasons": {
            "luci.best_effort_platform": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
            "luci.buildbucket.agent.cipd_installation": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
            "luci.buildbucket.agent.start_build": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
            "luci.buildbucket.backend_go": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
            "luci.buildbucket.bbagent_getbuild": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
            "luci.buildbucket.bq_exporter_go": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
            "luci.buildbucket.canary_software": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
            "luci.buildbucket.parent_tracking": "EXPERIMENT_REASON_REQUESTED",
            "luci.buildbucket.use_bbagent": "EXPERIMENT_REASON_BUILDER_CONFIG",
            "luci.buildbucket.use_bbagent_race": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
            "luci.non_production": "EXPERIMENT_REASON_REQUESTED",
            "luci.recipes.use_python3": "EXPERIMENT_REASON_BUILDER_CONFIG"
          },
          "agent": {
            "input": {
              "data": {
                "bbagent_utility_packages": {
                  "cipd": {
                    "specs": [
                      {
                        "package": "infra/tools/luci/cas/\${platform}",
                        "version": "git_revision:ec494f363fdfd8cdd5926baad4508d562b7353d4"
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
                    "specs": [
                      {
                        "package": "infra/3pp/tools/git/\${platform}",
                        "version": "version:2@2.42.0.chromium.11"
                      },
                      {
                        "package": "infra/tools/git/\${platform}",
                        "version": "git_revision:ec494f363fdfd8cdd5926baad4508d562b7353d4"
                      },
                      {
                        "package": "infra/tools/luci/git-credential-luci/\${platform}",
                        "version": "git_revision:ec494f363fdfd8cdd5926baad4508d562b7353d4"
                      },
                      {
                        "package": "infra/tools/luci/docker-credential-luci/\${platform}",
                        "version": "git_revision:ec494f363fdfd8cdd5926baad4508d562b7353d4"
                      },
                      {
                        "package": "infra/tools/luci/vpython3/\${platform}",
                        "version": "git_revision:7c18303a74d8a6ae4bb3aae9de8f659cc8a6c571"
                      },
                      {
                        "package": "infra/tools/luci/lucicfg/\${platform}",
                        "version": "git_revision:34ddbb29b2632cdcec7648a40a9e0150ad33fd6c"
                      },
                      {
                        "package": "infra/tools/luci-auth/\${platform}",
                        "version": "git_revision:ec494f363fdfd8cdd5926baad4508d562b7353d4"
                      },
                      {
                        "package": "infra/tools/bb/\${platform}",
                        "version": "git_revision:ec494f363fdfd8cdd5926baad4508d562b7353d4"
                      },
                      {
                        "package": "infra/tools/cloudtail/\${platform}",
                        "version": "git_revision:ec494f363fdfd8cdd5926baad4508d562b7353d4"
                      },
                      {
                        "package": "infra/tools/prpc/\${platform}",
                        "version": "git_revision:ec494f363fdfd8cdd5926baad4508d562b7353d4"
                      },
                      {
                        "package": "infra/tools/rdb/\${platform}",
                        "version": "git_revision:ec494f363fdfd8cdd5926baad4508d562b7353d4"
                      },
                      {
                        "package": "infra/tools/luci/led/\${platform}",
                        "version": "git_revision:0bb208f2de6f3e9c698b70a33cd01c6de9985db2"
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
                    "specs": [
                      {
                        "package": "infra/3pp/tools/cpython3/\${platform}",
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
                    "specs": [
                      {
                        "package": "flutter/recipe_bundles/flutter.googlesource.com/recipes",
                        "version": "refs/heads/main"
                      }
                    ]
                  }
                }
              }
            },
            "output": {
              "resolvedData": {
                "": {
                  "cipd": {
                    "specs": [
                      {
                        "package": "infra/tools/luci/bbagent/windows-amd64",
                        "version": "CWZTz-PPn4V6PQOLwboppTkVcHpDBw4mbSFdFzSCVZ8C"
                      }
                    ]
                  }
                },
                "bbagent_utility_packages": {
                  "cipd": {
                    "specs": [
                      {
                        "package": "infra/tools/luci/cas/windows-amd64",
                        "version": "GLca2xxHU1T7i8mC6CIQaVHYTpBsIgbfg461-p9auHgC"
                      }
                    ]
                  }
                },
                "cipd_bin_packages": {
                  "cipd": {
                    "specs": [
                      {
                        "package": "infra/3pp/tools/git/windows-amd64",
                        "version": "nUmXIMXMWYpRRL5G_imH9ylYe8OuFrw8E8E-aQqNniQC"
                      },
                      {
                        "package": "infra/tools/git/windows-amd64",
                        "version": "k9xBg8ePL7uiVWiSpRNiuwhZvIFXw9To1-Y7zmGLEsoC"
                      },
                      {
                        "package": "infra/tools/luci/git-credential-luci/windows-amd64",
                        "version": "wTYHK_9ozzrCAhNvSJQ2aNh4Xj_WdSZH8z_iPGygl1EC"
                      },
                      {
                        "package": "infra/tools/luci/docker-credential-luci/windows-amd64",
                        "version": "TkZdTN7vFH_togft9p4cUxn0aO3uvwCX2KCpCimlN0cC"
                      },
                      {
                        "package": "infra/tools/luci/vpython3/windows-amd64",
                        "version": "1JfARK50t0eNaL62bEi837AkuEnOCDAenGnpGcVplFUC"
                      },
                      {
                        "package": "infra/tools/luci/lucicfg/windows-amd64",
                        "version": "cWjTUBeuuKTpxum2UgieF5Gpk7maDGMWzGLrxPrIVBcC"
                      },
                      {
                        "package": "infra/tools/luci-auth/windows-amd64",
                        "version": "aIJRax7rJxdMLPUzrI7z7Semi5aWdt5LNaogSG72ke8C"
                      },
                      {
                        "package": "infra/tools/bb/windows-amd64",
                        "version": "AJCTgGxzUFvFWEY7pC3huf3BQJCRdE3dr06fqyD6_3sC"
                      },
                      {
                        "package": "infra/tools/cloudtail/windows-amd64",
                        "version": "wkrKDMSgJA6K4j1y5UkoGT8RJr2xcYqrRGd7EkpsamgC"
                      },
                      {
                        "package": "infra/tools/prpc/windows-amd64",
                        "version": "uVp8B8Ebw_buQCapgLcKbbABtQOBXTP69BZ-hiRjstIC"
                      },
                      {
                        "package": "infra/tools/rdb/windows-amd64",
                        "version": "LpQ6w9adpEItDPjyzrdc9JkgmySUqjIoawxM6XchQAwC"
                      },
                      {
                        "package": "infra/tools/luci/led/windows-amd64",
                        "version": "GUOxVDh_JsTrFpG8smahZzLBlOyWsiJBMfWm5RWm6qEC"
                      }
                    ]
                  }
                },
                "cipd_bin_packages/cpython3": {
                  "cipd": {
                    "specs": [
                      {
                        "package": "infra/3pp/tools/cpython3/windows-amd64",
                        "version": "55_vUpmQ9RyBMmHoJvSChlnlP07QjmvRaFAG4q4AF-QC"
                      }
                    ]
                  }
                },
                "kitchen-checkout": {
                  "cipd": {
                    "specs": [
                      {
                        "package": "flutter/recipe_bundles/flutter.googlesource.com/recipes",
                        "version": "y0oPD122qjmiYkrkpcIhZ0GZSeBgKYUHpiRAUuEAjGcC"
                      }
                    ]
                  }
                }
              },
              "status": "SUCCESS",
              "agentPlatform": "windows-amd64",
              "totalDuration": "17s"
            },
            "source": {
              "cipd": {
                "package": "infra/tools/luci/bbagent/\${platform}",
                "version": "git_revision:d210fcc40e0faaaf5b0a8bf57a8db5bfe1638c33"
              }
            },
            "purposes": {
              "bbagent_utility_packages": "PURPOSE_BBAGENT_UTILITY",
              "kitchen-checkout": "PURPOSE_EXE_PAYLOAD"
            }
          },
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
        },
        "swarming": {
          "hostname": "chromium-swarm.appspot.com",
          "taskId": "655dfb42a28dbe10",
          "parentRunId": "655df9add49f7311",
          "taskServiceAccount": "flutter-try-builder@chops-service-accounts.iam.gserviceaccount.com",
          "priority": 30,
          "taskDimensions": [
            {
              "key": "device_type",
              "value": "none"
            },
            {
              "key": "os",
              "value": "Windows-10"
            },
            {
              "key": "pool",
              "value": "luci.flutter.try"
            }
          ],
          "botDimensions": [
            {
              "key": "bot_config",
              "value": "bot_config.py"
            },
            {
              "key": "caches",
              "value": "engine_main_builder"
            },
            {
              "key": "caches",
              "value": "engine_main_git"
            },
            {
              "key": "caches",
              "value": "flutter_main_android_sdk_version_33v6_legacy"
            },
            {
              "key": "caches",
              "value": "flutter_main_certs_version_9563bb"
            },
            {
              "key": "caches",
              "value": "flutter_main_chrome_and_driver_version_119_0_6045_9_legacy"
            },
            {
              "key": "caches",
              "value": "flutter_main_open_jdk_version_11_legacy"
            },
            {
              "key": "caches",
              "value": "goma_v2"
            },
            {
              "key": "caches",
              "value": "packages_main_certs_version_9563bb"
            },
            {
              "key": "caches",
              "value": "vpython"
            },
            {
              "key": "cipd_platform",
              "value": "windows-amd64"
            },
            {
              "key": "cores",
              "value": "16"
            },
            {
              "key": "cpu",
              "value": "x86"
            },
            {
              "key": "cpu",
              "value": "x86-64"
            },
            {
              "key": "cpu",
              "value": "x86-64-Broadwell_GCE"
            },
            {
              "key": "device_os",
              "value": "none"
            },
            {
              "key": "device_type",
              "value": "none"
            },
            {
              "key": "display_attached",
              "value": "0"
            },
            {
              "key": "gce",
              "value": "1"
            },
            {
              "key": "gcp",
              "value": "flutter-machines-prod"
            },
            {
              "key": "gpu",
              "value": "none"
            },
            {
              "key": "id",
              "value": "flutter-try-flutterprj-windows-us-central1-b-1-602w"
            },
            {
              "key": "image",
              "value": "chrome-win10-22h2-23101200-2b28f7ecb56"
            },
            {
              "key": "inside_docker",
              "value": "0"
            },
            {
              "key": "integrity",
              "value": "high"
            },
            {
              "key": "locale",
              "value": "en_US.cp1252"
            },
            {
              "key": "machine_type",
              "value": "e2-highmem-16"
            },
            {
              "key": "os",
              "value": "Windows"
            },
            {
              "key": "os",
              "value": "Windows-10"
            },
            {
              "key": "os",
              "value": "Windows-10-19045"
            },
            {
              "key": "os",
              "value": "Windows-10-19045.2006"
            },
            {
              "key": "pool",
              "value": "luci.flutter.try"
            },
            {
              "key": "python",
              "value": "3"
            },
            {
              "key": "python",
              "value": "3.8"
            },
            {
              "key": "python",
              "value": "3.8.9"
            },
            {
              "key": "server_version",
              "value": "7419-34ac013"
            },
            {
              "key": "ssd",
              "value": "1"
            },
            {
              "key": "visual_studio_version",
              "value": "16.0"
            },
            {
              "key": "windows_client_version",
              "value": "10"
            },
            {
              "key": "zone",
              "value": "us"
            },
            {
              "key": "zone",
              "value": "us-central"
            },
            {
              "key": "zone",
              "value": "us-central1"
            },
            {
              "key": "zone",
              "value": "us-central1-b"
            }
          ],
          "caches": [
            {
              "name": "pub_cache",
              "path": ".pub-cache"
            },
            {
              "name": "engine_main_builder",
              "path": "builder"
            },
            {
              "name": "engine_main_git",
              "path": "git"
            },
            {
              "name": "goma_v2",
              "path": "goma"
            },
            {
              "name": "engine_main_open_jdk_version_11_legacy",
              "path": "java"
            },
            {
              "name": "engine_main_open_jdk_version_11",
              "path": "open_jdk"
            },
            {
              "name": "vpython",
              "path": "vpython",
              "envVar": "VPYTHON_VIRTUALENV_ROOT"
            }
          ]
        },
        "logdog": {
          "hostname": "logs.chromium.org",
          "project": "flutter",
          "prefix": "buildbucket/cr-buildbucket/8766855135863637953"
        },
        "resultdb": {
          "hostname": "results.api.cr.dev"
        },
        "bbagent": {
          "payloadPath": "kitchen-checkout",
          "cacheDir": "cache"
        }
      },
      "tags": [
        {
          "key": "buildset",
          "value": "pr/git/47066"
        },
        {
          "key": "buildset",
          "value": "sha/git/4d97460a271ceab7335b4e22110df77e9d3fd9a7"
        },
        {
          "key": "parent_buildbucket_id",
          "value": "8766855244016195329"
        },
        {
          "key": "parent_task_id",
          "value": "655df9add49f7311"
        },
        {
          "key": "user_agent",
          "value": "recipe"
        }
      ],
      "exe": {
        "cipdPackage": "flutter/recipe_bundles/flutter.googlesource.com/recipes",
        "cipdVersion": "refs/heads/main",
        "cmd": [
          "luciexe"
        ]
      },
      "schedulingTimeout": "21600s",
      "executionTimeout": "3600s",
      "gracePeriod": "30s",
      "ancestorIds": [
        "8766855244016195329"
      ]
    }

''';

String sampleBuildNoProperties = '''
{
      "id": "8766855135863637953",
      "builder": {
        "project": "flutter",
        "bucket": "try",
        "builder": "Windows Engine Drone"
      },
      "number": 259942,
      "createdBy": "user:flutter-try-builder@chops-service-accounts.iam.gserviceaccount.com",
      "createTime": "2023-10-18T23:40:43.480388983Z",
      "startTime": "2023-10-18T23:40:45.692900Z",
      "updateTime": "2023-10-18T23:47:04.674226745Z",
      "status": "STARTED",
      "input": {
        "properties": {
          
        },
        "experiments": [
          "luci.buildbucket.agent.cipd_installation",
          "luci.buildbucket.agent.start_build",
          "luci.buildbucket.backend_go",
          "luci.buildbucket.bbagent_getbuild",
          "luci.buildbucket.bq_exporter_go",
          "luci.buildbucket.parent_tracking",
          "luci.buildbucket.use_bbagent",
          "luci.recipes.use_python3"
        ]
      },
      "output": {
        "properties": {
          "git_cache_epoch": "1687554665",
          "got_engine_revision": "4d97460a271ceab7335b4e22110df77e9d3fd9a7"
        },
        "logs": [
          {
            "name": "stdout",
            "viewUrl": "https://logs.chromium.org/logs/flutter/buildbucket/cr-buildbucket/8766855135863637953/+/u/stdout",
            "url": "logdog://logs.chromium.org/flutter/buildbucket/cr-buildbucket/8766855135863637953/+/u/stdout"
          },
          {
            "name": "stderr",
            "viewUrl": "https://logs.chromium.org/logs/flutter/buildbucket/cr-buildbucket/8766855135863637953/+/u/stderr",
            "url": "logdog://logs.chromium.org/flutter/buildbucket/cr-buildbucket/8766855135863637953/+/u/stderr"
          }
        ],
        "status": "STARTED"
      },
      "infra": {
        "buildbucket": {
          "requestedProperties": {
            "\$flutter/goma": {
              "server": "rbe-prod1.endpoints.fuchsia-infra-goma-prod.cloud.goog"
            },
            "\$flutter/rbe": {
              "instance": "projects/flutter-rbe-prod/instances/default",
              "platform": "container-image=docker://gcr.io/cloud-marketplace/google/debian11@sha256:69e2789c9f3d28c6a0f13b25062c240ee7772be1f5e6d41bb4680b63eae6b304"
            },
            "\$kitchen": {
              "emulate_gce": true
            },
            "\$recipe_engine/isolated": {
              "server": "https://isolateserver.appspot.com"
            },
            "\$recipe_engine/path": {
              "cache_dir": "C:cache",
              "temp_dir": "C:t"
            },
            "\$recipe_engine/swarming": {
              "server": "https://chromium-swarm.appspot.com"
            },
            "add_recipes_cq": true,
            "bot_id": "flutter-try-windows-us-central1-f-16-8a9p",
            "bringup": false,
            "build": {
              "archives": [
                {
                  "base_path": "out/host_release_arm64/zip_archives/",
                  "include_paths": [
                    "out/host_release_arm64/zip_archives/windows-arm64-release/windows-arm64-flutter.zip"
                  ],
                  "name": "host_profile_arm64",
                  "realm": "production",
                  "type": "gcs"
                }
              ],
              "drone_dimensions": [
                "device_type=none",
                "os=Windows-10"
              ],
              "gclient_variables": {
                "download_android_deps": false
              },
              "generators": {},
              "gn": [
                "--runtime-mode",
                "release",
                "--no-lto",
                "--windows-cpu",
                "arm64"
              ],
              "name": "host_release_arm64",
              "ninja": {
                "config": "host_release_arm64",
                "targets": [
                  "windows",
                  "gen_snapshot",
                  "flutter/build/archives:windows_flutter"
                ]
              },
              "recipe": "engine_v2/builder"
            },
            "build_android_aot": false,
            "build_android_debug": false,
            "build_android_jit_release": false,
            "build_android_vulkan": false,
            "build_fuchsia": false,
            "build_host": false,
            "build_ios": false,
            "buildnumber": 13882,
            "clobber": false,
            "config_name": "windows_arm_host_engine",
            "device_type": "none",
            "exe_cipd_version": "refs/heads/main",
            "gclient_variables": {
              "download_android_deps": false
            },
            "gcs_goldens_bucket": "",
            "git_branch": "main",
            "git_ref": "refs/pull/47066/head",
            "git_repo": "engine",
            "git_url": "https://github.com/flutter/engine",
            "gold_tryjob": true,
            "goma_jobs": "200",
            "ios_debug": false,
            "ios_profile": false,
            "ios_release": false,
            "mastername": "client.flutter",
            "no_lto": true,
            "os": "Windows-10",
            "rbe_jobs": "200",
            "recipe": "engine_v2/builder",
            "upload_packages": false,
            "use_cas": true
          },
          "requestedDimensions": [
            {
              "key": "device_type",
              "value": "none"
            },
            {
              "key": "os",
              "value": "Windows-10"
            }
          ],
          "hostname": "cr-buildbucket.appspot.com",
          "experimentReasons": {
            "luci.best_effort_platform": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
            "luci.buildbucket.agent.cipd_installation": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
            "luci.buildbucket.agent.start_build": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
            "luci.buildbucket.backend_go": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
            "luci.buildbucket.bbagent_getbuild": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
            "luci.buildbucket.bq_exporter_go": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
            "luci.buildbucket.canary_software": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
            "luci.buildbucket.parent_tracking": "EXPERIMENT_REASON_REQUESTED",
            "luci.buildbucket.use_bbagent": "EXPERIMENT_REASON_BUILDER_CONFIG",
            "luci.buildbucket.use_bbagent_race": "EXPERIMENT_REASON_GLOBAL_DEFAULT",
            "luci.non_production": "EXPERIMENT_REASON_REQUESTED",
            "luci.recipes.use_python3": "EXPERIMENT_REASON_BUILDER_CONFIG"
          },
          "agent": {
            "input": {
              "data": {
                "bbagent_utility_packages": {
                  "cipd": {
                    "specs": [
                      {
                        "package": "infra/tools/luci/cas/\${platform}",
                        "version": "git_revision:ec494f363fdfd8cdd5926baad4508d562b7353d4"
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
                    "specs": [
                      {
                        "package": "infra/3pp/tools/git/\${platform}",
                        "version": "version:2@2.42.0.chromium.11"
                      },
                      {
                        "package": "infra/tools/git/\${platform}",
                        "version": "git_revision:ec494f363fdfd8cdd5926baad4508d562b7353d4"
                      },
                      {
                        "package": "infra/tools/luci/git-credential-luci/\${platform}",
                        "version": "git_revision:ec494f363fdfd8cdd5926baad4508d562b7353d4"
                      },
                      {
                        "package": "infra/tools/luci/docker-credential-luci/\${platform}",
                        "version": "git_revision:ec494f363fdfd8cdd5926baad4508d562b7353d4"
                      },
                      {
                        "package": "infra/tools/luci/vpython3/\${platform}",
                        "version": "git_revision:7c18303a74d8a6ae4bb3aae9de8f659cc8a6c571"
                      },
                      {
                        "package": "infra/tools/luci/lucicfg/\${platform}",
                        "version": "git_revision:34ddbb29b2632cdcec7648a40a9e0150ad33fd6c"
                      },
                      {
                        "package": "infra/tools/luci-auth/\${platform}",
                        "version": "git_revision:ec494f363fdfd8cdd5926baad4508d562b7353d4"
                      },
                      {
                        "package": "infra/tools/bb/\${platform}",
                        "version": "git_revision:ec494f363fdfd8cdd5926baad4508d562b7353d4"
                      },
                      {
                        "package": "infra/tools/cloudtail/\${platform}",
                        "version": "git_revision:ec494f363fdfd8cdd5926baad4508d562b7353d4"
                      },
                      {
                        "package": "infra/tools/prpc/\${platform}",
                        "version": "git_revision:ec494f363fdfd8cdd5926baad4508d562b7353d4"
                      },
                      {
                        "package": "infra/tools/rdb/\${platform}",
                        "version": "git_revision:ec494f363fdfd8cdd5926baad4508d562b7353d4"
                      },
                      {
                        "package": "infra/tools/luci/led/\${platform}",
                        "version": "git_revision:0bb208f2de6f3e9c698b70a33cd01c6de9985db2"
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
                    "specs": [
                      {
                        "package": "infra/3pp/tools/cpython3/\${platform}",
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
                    "specs": [
                      {
                        "package": "flutter/recipe_bundles/flutter.googlesource.com/recipes",
                        "version": "refs/heads/main"
                      }
                    ]
                  }
                }
              }
            },
            "output": {
              "resolvedData": {
                "": {
                  "cipd": {
                    "specs": [
                      {
                        "package": "infra/tools/luci/bbagent/windows-amd64",
                        "version": "CWZTz-PPn4V6PQOLwboppTkVcHpDBw4mbSFdFzSCVZ8C"
                      }
                    ]
                  }
                },
                "bbagent_utility_packages": {
                  "cipd": {
                    "specs": [
                      {
                        "package": "infra/tools/luci/cas/windows-amd64",
                        "version": "GLca2xxHU1T7i8mC6CIQaVHYTpBsIgbfg461-p9auHgC"
                      }
                    ]
                  }
                },
                "cipd_bin_packages": {
                  "cipd": {
                    "specs": [
                      {
                        "package": "infra/3pp/tools/git/windows-amd64",
                        "version": "nUmXIMXMWYpRRL5G_imH9ylYe8OuFrw8E8E-aQqNniQC"
                      },
                      {
                        "package": "infra/tools/git/windows-amd64",
                        "version": "k9xBg8ePL7uiVWiSpRNiuwhZvIFXw9To1-Y7zmGLEsoC"
                      },
                      {
                        "package": "infra/tools/luci/git-credential-luci/windows-amd64",
                        "version": "wTYHK_9ozzrCAhNvSJQ2aNh4Xj_WdSZH8z_iPGygl1EC"
                      },
                      {
                        "package": "infra/tools/luci/docker-credential-luci/windows-amd64",
                        "version": "TkZdTN7vFH_togft9p4cUxn0aO3uvwCX2KCpCimlN0cC"
                      },
                      {
                        "package": "infra/tools/luci/vpython3/windows-amd64",
                        "version": "1JfARK50t0eNaL62bEi837AkuEnOCDAenGnpGcVplFUC"
                      },
                      {
                        "package": "infra/tools/luci/lucicfg/windows-amd64",
                        "version": "cWjTUBeuuKTpxum2UgieF5Gpk7maDGMWzGLrxPrIVBcC"
                      },
                      {
                        "package": "infra/tools/luci-auth/windows-amd64",
                        "version": "aIJRax7rJxdMLPUzrI7z7Semi5aWdt5LNaogSG72ke8C"
                      },
                      {
                        "package": "infra/tools/bb/windows-amd64",
                        "version": "AJCTgGxzUFvFWEY7pC3huf3BQJCRdE3dr06fqyD6_3sC"
                      },
                      {
                        "package": "infra/tools/cloudtail/windows-amd64",
                        "version": "wkrKDMSgJA6K4j1y5UkoGT8RJr2xcYqrRGd7EkpsamgC"
                      },
                      {
                        "package": "infra/tools/prpc/windows-amd64",
                        "version": "uVp8B8Ebw_buQCapgLcKbbABtQOBXTP69BZ-hiRjstIC"
                      },
                      {
                        "package": "infra/tools/rdb/windows-amd64",
                        "version": "LpQ6w9adpEItDPjyzrdc9JkgmySUqjIoawxM6XchQAwC"
                      },
                      {
                        "package": "infra/tools/luci/led/windows-amd64",
                        "version": "GUOxVDh_JsTrFpG8smahZzLBlOyWsiJBMfWm5RWm6qEC"
                      }
                    ]
                  }
                },
                "cipd_bin_packages/cpython3": {
                  "cipd": {
                    "specs": [
                      {
                        "package": "infra/3pp/tools/cpython3/windows-amd64",
                        "version": "55_vUpmQ9RyBMmHoJvSChlnlP07QjmvRaFAG4q4AF-QC"
                      }
                    ]
                  }
                },
                "kitchen-checkout": {
                  "cipd": {
                    "specs": [
                      {
                        "package": "flutter/recipe_bundles/flutter.googlesource.com/recipes",
                        "version": "y0oPD122qjmiYkrkpcIhZ0GZSeBgKYUHpiRAUuEAjGcC"
                      }
                    ]
                  }
                }
              },
              "status": "SUCCESS",
              "agentPlatform": "windows-amd64",
              "totalDuration": "17s"
            },
            "source": {
              "cipd": {
                "package": "infra/tools/luci/bbagent/\${platform}",
                "version": "git_revision:d210fcc40e0faaaf5b0a8bf57a8db5bfe1638c33"
              }
            },
            "purposes": {
              "bbagent_utility_packages": "PURPOSE_BBAGENT_UTILITY",
              "kitchen-checkout": "PURPOSE_EXE_PAYLOAD"
            }
          },
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
        },
        "swarming": {
          "hostname": "chromium-swarm.appspot.com",
          "taskId": "655dfb42a28dbe10",
          "parentRunId": "655df9add49f7311",
          "taskServiceAccount": "flutter-try-builder@chops-service-accounts.iam.gserviceaccount.com",
          "priority": 30,
          "taskDimensions": [
            {
              "key": "device_type",
              "value": "none"
            },
            {
              "key": "os",
              "value": "Windows-10"
            },
            {
              "key": "pool",
              "value": "luci.flutter.try"
            }
          ],
          "botDimensions": [
            {
              "key": "bot_config",
              "value": "bot_config.py"
            },
            {
              "key": "caches",
              "value": "engine_main_builder"
            },
            {
              "key": "caches",
              "value": "engine_main_git"
            },
            {
              "key": "caches",
              "value": "flutter_main_android_sdk_version_33v6_legacy"
            },
            {
              "key": "caches",
              "value": "flutter_main_certs_version_9563bb"
            },
            {
              "key": "caches",
              "value": "flutter_main_chrome_and_driver_version_119_0_6045_9_legacy"
            },
            {
              "key": "caches",
              "value": "flutter_main_open_jdk_version_11_legacy"
            },
            {
              "key": "caches",
              "value": "goma_v2"
            },
            {
              "key": "caches",
              "value": "packages_main_certs_version_9563bb"
            },
            {
              "key": "caches",
              "value": "vpython"
            },
            {
              "key": "cipd_platform",
              "value": "windows-amd64"
            },
            {
              "key": "cores",
              "value": "16"
            },
            {
              "key": "cpu",
              "value": "x86"
            },
            {
              "key": "cpu",
              "value": "x86-64"
            },
            {
              "key": "cpu",
              "value": "x86-64-Broadwell_GCE"
            },
            {
              "key": "device_os",
              "value": "none"
            },
            {
              "key": "device_type",
              "value": "none"
            },
            {
              "key": "display_attached",
              "value": "0"
            },
            {
              "key": "gce",
              "value": "1"
            },
            {
              "key": "gcp",
              "value": "flutter-machines-prod"
            },
            {
              "key": "gpu",
              "value": "none"
            },
            {
              "key": "id",
              "value": "flutter-try-flutterprj-windows-us-central1-b-1-602w"
            },
            {
              "key": "image",
              "value": "chrome-win10-22h2-23101200-2b28f7ecb56"
            },
            {
              "key": "inside_docker",
              "value": "0"
            },
            {
              "key": "integrity",
              "value": "high"
            },
            {
              "key": "locale",
              "value": "en_US.cp1252"
            },
            {
              "key": "machine_type",
              "value": "e2-highmem-16"
            },
            {
              "key": "os",
              "value": "Windows"
            },
            {
              "key": "os",
              "value": "Windows-10"
            },
            {
              "key": "os",
              "value": "Windows-10-19045"
            },
            {
              "key": "os",
              "value": "Windows-10-19045.2006"
            },
            {
              "key": "pool",
              "value": "luci.flutter.try"
            },
            {
              "key": "python",
              "value": "3"
            },
            {
              "key": "python",
              "value": "3.8"
            },
            {
              "key": "python",
              "value": "3.8.9"
            },
            {
              "key": "server_version",
              "value": "7419-34ac013"
            },
            {
              "key": "ssd",
              "value": "1"
            },
            {
              "key": "visual_studio_version",
              "value": "16.0"
            },
            {
              "key": "windows_client_version",
              "value": "10"
            },
            {
              "key": "zone",
              "value": "us"
            },
            {
              "key": "zone",
              "value": "us-central"
            },
            {
              "key": "zone",
              "value": "us-central1"
            },
            {
              "key": "zone",
              "value": "us-central1-b"
            }
          ],
          "caches": [
            {
              "name": "pub_cache",
              "path": ".pub-cache"
            },
            {
              "name": "engine_main_builder",
              "path": "builder"
            },
            {
              "name": "engine_main_git",
              "path": "git"
            },
            {
              "name": "goma_v2",
              "path": "goma"
            },
            {
              "name": "engine_main_open_jdk_version_11_legacy",
              "path": "java"
            },
            {
              "name": "engine_main_open_jdk_version_11",
              "path": "open_jdk"
            },
            {
              "name": "vpython",
              "path": "vpython",
              "envVar": "VPYTHON_VIRTUALENV_ROOT"
            }
          ]
        },
        "logdog": {
          "hostname": "logs.chromium.org",
          "project": "flutter",
          "prefix": "buildbucket/cr-buildbucket/8766855135863637953"
        },
        "resultdb": {
          "hostname": "results.api.cr.dev"
        },
        "bbagent": {
          "payloadPath": "kitchen-checkout",
          "cacheDir": "cache"
        }
      },
      "tags": [
        {
          "key": "buildset",
          "value": "pr/git/47066"
        },
        {
          "key": "buildset",
          "value": "sha/git/4d97460a271ceab7335b4e22110df77e9d3fd9a7"
        },
        {
          "key": "parent_buildbucket_id",
          "value": "8766855244016195329"
        },
        {
          "key": "parent_task_id",
          "value": "655df9add49f7311"
        },
        {
          "key": "user_agent",
          "value": "recipe"
        }
      ],
      "exe": {
        "cipdPackage": "flutter/recipe_bundles/flutter.googlesource.com/recipes",
        "cipdVersion": "refs/heads/main",
        "cmd": [
          "luciexe"
        ]
      },
      "schedulingTimeout": "21600s",
      "executionTimeout": "3600s",
      "gracePeriod": "30s",
      "ancestorIds": [
        "8766855244016195329"
      ]
    }
''';
