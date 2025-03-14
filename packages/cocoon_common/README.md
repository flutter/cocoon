# Cocoon Commons

This package includes functionality used across services and UIs in Cocoon,
including [`app_dart`][], [`auto_submit`][], and [`dashboard`][].

[`app_dart`]: ../../app_dart/
[`auto_submit`]: ../../auto_submit/
[`dashboard`]: ../../dashboard

What should go into this package:

- Shared code and interfaces used directly in a package in `flutter/cocoon`

What should _not_ go into this package:

- Code that is dependent on running on the server; see [`cocoon_server`](../../cocoon_server/)
- Code that imports or uses the Flutter SDK
- Code that will be imported or used _outside_ of `flutter/cocoon`
- Code that is used _exclusively_ for testing[^1], i.e. depends on `package:test` or similar

[^1]: See [`cocoon_common_test`](../cocoon_common_test/) for the testing package.
