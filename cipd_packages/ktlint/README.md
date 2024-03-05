# ktlint at Flutter

The scripts in this folder are used to package the kotlin linter
ktlint as a self contained CIPD package. This package is used
for linting kotlin code in the flutter/flutter repository.

# Updating to new ktlint versions.

Update `ktlint_metadata.txt` with the major version
and the file name. New versions can be found at the releases page for ktlint
(https://github.com/pinterest/ktlint/releases). Before changing the version here,
you must also identify and resolve any new lints in flutter/flutter, by
running the new version of ktlint from the root of flutter/flutter (passing in the
current baseline).
