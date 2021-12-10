The release dashboard is a Flutter desktop app to publish a release of the Flutter SDK.
It has the same functionalities as the command-line tool (conductor: `https://github.com/flutter/flutter/tree/master/dev/conductor`) with a more user-friendly UI and an improved workflow. It uses the same core code
as the conductor.

Also see
https://github.com/flutter/flutter/wiki/Release-process for more information on
the release process.

It is designed to make the Flutter SDK releaes process easier.

## Requirements

Some basic requirements to publish a release are:

- a Linux or macOS computer set up for Flutter development. The release dashboard does
  not support Windows.
- git
- Mirrors on GitHub of the Flutter
  [framework](https://github.com/flutter/flutter) and
  [engine](https://github.com/flutter/engine) repositories.
- Flutter SDK >=2.12.0 <3.0.0 with desktop enabled.


# Using the release dashboard

Run this app as a MacOS or Linux desktop app locally from the root directory, and follow each step
in order. The release dashboard
supports resuming from a previously incompleted release. In another word, if the app is closed or stopped
during a release in progress, reopning the app will resume the release progress from where it was left off. 

## Prod of Dev mode

The release dashboard supports production and development modes. To toggle between the modes, simply
switch the boolean `isDev` located just before `WidgetsFlutterBinding.ensureInitialized();` in `./lib/main.dart`.
If `isDev` is true (default), the release dashboard is in development mode. Otherwise, it is in production mode.
