# device_doctor

This utility tool is used by LUCI infrastructure to manage device health
for Flutter LUCI swarming bots.

It offers support for different platforms: linux, mac and windows, and
different devices: android and iOS.

## Dependencies

Different devices require different tools to be in the `path` beforehand.

### android
* `adb`

### iOS
* `idevice_id`
* `idevicediagnostics`

## Building

This tool is meant to be published as an AOT compiled binary distributed via
CIPD. To build the AOT binary, run `tool/build.sh` for linux and mac, and run
`tool/build.bat` for windows.

Build the tool for different platforms on corresponding machines. It will
automatically download a suitable version of Dart to build the binary.

To create the CIPD package, make sure that the `build/` folder does not exist.

### Auto build

Every new commit will trigger pre-submit builders to auto build a new version
for different platforms without any tag/ref.

When a new commit is submitted, post-submit builders will trigger a new version
with a tag of `commit_sha`, and a ref of `staging`.

### Manual build

Running `tool/build.sh` or `tool/build.bat` will build an executable binary in
the `build` folder. Then push to cipd by running

```bash
cipd create -in build                   \
  -name flutter/device_doctor/<os>-amd64 \
  -ref <ref>                     \
  -tag sha_timestamp:<revision>_<timestamp>
```

* os: `linux`, `mac`, or `windows`.
* ref: `release` or `staging`

## How to use

`device_doctor` is the executable binary, and can be called

```bash
/path/to/device_doctor --action <healthcheck|recovery|properties> --device-os <device_os>
```

* action
  * healthcheck: check device health status
  * recovery: clean up and reboot device
  * properties: return device properties/dimensions
* device_os
  * android
  * ios

**Note**: this tool is assuming one connected device on each host, but can be easily extended
to support multiple devices.
