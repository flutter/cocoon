// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'models.dart';
export 'models.dart';

class ClockProvider extends InheritedNotifier<ClockModel> {
  const ClockProvider({
    Key key,
    @required Widget child,
    @required ClockModel notifier,
  }) : super(
          key: key,
          child: child,
          notifier: notifier,
        );

  static ClockModel of(BuildContext context) {
    final ClockProvider provider = context.inheritFromWidgetOfExactType(ClockProvider);
    return provider.notifier;
  }
}

class BuildBrokenProvider extends InheritedNotifier<BuildBrokenModel> {
  const BuildBrokenProvider({
    Key key,
    @required Widget child,
    @required BuildBrokenModel notifier,
  }) : super(
          key: key,
          child: child,
          notifier: notifier,
        );

  static BuildBrokenModel of(BuildContext context) {
    final BuildBrokenProvider provider = context.inheritFromWidgetOfExactType(BuildBrokenProvider);
    return provider.notifier;
  }
}

class BuildStatusProvider extends InheritedNotifier<BuildStatusModel> {
  const BuildStatusProvider({
    Key key,
    @required Widget child,
    @required BuildStatusModel notifier,
  }) : super(
          key: key,
          child: child,
          notifier: notifier,
        );

  static BuildStatusModel of(BuildContext context) {
    final BuildStatusProvider provider = context.inheritFromWidgetOfExactType(BuildStatusProvider);
    return provider.notifier;
  }
}

class CommitProvider extends InheritedNotifier<CommitModel> {
  const CommitProvider({
    Key key,
    @required Widget child,
    @required CommitModel notifier,
  }) : super(
          key: key,
          child: child,
          notifier: notifier,
        );

  static CommitModel of(BuildContext context) {
    final CommitProvider provider = context.inheritFromWidgetOfExactType(CommitProvider);
    return provider.notifier;
  }
}

class SignInProvider extends InheritedNotifier<SignInModel> {
  const SignInProvider({
    Key key,
    @required Widget child,
    @required SignInModel notifier,
  }) : super(
          key: key,
          child: child,
          notifier: notifier,
        );

  static SignInModel of(BuildContext context) {
    final SignInProvider provider = context.inheritFromWidgetOfExactType(SignInProvider);
    return provider.notifier;
  }
}

class UserSettingsProvider extends InheritedNotifier<UserSettingsModel> {
  const UserSettingsProvider({
    Key key,
    @required Widget child,
    @required UserSettingsModel notifier,
  }) : super(
          key: key,
          child: child,
          notifier: notifier,
        );

  static UserSettingsModel of(BuildContext context) {
    final UserSettingsProvider provider = context.inheritFromWidgetOfExactType(UserSettingsProvider);
    return provider.notifier;
  }
}

class BenchmarkProvider extends InheritedNotifier<BenchmarkModel> {
  const BenchmarkProvider({
    Key key,
    @required Widget child,
    @required BenchmarkModel notifier,
  }) : super(
          key: key,
          child: child,
          notifier: notifier,
        );

  static BenchmarkModel of(BuildContext context) {
    final BenchmarkProvider provider = context.inheritFromWidgetOfExactType(BenchmarkProvider);
    return provider.notifier;
  }
}

class ApplicationProvider extends StatelessWidget {
  const ApplicationProvider({
    @required this.commitModel,
    @required this.buildStatusModel,
    @required this.buildBrokenModel,
    @required this.clockModel,
    @required this.signInModel,
    @required this.benchmarkModel,
    @required this.userSettingsModel,
    @required this.child,
  });

  final CommitModel commitModel;
  final BuildStatusModel buildStatusModel;
  final BuildBrokenModel buildBrokenModel;
  final ClockModel clockModel;
  final SignInModel signInModel;
  final BenchmarkModel benchmarkModel;
  final UserSettingsModel userSettingsModel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SignInProvider(
      notifier: signInModel,
      child: CommitProvider(
        notifier: commitModel,
        child: BuildBrokenProvider(
          notifier: buildBrokenModel,
          child: BuildStatusProvider(
            notifier: buildStatusModel,
            child: ClockProvider(
              notifier: clockModel,
              child: BenchmarkProvider(
                notifier: benchmarkModel,
                child: UserSettingsProvider(
                  notifier: userSettingsModel,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
