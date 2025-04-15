// Mocks generated by Mockito 5.4.4 from annotations
// in flutter_dashboard/test/utils/mocks.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i8;
import 'dart:convert' as _i9;
import 'dart:typed_data' as _i11;
import 'dart:ui' as _i14;

import 'package:cocoon_common/rpc_model.dart' as _i12;
import 'package:firebase_auth/firebase_auth.dart' as _i7;
import 'package:firebase_core/firebase_core.dart' as _i6;
import 'package:flutter_dashboard/logic/brooks.dart' as _i5;
import 'package:flutter_dashboard/service/cocoon.dart' as _i3;
import 'package:flutter_dashboard/service/firebase_auth.dart' as _i4;
import 'package:flutter_dashboard/state/build.dart' as _i13;
import 'package:http/http.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i10;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeResponse_0 extends _i1.SmartFake implements _i2.Response {
  _FakeResponse_0(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeStreamedResponse_1 extends _i1.SmartFake
    implements _i2.StreamedResponse {
  _FakeStreamedResponse_1(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeCocoonResponse_2<T> extends _i1.SmartFake
    implements _i3.CocoonResponse<T> {
  _FakeCocoonResponse_2(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeCocoonService_3 extends _i1.SmartFake implements _i3.CocoonService {
  _FakeCocoonService_3(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeFirebaseAuthService_4 extends _i1.SmartFake
    implements _i4.FirebaseAuthService {
  _FakeFirebaseAuthService_4(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeBrook_5<T> extends _i1.SmartFake implements _i5.Brook<T> {
  _FakeBrook_5(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeFirebaseApp_6 extends _i1.SmartFake implements _i6.FirebaseApp {
  _FakeFirebaseApp_6(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeActionCodeInfo_7 extends _i1.SmartFake
    implements _i7.ActionCodeInfo {
  _FakeActionCodeInfo_7(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeUserCredential_8 extends _i1.SmartFake
    implements _i7.UserCredential {
  _FakeUserCredential_8(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeConfirmationResult_9 extends _i1.SmartFake
    implements _i7.ConfirmationResult {
  _FakeConfirmationResult_9(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

/// A class which mocks [Client].
///
/// See the documentation for Mockito's code generation for more information.
class MockClient extends _i1.Mock implements _i2.Client {
  MockClient() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i8.Future<_i2.Response> head(Uri? url, {Map<String, String>? headers}) =>
      (super.noSuchMethod(
            Invocation.method(#head, [url], {#headers: headers}),
            returnValue: _i8.Future<_i2.Response>.value(
              _FakeResponse_0(
                this,
                Invocation.method(#head, [url], {#headers: headers}),
              ),
            ),
          )
          as _i8.Future<_i2.Response>);

  @override
  _i8.Future<_i2.Response> get(Uri? url, {Map<String, String>? headers}) =>
      (super.noSuchMethod(
            Invocation.method(#get, [url], {#headers: headers}),
            returnValue: _i8.Future<_i2.Response>.value(
              _FakeResponse_0(
                this,
                Invocation.method(#get, [url], {#headers: headers}),
              ),
            ),
          )
          as _i8.Future<_i2.Response>);

  @override
  _i8.Future<_i2.Response> post(
    Uri? url, {
    Map<String, String>? headers,
    Object? body,
    _i9.Encoding? encoding,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #post,
              [url],
              {#headers: headers, #body: body, #encoding: encoding},
            ),
            returnValue: _i8.Future<_i2.Response>.value(
              _FakeResponse_0(
                this,
                Invocation.method(
                  #post,
                  [url],
                  {#headers: headers, #body: body, #encoding: encoding},
                ),
              ),
            ),
          )
          as _i8.Future<_i2.Response>);

  @override
  _i8.Future<_i2.Response> put(
    Uri? url, {
    Map<String, String>? headers,
    Object? body,
    _i9.Encoding? encoding,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #put,
              [url],
              {#headers: headers, #body: body, #encoding: encoding},
            ),
            returnValue: _i8.Future<_i2.Response>.value(
              _FakeResponse_0(
                this,
                Invocation.method(
                  #put,
                  [url],
                  {#headers: headers, #body: body, #encoding: encoding},
                ),
              ),
            ),
          )
          as _i8.Future<_i2.Response>);

  @override
  _i8.Future<_i2.Response> patch(
    Uri? url, {
    Map<String, String>? headers,
    Object? body,
    _i9.Encoding? encoding,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #patch,
              [url],
              {#headers: headers, #body: body, #encoding: encoding},
            ),
            returnValue: _i8.Future<_i2.Response>.value(
              _FakeResponse_0(
                this,
                Invocation.method(
                  #patch,
                  [url],
                  {#headers: headers, #body: body, #encoding: encoding},
                ),
              ),
            ),
          )
          as _i8.Future<_i2.Response>);

  @override
  _i8.Future<_i2.Response> delete(
    Uri? url, {
    Map<String, String>? headers,
    Object? body,
    _i9.Encoding? encoding,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #delete,
              [url],
              {#headers: headers, #body: body, #encoding: encoding},
            ),
            returnValue: _i8.Future<_i2.Response>.value(
              _FakeResponse_0(
                this,
                Invocation.method(
                  #delete,
                  [url],
                  {#headers: headers, #body: body, #encoding: encoding},
                ),
              ),
            ),
          )
          as _i8.Future<_i2.Response>);

  @override
  _i8.Future<String> read(Uri? url, {Map<String, String>? headers}) =>
      (super.noSuchMethod(
            Invocation.method(#read, [url], {#headers: headers}),
            returnValue: _i8.Future<String>.value(
              _i10.dummyValue<String>(
                this,
                Invocation.method(#read, [url], {#headers: headers}),
              ),
            ),
          )
          as _i8.Future<String>);

  @override
  _i8.Future<_i11.Uint8List> readBytes(
    Uri? url, {
    Map<String, String>? headers,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#readBytes, [url], {#headers: headers}),
            returnValue: _i8.Future<_i11.Uint8List>.value(_i11.Uint8List(0)),
          )
          as _i8.Future<_i11.Uint8List>);

  @override
  _i8.Future<_i2.StreamedResponse> send(_i2.BaseRequest? request) =>
      (super.noSuchMethod(
            Invocation.method(#send, [request]),
            returnValue: _i8.Future<_i2.StreamedResponse>.value(
              _FakeStreamedResponse_1(
                this,
                Invocation.method(#send, [request]),
              ),
            ),
          )
          as _i8.Future<_i2.StreamedResponse>);

  @override
  void close() => super.noSuchMethod(
    Invocation.method(#close, []),
    returnValueForMissingStub: null,
  );
}

/// A class which mocks [CocoonService].
///
/// See the documentation for Mockito's code generation for more information.
class MockCocoonService extends _i1.Mock implements _i3.CocoonService {
  MockCocoonService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i8.Future<_i3.CocoonResponse<List<_i12.CommitStatus>>> fetchCommitStatuses({
    _i12.CommitStatus? lastCommitStatus,
    String? branch,
    required String? repo,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#fetchCommitStatuses, [], {
              #lastCommitStatus: lastCommitStatus,
              #branch: branch,
              #repo: repo,
            }),
            returnValue:
                _i8.Future<_i3.CocoonResponse<List<_i12.CommitStatus>>>.value(
                  _FakeCocoonResponse_2<List<_i12.CommitStatus>>(
                    this,
                    Invocation.method(#fetchCommitStatuses, [], {
                      #lastCommitStatus: lastCommitStatus,
                      #branch: branch,
                      #repo: repo,
                    }),
                  ),
                ),
          )
          as _i8.Future<_i3.CocoonResponse<List<_i12.CommitStatus>>>);

  @override
  _i8.Future<_i3.CocoonResponse<_i12.BuildStatusResponse>>
  fetchTreeBuildStatus({String? branch, required String? repo}) =>
      (super.noSuchMethod(
            Invocation.method(#fetchTreeBuildStatus, [], {
              #branch: branch,
              #repo: repo,
            }),
            returnValue:
                _i8.Future<_i3.CocoonResponse<_i12.BuildStatusResponse>>.value(
                  _FakeCocoonResponse_2<_i12.BuildStatusResponse>(
                    this,
                    Invocation.method(#fetchTreeBuildStatus, [], {
                      #branch: branch,
                      #repo: repo,
                    }),
                  ),
                ),
          )
          as _i8.Future<_i3.CocoonResponse<_i12.BuildStatusResponse>>);

  @override
  _i8.Future<_i3.CocoonResponse<List<_i12.Branch>>> fetchFlutterBranches() =>
      (super.noSuchMethod(
            Invocation.method(#fetchFlutterBranches, []),
            returnValue:
                _i8.Future<_i3.CocoonResponse<List<_i12.Branch>>>.value(
                  _FakeCocoonResponse_2<List<_i12.Branch>>(
                    this,
                    Invocation.method(#fetchFlutterBranches, []),
                  ),
                ),
          )
          as _i8.Future<_i3.CocoonResponse<List<_i12.Branch>>>);

  @override
  _i8.Future<_i3.CocoonResponse<List<String>>> fetchRepos() =>
      (super.noSuchMethod(
            Invocation.method(#fetchRepos, []),
            returnValue: _i8.Future<_i3.CocoonResponse<List<String>>>.value(
              _FakeCocoonResponse_2<List<String>>(
                this,
                Invocation.method(#fetchRepos, []),
              ),
            ),
          )
          as _i8.Future<_i3.CocoonResponse<List<String>>>);

  @override
  _i8.Future<_i3.CocoonResponse<bool>> rerunTask({
    required String? idToken,
    required String? taskName,
    required String? commitSha,
    required String? repo,
    required String? branch,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#rerunTask, [], {
              #idToken: idToken,
              #taskName: taskName,
              #commitSha: commitSha,
              #repo: repo,
              #branch: branch,
            }),
            returnValue: _i8.Future<_i3.CocoonResponse<bool>>.value(
              _FakeCocoonResponse_2<bool>(
                this,
                Invocation.method(#rerunTask, [], {
                  #idToken: idToken,
                  #taskName: taskName,
                  #commitSha: commitSha,
                  #repo: repo,
                  #branch: branch,
                }),
              ),
            ),
          )
          as _i8.Future<_i3.CocoonResponse<bool>>);

  @override
  _i8.Future<_i3.CocoonResponse<void>> rerunCommit({
    required String? idToken,
    required String? commitSha,
    required String? repo,
    required String? branch,
    Iterable<String>? include,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#rerunCommit, [], {
              #idToken: idToken,
              #commitSha: commitSha,
              #repo: repo,
              #branch: branch,
              #include: include,
            }),
            returnValue: _i8.Future<_i3.CocoonResponse<void>>.value(
              _FakeCocoonResponse_2<void>(
                this,
                Invocation.method(#rerunCommit, [], {
                  #idToken: idToken,
                  #commitSha: commitSha,
                  #repo: repo,
                  #branch: branch,
                  #include: include,
                }),
              ),
            ),
          )
          as _i8.Future<_i3.CocoonResponse<void>>);

  @override
  _i8.Future<_i3.CocoonResponse<bool>> vacuumGitHubCommits(String? idToken) =>
      (super.noSuchMethod(
            Invocation.method(#vacuumGitHubCommits, [idToken]),
            returnValue: _i8.Future<_i3.CocoonResponse<bool>>.value(
              _FakeCocoonResponse_2<bool>(
                this,
                Invocation.method(#vacuumGitHubCommits, [idToken]),
              ),
            ),
          )
          as _i8.Future<_i3.CocoonResponse<bool>>);
}

/// A class which mocks [BuildState].
///
/// See the documentation for Mockito's code generation for more information.
class MockBuildState extends _i1.Mock implements _i13.BuildState {
  MockBuildState() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.CocoonService get cocoonService =>
      (super.noSuchMethod(
            Invocation.getter(#cocoonService),
            returnValue: _FakeCocoonService_3(
              this,
              Invocation.getter(#cocoonService),
            ),
          )
          as _i3.CocoonService);

  @override
  _i4.FirebaseAuthService get authService =>
      (super.noSuchMethod(
            Invocation.getter(#authService),
            returnValue: _FakeFirebaseAuthService_4(
              this,
              Invocation.getter(#authService),
            ),
          )
          as _i4.FirebaseAuthService);

  @override
  set authService(_i4.FirebaseAuthService? _authService) => super.noSuchMethod(
    Invocation.setter(#authService, _authService),
    returnValueForMissingStub: null,
  );

  @override
  set refreshTimer(_i8.Timer? _refreshTimer) => super.noSuchMethod(
    Invocation.setter(#refreshTimer, _refreshTimer),
    returnValueForMissingStub: null,
  );

  @override
  List<_i12.Branch> get branches =>
      (super.noSuchMethod(
            Invocation.getter(#branches),
            returnValue: <_i12.Branch>[],
          )
          as List<_i12.Branch>);

  @override
  String get currentBranch =>
      (super.noSuchMethod(
            Invocation.getter(#currentBranch),
            returnValue: _i10.dummyValue<String>(
              this,
              Invocation.getter(#currentBranch),
            ),
          )
          as String);

  @override
  String get currentRepo =>
      (super.noSuchMethod(
            Invocation.getter(#currentRepo),
            returnValue: _i10.dummyValue<String>(
              this,
              Invocation.getter(#currentRepo),
            ),
          )
          as String);

  @override
  List<String> get repos =>
      (super.noSuchMethod(Invocation.getter(#repos), returnValue: <String>[])
          as List<String>);

  @override
  List<_i12.CommitStatus> get statuses =>
      (super.noSuchMethod(
            Invocation.getter(#statuses),
            returnValue: <_i12.CommitStatus>[],
          )
          as List<_i12.CommitStatus>);

  @override
  List<String> get failingTasks =>
      (super.noSuchMethod(
            Invocation.getter(#failingTasks),
            returnValue: <String>[],
          )
          as List<String>);

  @override
  bool get moreStatusesExist =>
      (super.noSuchMethod(
            Invocation.getter(#moreStatusesExist),
            returnValue: false,
          )
          as bool);

  @override
  _i5.Brook<String> get errors =>
      (super.noSuchMethod(
            Invocation.getter(#errors),
            returnValue: _FakeBrook_5<String>(this, Invocation.getter(#errors)),
          )
          as _i5.Brook<String>);

  @override
  bool get hasListeners =>
      (super.noSuchMethod(Invocation.getter(#hasListeners), returnValue: false)
          as bool);

  @override
  void addListener(_i14.VoidCallback? listener) => super.noSuchMethod(
    Invocation.method(#addListener, [listener]),
    returnValueForMissingStub: null,
  );

  @override
  void removeListener(_i14.VoidCallback? listener) => super.noSuchMethod(
    Invocation.method(#removeListener, [listener]),
    returnValueForMissingStub: null,
  );

  @override
  void updateCurrentRepoBranch(String? repo, String? branch) =>
      super.noSuchMethod(
        Invocation.method(#updateCurrentRepoBranch, [repo, branch]),
        returnValueForMissingStub: null,
      );

  @override
  _i8.Future<void>? fetchMoreCommitStatuses() =>
      (super.noSuchMethod(
            Invocation.method(#fetchMoreCommitStatuses, []),
            returnValueForMissingStub: _i8.Future<void>.value(),
          )
          as _i8.Future<void>?);

  @override
  _i8.Future<bool> refreshGitHubCommits() =>
      (super.noSuchMethod(
            Invocation.method(#refreshGitHubCommits, []),
            returnValue: _i8.Future<bool>.value(false),
          )
          as _i8.Future<bool>);

  @override
  _i8.Future<bool> rerunTask(_i12.Task? task, _i12.Commit? commit) =>
      (super.noSuchMethod(
            Invocation.method(#rerunTask, [task, commit]),
            returnValue: _i8.Future<bool>.value(false),
          )
          as _i8.Future<bool>);

  @override
  void dispose() => super.noSuchMethod(
    Invocation.method(#dispose, []),
    returnValueForMissingStub: null,
  );

  @override
  void notifyListeners() => super.noSuchMethod(
    Invocation.method(#notifyListeners, []),
    returnValueForMissingStub: null,
  );
}

/// A class which mocks [FirebaseAuthService].
///
/// See the documentation for Mockito's code generation for more information.
class MockFirebaseAuthService extends _i1.Mock
    implements _i4.FirebaseAuthService {
  MockFirebaseAuthService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  bool get isAuthenticated =>
      (super.noSuchMethod(
            Invocation.getter(#isAuthenticated),
            returnValue: false,
          )
          as bool);

  @override
  _i8.Future<String> get idToken =>
      (super.noSuchMethod(
            Invocation.getter(#idToken),
            returnValue: _i8.Future<String>.value(
              _i10.dummyValue<String>(this, Invocation.getter(#idToken)),
            ),
          )
          as _i8.Future<String>);

  @override
  bool get hasListeners =>
      (super.noSuchMethod(Invocation.getter(#hasListeners), returnValue: false)
          as bool);

  @override
  _i8.Future<void> signIn() =>
      (super.noSuchMethod(
            Invocation.method(#signIn, []),
            returnValue: _i8.Future<void>.value(),
            returnValueForMissingStub: _i8.Future<void>.value(),
          )
          as _i8.Future<void>);

  @override
  _i8.Future<void> signOut() =>
      (super.noSuchMethod(
            Invocation.method(#signOut, []),
            returnValue: _i8.Future<void>.value(),
            returnValueForMissingStub: _i8.Future<void>.value(),
          )
          as _i8.Future<void>);

  @override
  _i8.Future<void> clearUser() =>
      (super.noSuchMethod(
            Invocation.method(#clearUser, []),
            returnValue: _i8.Future<void>.value(),
            returnValueForMissingStub: _i8.Future<void>.value(),
          )
          as _i8.Future<void>);

  @override
  void addListener(_i14.VoidCallback? listener) => super.noSuchMethod(
    Invocation.method(#addListener, [listener]),
    returnValueForMissingStub: null,
  );

  @override
  void removeListener(_i14.VoidCallback? listener) => super.noSuchMethod(
    Invocation.method(#removeListener, [listener]),
    returnValueForMissingStub: null,
  );

  @override
  void dispose() => super.noSuchMethod(
    Invocation.method(#dispose, []),
    returnValueForMissingStub: null,
  );

  @override
  void notifyListeners() => super.noSuchMethod(
    Invocation.method(#notifyListeners, []),
    returnValueForMissingStub: null,
  );
}

/// A class which mocks [FirebaseAuth].
///
/// See the documentation for Mockito's code generation for more information.
class MockFirebaseAuth extends _i1.Mock implements _i7.FirebaseAuth {
  MockFirebaseAuth() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i6.FirebaseApp get app =>
      (super.noSuchMethod(
            Invocation.getter(#app),
            returnValue: _FakeFirebaseApp_6(this, Invocation.getter(#app)),
          )
          as _i6.FirebaseApp);

  @override
  set app(_i6.FirebaseApp? _app) => super.noSuchMethod(
    Invocation.setter(#app, _app),
    returnValueForMissingStub: null,
  );

  @override
  set tenantId(String? tenantId) => super.noSuchMethod(
    Invocation.setter(#tenantId, tenantId),
    returnValueForMissingStub: null,
  );

  @override
  set customAuthDomain(String? customAuthDomain) => super.noSuchMethod(
    Invocation.setter(#customAuthDomain, customAuthDomain),
    returnValueForMissingStub: null,
  );

  @override
  Map<dynamic, dynamic> get pluginConstants =>
      (super.noSuchMethod(
            Invocation.getter(#pluginConstants),
            returnValue: <dynamic, dynamic>{},
          )
          as Map<dynamic, dynamic>);

  @override
  _i8.Future<void> useAuthEmulator(
    String? host,
    int? port, {
    bool? automaticHostMapping = true,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #useAuthEmulator,
              [host, port],
              {#automaticHostMapping: automaticHostMapping},
            ),
            returnValue: _i8.Future<void>.value(),
            returnValueForMissingStub: _i8.Future<void>.value(),
          )
          as _i8.Future<void>);

  @override
  _i8.Future<void> applyActionCode(String? code) =>
      (super.noSuchMethod(
            Invocation.method(#applyActionCode, [code]),
            returnValue: _i8.Future<void>.value(),
            returnValueForMissingStub: _i8.Future<void>.value(),
          )
          as _i8.Future<void>);

  @override
  _i8.Future<_i7.ActionCodeInfo> checkActionCode(String? code) =>
      (super.noSuchMethod(
            Invocation.method(#checkActionCode, [code]),
            returnValue: _i8.Future<_i7.ActionCodeInfo>.value(
              _FakeActionCodeInfo_7(
                this,
                Invocation.method(#checkActionCode, [code]),
              ),
            ),
          )
          as _i8.Future<_i7.ActionCodeInfo>);

  @override
  _i8.Future<void> confirmPasswordReset({
    required String? code,
    required String? newPassword,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#confirmPasswordReset, [], {
              #code: code,
              #newPassword: newPassword,
            }),
            returnValue: _i8.Future<void>.value(),
            returnValueForMissingStub: _i8.Future<void>.value(),
          )
          as _i8.Future<void>);

  @override
  _i8.Future<_i7.UserCredential> createUserWithEmailAndPassword({
    required String? email,
    required String? password,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#createUserWithEmailAndPassword, [], {
              #email: email,
              #password: password,
            }),
            returnValue: _i8.Future<_i7.UserCredential>.value(
              _FakeUserCredential_8(
                this,
                Invocation.method(#createUserWithEmailAndPassword, [], {
                  #email: email,
                  #password: password,
                }),
              ),
            ),
          )
          as _i8.Future<_i7.UserCredential>);

  @override
  _i8.Future<List<String>> fetchSignInMethodsForEmail(String? email) =>
      (super.noSuchMethod(
            Invocation.method(#fetchSignInMethodsForEmail, [email]),
            returnValue: _i8.Future<List<String>>.value(<String>[]),
          )
          as _i8.Future<List<String>>);

  @override
  _i8.Future<_i7.UserCredential> getRedirectResult() =>
      (super.noSuchMethod(
            Invocation.method(#getRedirectResult, []),
            returnValue: _i8.Future<_i7.UserCredential>.value(
              _FakeUserCredential_8(
                this,
                Invocation.method(#getRedirectResult, []),
              ),
            ),
          )
          as _i8.Future<_i7.UserCredential>);

  @override
  bool isSignInWithEmailLink(String? emailLink) =>
      (super.noSuchMethod(
            Invocation.method(#isSignInWithEmailLink, [emailLink]),
            returnValue: false,
          )
          as bool);

  @override
  _i8.Stream<_i7.User?> authStateChanges() =>
      (super.noSuchMethod(
            Invocation.method(#authStateChanges, []),
            returnValue: _i8.Stream<_i7.User?>.empty(),
          )
          as _i8.Stream<_i7.User?>);

  @override
  _i8.Stream<_i7.User?> idTokenChanges() =>
      (super.noSuchMethod(
            Invocation.method(#idTokenChanges, []),
            returnValue: _i8.Stream<_i7.User?>.empty(),
          )
          as _i8.Stream<_i7.User?>);

  @override
  _i8.Stream<_i7.User?> userChanges() =>
      (super.noSuchMethod(
            Invocation.method(#userChanges, []),
            returnValue: _i8.Stream<_i7.User?>.empty(),
          )
          as _i8.Stream<_i7.User?>);

  @override
  _i8.Future<void> sendPasswordResetEmail({
    required String? email,
    _i7.ActionCodeSettings? actionCodeSettings,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#sendPasswordResetEmail, [], {
              #email: email,
              #actionCodeSettings: actionCodeSettings,
            }),
            returnValue: _i8.Future<void>.value(),
            returnValueForMissingStub: _i8.Future<void>.value(),
          )
          as _i8.Future<void>);

  @override
  _i8.Future<void> sendSignInLinkToEmail({
    required String? email,
    required _i7.ActionCodeSettings? actionCodeSettings,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#sendSignInLinkToEmail, [], {
              #email: email,
              #actionCodeSettings: actionCodeSettings,
            }),
            returnValue: _i8.Future<void>.value(),
            returnValueForMissingStub: _i8.Future<void>.value(),
          )
          as _i8.Future<void>);

  @override
  _i8.Future<void> setLanguageCode(String? languageCode) =>
      (super.noSuchMethod(
            Invocation.method(#setLanguageCode, [languageCode]),
            returnValue: _i8.Future<void>.value(),
            returnValueForMissingStub: _i8.Future<void>.value(),
          )
          as _i8.Future<void>);

  @override
  _i8.Future<void> setSettings({
    bool? appVerificationDisabledForTesting = false,
    String? userAccessGroup,
    String? phoneNumber,
    String? smsCode,
    bool? forceRecaptchaFlow,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#setSettings, [], {
              #appVerificationDisabledForTesting:
                  appVerificationDisabledForTesting,
              #userAccessGroup: userAccessGroup,
              #phoneNumber: phoneNumber,
              #smsCode: smsCode,
              #forceRecaptchaFlow: forceRecaptchaFlow,
            }),
            returnValue: _i8.Future<void>.value(),
            returnValueForMissingStub: _i8.Future<void>.value(),
          )
          as _i8.Future<void>);

  @override
  _i8.Future<void> setPersistence(_i7.Persistence? persistence) =>
      (super.noSuchMethod(
            Invocation.method(#setPersistence, [persistence]),
            returnValue: _i8.Future<void>.value(),
            returnValueForMissingStub: _i8.Future<void>.value(),
          )
          as _i8.Future<void>);

  @override
  _i8.Future<_i7.UserCredential> signInAnonymously() =>
      (super.noSuchMethod(
            Invocation.method(#signInAnonymously, []),
            returnValue: _i8.Future<_i7.UserCredential>.value(
              _FakeUserCredential_8(
                this,
                Invocation.method(#signInAnonymously, []),
              ),
            ),
          )
          as _i8.Future<_i7.UserCredential>);

  @override
  _i8.Future<_i7.UserCredential> signInWithCredential(
    _i7.AuthCredential? credential,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#signInWithCredential, [credential]),
            returnValue: _i8.Future<_i7.UserCredential>.value(
              _FakeUserCredential_8(
                this,
                Invocation.method(#signInWithCredential, [credential]),
              ),
            ),
          )
          as _i8.Future<_i7.UserCredential>);

  @override
  _i8.Future<_i7.UserCredential> signInWithCustomToken(String? token) =>
      (super.noSuchMethod(
            Invocation.method(#signInWithCustomToken, [token]),
            returnValue: _i8.Future<_i7.UserCredential>.value(
              _FakeUserCredential_8(
                this,
                Invocation.method(#signInWithCustomToken, [token]),
              ),
            ),
          )
          as _i8.Future<_i7.UserCredential>);

  @override
  _i8.Future<_i7.UserCredential> signInWithEmailAndPassword({
    required String? email,
    required String? password,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#signInWithEmailAndPassword, [], {
              #email: email,
              #password: password,
            }),
            returnValue: _i8.Future<_i7.UserCredential>.value(
              _FakeUserCredential_8(
                this,
                Invocation.method(#signInWithEmailAndPassword, [], {
                  #email: email,
                  #password: password,
                }),
              ),
            ),
          )
          as _i8.Future<_i7.UserCredential>);

  @override
  _i8.Future<_i7.UserCredential> signInWithEmailLink({
    required String? email,
    required String? emailLink,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#signInWithEmailLink, [], {
              #email: email,
              #emailLink: emailLink,
            }),
            returnValue: _i8.Future<_i7.UserCredential>.value(
              _FakeUserCredential_8(
                this,
                Invocation.method(#signInWithEmailLink, [], {
                  #email: email,
                  #emailLink: emailLink,
                }),
              ),
            ),
          )
          as _i8.Future<_i7.UserCredential>);

  @override
  _i8.Future<_i7.UserCredential> signInWithProvider(
    _i7.AuthProvider? provider,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#signInWithProvider, [provider]),
            returnValue: _i8.Future<_i7.UserCredential>.value(
              _FakeUserCredential_8(
                this,
                Invocation.method(#signInWithProvider, [provider]),
              ),
            ),
          )
          as _i8.Future<_i7.UserCredential>);

  @override
  _i8.Future<_i7.ConfirmationResult> signInWithPhoneNumber(
    String? phoneNumber, [
    _i7.RecaptchaVerifier? verifier,
  ]) =>
      (super.noSuchMethod(
            Invocation.method(#signInWithPhoneNumber, [phoneNumber, verifier]),
            returnValue: _i8.Future<_i7.ConfirmationResult>.value(
              _FakeConfirmationResult_9(
                this,
                Invocation.method(#signInWithPhoneNumber, [
                  phoneNumber,
                  verifier,
                ]),
              ),
            ),
          )
          as _i8.Future<_i7.ConfirmationResult>);

  @override
  _i8.Future<_i7.UserCredential> signInWithPopup(_i7.AuthProvider? provider) =>
      (super.noSuchMethod(
            Invocation.method(#signInWithPopup, [provider]),
            returnValue: _i8.Future<_i7.UserCredential>.value(
              _FakeUserCredential_8(
                this,
                Invocation.method(#signInWithPopup, [provider]),
              ),
            ),
          )
          as _i8.Future<_i7.UserCredential>);

  @override
  _i8.Future<void> signInWithRedirect(_i7.AuthProvider? provider) =>
      (super.noSuchMethod(
            Invocation.method(#signInWithRedirect, [provider]),
            returnValue: _i8.Future<void>.value(),
            returnValueForMissingStub: _i8.Future<void>.value(),
          )
          as _i8.Future<void>);

  @override
  _i8.Future<void> signOut() =>
      (super.noSuchMethod(
            Invocation.method(#signOut, []),
            returnValue: _i8.Future<void>.value(),
            returnValueForMissingStub: _i8.Future<void>.value(),
          )
          as _i8.Future<void>);

  @override
  _i8.Future<String> verifyPasswordResetCode(String? code) =>
      (super.noSuchMethod(
            Invocation.method(#verifyPasswordResetCode, [code]),
            returnValue: _i8.Future<String>.value(
              _i10.dummyValue<String>(
                this,
                Invocation.method(#verifyPasswordResetCode, [code]),
              ),
            ),
          )
          as _i8.Future<String>);

  @override
  _i8.Future<void> verifyPhoneNumber({
    String? phoneNumber,
    _i7.PhoneMultiFactorInfo? multiFactorInfo,
    required _i7.PhoneVerificationCompleted? verificationCompleted,
    required _i7.PhoneVerificationFailed? verificationFailed,
    required _i7.PhoneCodeSent? codeSent,
    required _i7.PhoneCodeAutoRetrievalTimeout? codeAutoRetrievalTimeout,
    String? autoRetrievedSmsCodeForTesting,
    Duration? timeout = const Duration(seconds: 30),
    int? forceResendingToken,
    _i7.MultiFactorSession? multiFactorSession,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#verifyPhoneNumber, [], {
              #phoneNumber: phoneNumber,
              #multiFactorInfo: multiFactorInfo,
              #verificationCompleted: verificationCompleted,
              #verificationFailed: verificationFailed,
              #codeSent: codeSent,
              #codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
              #autoRetrievedSmsCodeForTesting: autoRetrievedSmsCodeForTesting,
              #timeout: timeout,
              #forceResendingToken: forceResendingToken,
              #multiFactorSession: multiFactorSession,
            }),
            returnValue: _i8.Future<void>.value(),
            returnValueForMissingStub: _i8.Future<void>.value(),
          )
          as _i8.Future<void>);

  @override
  _i8.Future<void> revokeTokenWithAuthorizationCode(
    String? authorizationCode,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#revokeTokenWithAuthorizationCode, [
              authorizationCode,
            ]),
            returnValue: _i8.Future<void>.value(),
            returnValueForMissingStub: _i8.Future<void>.value(),
          )
          as _i8.Future<void>);
}

/// A class which mocks [UserCredential].
///
/// See the documentation for Mockito's code generation for more information.
class MockUserCredential extends _i1.Mock implements _i7.UserCredential {
  MockUserCredential() {
    _i1.throwOnMissingStub(this);
  }
}
