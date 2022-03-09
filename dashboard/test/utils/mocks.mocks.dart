// Mocks generated by Mockito 5.0.15 from annotations
// in flutter_dashboard/test/utils/mocks.dart.
// Do not manually edit this file.

import 'dart:async' as _i8;
import 'dart:convert' as _i9;
import 'dart:typed_data' as _i10;
import 'dart:ui' as _i16;

import 'package:flutter_dashboard/logic/brooks.dart' as _i6;
import 'package:flutter_dashboard/model/build_status_response.pb.dart' as _i13;
import 'package:flutter_dashboard/model/commit_status.pb.dart' as _i12;
import 'package:flutter_dashboard/model/task.pb.dart' as _i14;
import 'package:flutter_dashboard/service/cocoon.dart' as _i4;
import 'package:flutter_dashboard/service/google_authentication.dart' as _i5;
import 'package:flutter_dashboard/state/build.dart' as _i15;
import 'package:google_sign_in/google_sign_in.dart' as _i17;
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart' as _i18;
import 'package:http/src/base_request.dart' as _i11;
import 'package:http/src/client.dart' as _i7;
import 'package:http/src/response.dart' as _i2;
import 'package:http/src/streamed_response.dart' as _i3;
import 'package:mockito/mockito.dart' as _i1;

// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis

class _FakeResponse_0 extends _i1.Fake implements _i2.Response {}

class _FakeStreamedResponse_1 extends _i1.Fake implements _i3.StreamedResponse {}

class _FakeCocoonResponse_2<T> extends _i1.Fake implements _i4.CocoonResponse<T> {}

class _FakeCocoonService_3 extends _i1.Fake implements _i4.CocoonService {}

class _FakeGoogleSignInService_4 extends _i1.Fake implements _i5.GoogleSignInService {}

class _FakeBrook_5<T> extends _i1.Fake implements _i6.Brook<T> {}

/// A class which mocks [Client].
///
/// See the documentation for Mockito's code generation for more information.
class MockClient extends _i1.Mock implements _i7.Client {
  MockClient() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i8.Future<_i2.Response> head(Uri? url, {Map<String, String>? headers}) =>
      (super.noSuchMethod(Invocation.method(#head, [url], {#headers: headers}),
          returnValue: Future<_i2.Response>.value(_FakeResponse_0())) as _i8.Future<_i2.Response>);
  @override
  _i8.Future<_i2.Response> get(Uri? url, {Map<String, String>? headers}) =>
      (super.noSuchMethod(Invocation.method(#get, [url], {#headers: headers}),
          returnValue: Future<_i2.Response>.value(_FakeResponse_0())) as _i8.Future<_i2.Response>);
  @override
  _i8.Future<_i2.Response> post(Uri? url, {Map<String, String>? headers, Object? body, _i9.Encoding? encoding}) =>
      (super.noSuchMethod(Invocation.method(#post, [url], {#headers: headers, #body: body, #encoding: encoding}),
          returnValue: Future<_i2.Response>.value(_FakeResponse_0())) as _i8.Future<_i2.Response>);
  @override
  _i8.Future<_i2.Response> put(Uri? url, {Map<String, String>? headers, Object? body, _i9.Encoding? encoding}) =>
      (super.noSuchMethod(Invocation.method(#put, [url], {#headers: headers, #body: body, #encoding: encoding}),
          returnValue: Future<_i2.Response>.value(_FakeResponse_0())) as _i8.Future<_i2.Response>);
  @override
  _i8.Future<_i2.Response> patch(Uri? url, {Map<String, String>? headers, Object? body, _i9.Encoding? encoding}) =>
      (super.noSuchMethod(Invocation.method(#patch, [url], {#headers: headers, #body: body, #encoding: encoding}),
          returnValue: Future<_i2.Response>.value(_FakeResponse_0())) as _i8.Future<_i2.Response>);
  @override
  _i8.Future<_i2.Response> delete(Uri? url, {Map<String, String>? headers, Object? body, _i9.Encoding? encoding}) =>
      (super.noSuchMethod(Invocation.method(#delete, [url], {#headers: headers, #body: body, #encoding: encoding}),
          returnValue: Future<_i2.Response>.value(_FakeResponse_0())) as _i8.Future<_i2.Response>);
  @override
  _i8.Future<String> read(Uri? url, {Map<String, String>? headers}) =>
      (super.noSuchMethod(Invocation.method(#read, [url], {#headers: headers}), returnValue: Future<String>.value(''))
          as _i8.Future<String>);
  @override
  _i8.Future<_i10.Uint8List> readBytes(Uri? url, {Map<String, String>? headers}) =>
      (super.noSuchMethod(Invocation.method(#readBytes, [url], {#headers: headers}),
          returnValue: Future<_i10.Uint8List>.value(_i10.Uint8List(0))) as _i8.Future<_i10.Uint8List>);
  @override
  _i8.Future<_i3.StreamedResponse> send(_i11.BaseRequest? request) => (super.noSuchMethod(
      Invocation.method(#send, [request]),
      returnValue: Future<_i3.StreamedResponse>.value(_FakeStreamedResponse_1())) as _i8.Future<_i3.StreamedResponse>);
  @override
  void close() => super.noSuchMethod(Invocation.method(#close, []), returnValueForMissingStub: null);
  @override
  String toString() => super.toString();
}

/// A class which mocks [CocoonService].
///
/// See the documentation for Mockito's code generation for more information.
class MockCocoonService extends _i1.Mock implements _i4.CocoonService {
  MockCocoonService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i8.Future<_i4.CocoonResponse<List<_i12.CommitStatus>>> fetchCommitStatuses(
          {_i12.CommitStatus? lastCommitStatus, String? branch, String? repo}) =>
      (super.noSuchMethod(
              Invocation.method(
                  #fetchCommitStatuses, [], {#lastCommitStatus: lastCommitStatus, #branch: branch, #repo: repo}),
              returnValue: Future<_i4.CocoonResponse<List<_i12.CommitStatus>>>.value(
                  _FakeCocoonResponse_2<List<_i12.CommitStatus>>()))
          as _i8.Future<_i4.CocoonResponse<List<_i12.CommitStatus>>>);
  @override
  _i8.Future<_i4.CocoonResponse<_i13.BuildStatusResponse>> fetchTreeBuildStatus({String? branch, String? repo}) =>
      (super.noSuchMethod(Invocation.method(#fetchTreeBuildStatus, [], {#branch: branch, #repo: repo}),
              returnValue: Future<_i4.CocoonResponse<_i13.BuildStatusResponse>>.value(
                  _FakeCocoonResponse_2<_i13.BuildStatusResponse>()))
          as _i8.Future<_i4.CocoonResponse<_i13.BuildStatusResponse>>);
  @override
  _i8.Future<_i4.CocoonResponse<List<String>>> fetchFlutterBranches() =>
      (super.noSuchMethod(Invocation.method(#fetchFlutterBranches, []),
              returnValue: Future<_i4.CocoonResponse<List<String>>>.value(_FakeCocoonResponse_2<List<String>>()))
          as _i8.Future<_i4.CocoonResponse<List<String>>>);
  @override
  _i8.Future<_i4.CocoonResponse<List<String>>> fetchRepos() => (super.noSuchMethod(Invocation.method(#fetchRepos, []),
          returnValue: Future<_i4.CocoonResponse<List<String>>>.value(_FakeCocoonResponse_2<List<String>>()))
      as _i8.Future<_i4.CocoonResponse<List<String>>>);
  @override
  _i8.Future<_i4.CocoonResponse<bool>> rerunTask(_i14.Task? task, String? idToken, String? repo) =>
      (super.noSuchMethod(Invocation.method(#rerunTask, [task, idToken, repo]),
              returnValue: Future<_i4.CocoonResponse<bool>>.value(_FakeCocoonResponse_2<bool>()))
          as _i8.Future<_i4.CocoonResponse<bool>>);
  @override
  _i8.Future<bool> vacuumGitHubCommits(String? idToken) =>
      (super.noSuchMethod(Invocation.method(#vacuumGitHubCommits, [idToken]), returnValue: Future<bool>.value(false))
          as _i8.Future<bool>);
  @override
  String toString() => super.toString();
}

/// A class which mocks [BuildState].
///
/// See the documentation for Mockito's code generation for more information.
class MockBuildState extends _i1.Mock implements _i15.BuildState {
  MockBuildState() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.CocoonService get cocoonService =>
      (super.noSuchMethod(Invocation.getter(#cocoonService), returnValue: _FakeCocoonService_3()) as _i4.CocoonService);
  @override
  _i5.GoogleSignInService get authService =>
      (super.noSuchMethod(Invocation.getter(#authService), returnValue: _FakeGoogleSignInService_4())
          as _i5.GoogleSignInService);
  @override
  set authService(_i5.GoogleSignInService? _authService) =>
      super.noSuchMethod(Invocation.setter(#authService, _authService), returnValueForMissingStub: null);
  @override
  set refreshTimer(_i8.Timer? _refreshTimer) =>
      super.noSuchMethod(Invocation.setter(#refreshTimer, _refreshTimer), returnValueForMissingStub: null);
  @override
  List<String> get branches =>
      (super.noSuchMethod(Invocation.getter(#branches), returnValue: <String>[]) as List<String>);
  @override
  String get currentBranch => (super.noSuchMethod(Invocation.getter(#currentBranch), returnValue: '') as String);
  @override
  String get currentRepo => (super.noSuchMethod(Invocation.getter(#currentRepo), returnValue: '') as String);
  @override
  List<String> get repos => (super.noSuchMethod(Invocation.getter(#repos), returnValue: <String>[]) as List<String>);
  @override
  List<_i12.CommitStatus> get statuses =>
      (super.noSuchMethod(Invocation.getter(#statuses), returnValue: <_i12.CommitStatus>[]) as List<_i12.CommitStatus>);
  @override
  List<String> get failingTasks =>
      (super.noSuchMethod(Invocation.getter(#failingTasks), returnValue: <String>[]) as List<String>);
  @override
  bool get moreStatusesExist => (super.noSuchMethod(Invocation.getter(#moreStatusesExist), returnValue: false) as bool);
  @override
  _i6.Brook<String> get errors =>
      (super.noSuchMethod(Invocation.getter(#errors), returnValue: _FakeBrook_5<String>()) as _i6.Brook<String>);
  @override
  bool get hasListeners => (super.noSuchMethod(Invocation.getter(#hasListeners), returnValue: false) as bool);
  @override
  void addListener(_i16.VoidCallback? listener) =>
      super.noSuchMethod(Invocation.method(#addListener, [listener]), returnValueForMissingStub: null);
  @override
  void removeListener(_i16.VoidCallback? listener) =>
      super.noSuchMethod(Invocation.method(#removeListener, [listener]), returnValueForMissingStub: null);
  @override
  void updateCurrentRepoBranch(String? repo, String? branch) =>
      super.noSuchMethod(Invocation.method(#updateCurrentRepoBranch, [repo, branch]), returnValueForMissingStub: null);
  @override
  _i8.Future<void>? fetchMoreCommitStatuses() => (super.noSuchMethod(Invocation.method(#fetchMoreCommitStatuses, []),
      returnValueForMissingStub: Future<void>.value()) as _i8.Future<void>?);
  @override
  _i8.Future<bool> refreshGitHubCommits() =>
      (super.noSuchMethod(Invocation.method(#refreshGitHubCommits, []), returnValue: Future<bool>.value(false))
          as _i8.Future<bool>);
  @override
  _i8.Future<bool> rerunTask(_i14.Task? task) =>
      (super.noSuchMethod(Invocation.method(#rerunTask, [task]), returnValue: Future<bool>.value(false))
          as _i8.Future<bool>);
  @override
  void dispose() => super.noSuchMethod(Invocation.method(#dispose, []), returnValueForMissingStub: null);
  @override
  void notifyListeners() =>
      super.noSuchMethod(Invocation.method(#notifyListeners, []), returnValueForMissingStub: null);
  @override
  String toString() => super.toString();
}

/// A class which mocks [GoogleSignIn].
///
/// See the documentation for Mockito's code generation for more information.
class MockGoogleSignIn extends _i1.Mock implements _i17.GoogleSignIn {
  MockGoogleSignIn() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i18.SignInOption get signInOption =>
      (super.noSuchMethod(Invocation.getter(#signInOption), returnValue: _i18.SignInOption.standard)
          as _i18.SignInOption);
  @override
  List<String> get scopes => (super.noSuchMethod(Invocation.getter(#scopes), returnValue: <String>[]) as List<String>);
  @override
  _i8.Stream<_i17.GoogleSignInAccount?> get onCurrentUserChanged =>
      (super.noSuchMethod(Invocation.getter(#onCurrentUserChanged),
          returnValue: Stream<_i17.GoogleSignInAccount?>.empty()) as _i8.Stream<_i17.GoogleSignInAccount?>);
  @override
  _i8.Future<_i17.GoogleSignInAccount?> signInSilently({bool? suppressErrors = true, bool? reAuthenticate = false}) =>
      (super.noSuchMethod(
          Invocation.method(#signInSilently, [], {#suppressErrors: suppressErrors, #reAuthenticate: reAuthenticate}),
          returnValue: Future<_i17.GoogleSignInAccount?>.value()) as _i8.Future<_i17.GoogleSignInAccount?>);
  @override
  _i8.Future<bool> isSignedIn() =>
      (super.noSuchMethod(Invocation.method(#isSignedIn, []), returnValue: Future<bool>.value(false))
          as _i8.Future<bool>);
  @override
  _i8.Future<_i17.GoogleSignInAccount?> signIn() =>
      (super.noSuchMethod(Invocation.method(#signIn, []), returnValue: Future<_i17.GoogleSignInAccount?>.value())
          as _i8.Future<_i17.GoogleSignInAccount?>);
  @override
  _i8.Future<_i17.GoogleSignInAccount?> signOut() =>
      (super.noSuchMethod(Invocation.method(#signOut, []), returnValue: Future<_i17.GoogleSignInAccount?>.value())
          as _i8.Future<_i17.GoogleSignInAccount?>);
  @override
  _i8.Future<_i17.GoogleSignInAccount?> disconnect() =>
      (super.noSuchMethod(Invocation.method(#disconnect, []), returnValue: Future<_i17.GoogleSignInAccount?>.value())
          as _i8.Future<_i17.GoogleSignInAccount?>);
  @override
  _i8.Future<bool> requestScopes(List<String>? scopes) =>
      (super.noSuchMethod(Invocation.method(#requestScopes, [scopes]), returnValue: Future<bool>.value(false))
          as _i8.Future<bool>);
  @override
  String toString() => super.toString();
}

/// A class which mocks [GoogleSignInService].
///
/// See the documentation for Mockito's code generation for more information.
class MockGoogleSignInService extends _i1.Mock implements _i5.GoogleSignInService {
  MockGoogleSignInService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  set user(_i17.GoogleSignInAccount? _user) =>
      super.noSuchMethod(Invocation.setter(#user, _user), returnValueForMissingStub: null);
  @override
  _i8.Future<bool> get isAuthenticated =>
      (super.noSuchMethod(Invocation.getter(#isAuthenticated), returnValue: Future<bool>.value(false))
          as _i8.Future<bool>);
  @override
  _i8.Future<String> get idToken =>
      (super.noSuchMethod(Invocation.getter(#idToken), returnValue: Future<String>.value('')) as _i8.Future<String>);
  @override
  bool get hasListeners => (super.noSuchMethod(Invocation.getter(#hasListeners), returnValue: false) as bool);
  @override
  _i8.Future<void> signIn() => (super.noSuchMethod(Invocation.method(#signIn, []),
      returnValue: Future<void>.value(), returnValueForMissingStub: Future<void>.value()) as _i8.Future<void>);
  @override
  _i8.Future<void> signOut() => (super.noSuchMethod(Invocation.method(#signOut, []),
      returnValue: Future<void>.value(), returnValueForMissingStub: Future<void>.value()) as _i8.Future<void>);
  @override
  void addListener(_i16.VoidCallback? listener) =>
      super.noSuchMethod(Invocation.method(#addListener, [listener]), returnValueForMissingStub: null);
  @override
  void removeListener(_i16.VoidCallback? listener) =>
      super.noSuchMethod(Invocation.method(#removeListener, [listener]), returnValueForMissingStub: null);
  @override
  void dispose() => super.noSuchMethod(Invocation.method(#dispose, []), returnValueForMissingStub: null);
  @override
  void notifyListeners() =>
      super.noSuchMethod(Invocation.method(#notifyListeners, []), returnValueForMissingStub: null);
  @override
  String toString() => super.toString();
}
