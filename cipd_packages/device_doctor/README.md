# device_doctor

This utility tool is used by LUCI infrastructure to manage device health
for Flutter LUCI swarming bots.

It offers support for different host platforms: linux, mac and windows, and
different devices: android and iOS.

## Dependencies

Different devices require different tools to be in the `path` beforehand.

### android
* `adb`

### iOS
* `idevice_id`
* `idevicediagnostics`
* `xcrun`

## Building

This tool is meant to be published as an
[AOT compiled binary](https://chrome-infra-packages.appspot.com/p/flutter/device_doctor)
distributed via CIPD.

Build the tool for different host platforms on corresponding machines. It will
automatically download a suitable version of Dart to build the binary.

To create the CIPD package, make sure that the `build/` folder does not exist.

### Auto build

Every new commit will trigger pre-submit builders to auto build a new version
for different platforms without any tag/ref.

When a new commit is submitted, post-submit builders will trigger a new version
with a tag of `commit_sha`, and a ref of `latest`.

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
/path/to/device_doctor --action <healthcheck|recovery|properties> --device-os <android|ios>
```

Use `/path/to/device_doctor --help` to learn more.

**Note**: this tool is assuming one connected device on each host, but can be easily extended
to support multiple devices.

## Releasing device_doctor

The release process of the tool is controlled by setting `release` and `staging` refs.

To promote a given version to staging you can run the following command:

```
cipd set-ref flutter/device_doctor/<os>-<arch> -ref staging -version <packageid>
```

Example for mac and amd64:

```
cipd set-ref flutter/device_doctor/mac-amd64 -ref staging -version IQgKjNstWbFhUuMVp898zZoPKRd66KLRKuiY88XYQXAC
```

After extensive validation on staging you can promote the package to release using:


```
cipd set-ref flutter/device_doctor/<os>-<arch> -ref release -version <packageid>
```
