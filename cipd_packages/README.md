# Flutter CIPD Packages

This folder contains auto built/deployed public [CIPD packages](https://chrome-infra-packages.appspot.com/p/flutter)
used by Flutter CI. These packages will be consumed from tests and auto cached to boost future runs.

Please follow these steps to add a new package.

## Creating the package build file

Create a new sub directory under this folder named with the new package. Add a `build.sh` script for Linux/Mac or
`build.bat` for Windows, and put it under a child dir `tool`. This is the main script to build this package. Add
necessary lib files if needed.

Note:

1) we do not archive the binaries in the repo, and will auto build package artifacts and upload to CIPD via the bot.
2) please add a code owner entry under section `cipd packages` in [CODEOWNERS](https://github.com/flutter/cocoon/blob/main/CODEOWNERS) file.

## Add an entry to cocoon .ci.yaml

This is to enable the auto build and upload. Please follow the following example format:
```yaml
  - name: Mac <package_name>
    recipe: cocoon/cipd
    bringup: true
    properties:
      script: cipd_packages/<package_name>/tool/build.sh
      cipd_name: flutter/<package_name>/mac-amd64 # Use mac-arm64 for arm64 version.
      device_type: none
    runIf:
      - cipd_packages/<package_name>/**
      - .ci.yaml
```

Start with `bringup: true`, same as any other regular new target. Once validated in CI, remove it to enable running
in the `prod` environment so that artifacts are to be uploaded to CIPD.

Note: with `bringup: true`, the target will be executed in a staging environment and it validates only the logic
and will not upload to CIPD.

## Adding a reference to the CIPD package

Until this step, artifacts are being uploaded to CIPD whenever a new commit is merged.  It is useful to add a reference
to the package, so that we can use the reference in the CI recipe. This way we won’t need to change the recipe
whenever we update the package.

Googlers have default access to add a reference to a package via:
```sh
cipd set-ref flutter/PackageName/mac-amd64 -ref Reference -version InstanceID
```

* Reference: e.g. major release versions. If not specified, `latest` will be used based on the latest package instance.
* InstaneID: this can be obtained from the package page, e.g. [ruby](https://chrome-infra-packages.appspot.com/p/flutter/ruby/mac-amd64/+/TyvPskvefNRkTDmiDcwRHrdL_a2FQE_4wBojOqhxdtYC).

Note: for non-Googler contributors, please file an [infra bug](https://github.com/flutter/flutter/issues/new?assignees=&labels=team-infra&projects=&template=6_infrastructure.yml) to make a reference request.

## Supporting packages download from CI recipe

Example CL: [51547 ](https://flutter-review.googlesource.com/c/recipes/+/51547)

Refer to [CONTRIBUTING.md](https://flutter.googlesource.com/recipes/+/refs/heads/main/CONTRIBUTING.md) on how to
contribute to recipes repository.

## Adding/updating package dependency from .ci.yaml from different repositories

This is the last step to enable the package usage in the real CI. Add or update the new package to either the platform level or
target level entries for your targeted repository:
``` yaml
dependencies: >-
  [
    {"dependency": "chrome_and_driver", "version": "Reference"},
  ]
```

Note: use the `Reference` created above.

More details about configuration setup can be found in [CI_YAML.md](https://github.com/flutter/cocoon/blob/main/CI_YAML.md).