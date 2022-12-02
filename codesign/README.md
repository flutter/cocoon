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

When a new commit is submitted, post-submit builders will trigger the build of
a new version of the cipd package, and tag the package with `latest`.

### Manual build

Running `tool/build.sh` will build an executable binary in
the `build` folder. Then push to cipd by running

```bash
cipd create -in build                   \
  -name flutter/codesign/<os>-amd64 \
  -ref <ref>                     \
  -tag sha_timestamp:<revision>_<timestamp>
```

* os: `linux`, `mac`, or `windows`.
* ref: `release` or `staging`

## How to use

`codesign` is the executable binary in the `build` folder, and can be called via

 ```bash
 ./codesign --[no-]dryrun
 --codesign-cert-name="FLUTTER.IO LLC"
 --codesign-team-id-file-path=/a/b/c.txt
 --codesign-appstore-id-file-path=/a/b/b.txt
 --app-specific-password-file-path=/a/b/a.txt
 --input-zip-file-path=/a/input.zip
 --output-zip-file-path=/b/output.zip
 ```

Use `codesign --help` to learn more.

Alternatively, if user has dart installed and does not wish to build a binary,
codesign app can be invoked via `dart run bin/codesign.dart --<extra_flags>`.
