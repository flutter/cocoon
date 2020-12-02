# device_doctor

This utility tool is used by LUCI infrastructure to manage device health
check, clean up and recovery for Flutter LUCI swarming bots.

It offers support for different platforms: linux, mac and windows, and
different devices: android and ios.

## Building

This tool is meant to be published as an AOT compiled binary distributed via
CIPD. To build the AOT binary, run `tool/build.sh`.

Build the tool for different platforms on corresponding machines. It will
automatically download a suitable version of Dart to build the binary.

To create the CIPD package, make sure that the `build/` folder does not exist.
Then run:

```bash
cipd create -in build                   \
  -name flutter/device_doctor/<os>-amd64 \
  -ref <dev/stable>                     \
  -tag version:n.n.n
```

with an appropriate version string, after running `tool/build.sh`.

The above script will build an executable binary in the `build` folder.

## How to use
`config.yaml` configues the device os information for corresponding hosts. The
device os info. is needed for device_doctor to manage devices. This file should
be up-to-date with DeviceLab hardwares.

`device_doctor` is the executable binary, and can be called

```bash
/path/to/device_doctor --action <healthcheck|cleanup|restart>
```
