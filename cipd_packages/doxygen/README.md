# Doxygen

This utility tool is used by LUCI infrastructure to manage the CIPD package
for [Doxygen](https://www.doxygen.nl/).

It offers support for linux only at this time.

## Dependencies

Building requires an installation of relatively new versions of `bison` and `yacc`,
as well as `cmake`, `make` and a C++ compiler toolchain.

## Building

Doxygen is meant to be distributed via CIPD.

To create the CIPD package, first make sure that the `build/` and `doxygen_src/`
folders do not exist.

The build script will download a specific version of Doxygen from the GitHub
page of [Doxygen releases](https://github.com/doxygen/doxygen/tags).

Which version it downloads can be changed by changing the RELEASE variable
inside of the build script.

### Auto build

Every new commit will trigger pre-submit builders to auto build a new version
for different platforms without any tag/ref.

When a new commit is submitted, post-submit builders will trigger a new version
with a tag of `commit_sha`, and a ref of `staging`.

### Manual build

Running `tool/build.sh` will build an executable binary in the `build/bin` folder.
Then push to cipd by running

```bash
cipd create -in build                   \
  -name flutter/doxygen/<os>-amd64 \
  -ref <ref>                     \
  -tag sha_timestamp:<revision>_<timestamp>
```

* os: `linux`, `mac`, or `windows`.
* ref: `release` or `staging`
