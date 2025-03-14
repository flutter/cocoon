# Cocoon Server

This package contains server-side functionality shared between [`app_dart`][]
and [`auto_submit`][].

[`app_dart`]: ../../app_dart/
[`auto_submit`]: ../../auto_submit/

What should go into this package:

- Shared code used directly in a server package in `flutter/cocoon`

What should _not_ go into this package:

- Code that imports or uses the Flutter SDK
- Code that will be imported or used _outside_ of `flutter/cocoon`
- Code that is used _exclusively_ for testing[^1], i.e. depends on `package:test` or similar
