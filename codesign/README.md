# codesign

A standalone tool to codesign Mac engine binaries.

## Building

This tool is meant to be published as an
[AOT compiled binary](https://chrome-infra-packages.appspot.com/p/flutter/codesign)
distributed via CIPD.

Build the tool for different host platforms on corresponding machines. It will
automatically download a suitable version of Dart to build the binary.

To create the CIPD package, make sure that the `build/` folder does not exist.

### Auto build

Every new commit will trigger pre-submit builders to auto build a new version
for different platforms without any tag/ref.

When a new commit is submitted, post-submit builders will trigger a new version
with a tag of `commit_sha`, and a ref of `staging`.

### Manual build

Running `tool/build.sh` will build an executable binary in
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

`codesign` is the executable binary, and can be called

```bash
/path/to/codesign --commit <commit_sha> (--production)
--filepath <darwin-x64/FlutterMacOS.framework.zip>
--filepath <ios/artifacts.zip>
--filepath <more_file_path>
```

Use `/path/to/codesign --help` to learn more.

**Note**: Do not add the --production flag unless the binaries are
intended to be uploaded back to Google Cloud Storage.