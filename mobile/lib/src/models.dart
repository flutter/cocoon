// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import 'entities.dart';
import 'service.dart';

class MementoRegistry {
  MementoRegistry(this._mementos) {
    for (var memento in _mementos) {
      memento.addListener(() {
        if (memento._saveToDisk) {
          _save(memento);
        }
      });
    }
  }

  final List<Memento> _mementos;

  Future<void> _save(Memento memento) async {
    var documents = await getApplicationDocumentsDirectory();
    var file = await File('${documents.path}/${memento.name}').create();
    var data = memento.toData();
    List<int> bytes;
    try {
      bytes = utf8.encode(json.encode(data));
      await null;
    } on FormatException {
      return;
    }
    await file.writeAsBytes(bytes);
  }

  Future<void> init() async {
    var documents = await getApplicationDocumentsDirectory();
    var futures = <Future<Object>>[];
    for (var memento in _mementos) {
      var file = File('${documents.path}/${memento.name}');
      if (file.existsSync())
        file.readAsBytes().then((List<int> bytes) {
          Object data;
          try {
            data = json.decode(utf8.decode(bytes));
          } on FormatException {
            return file.delete();
          }
          memento.fromData(data);
        }, onError: (Object err) {
          assert(() {
            print('WARNING: error loading ${memento.name}: $err');
            return true;
          }());
        });
    }
    return Future.wait(futures);
  }

  Future<void> clearAll() async {
    var documents = await getApplicationDocumentsDirectory();
    for (var memento in _mementos) {
      var file = File('${documents.path}/${memento.name}');
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}

mixin Memento on ChangeNotifier {
  /// Returns an encoded representation of the model.
  ///
  /// This data is persisted to disk and can be used to recreate the model
  /// from it.
  Object toData();

  /// Called when the model is restored.
  void fromData(Object data);

  /// The name of the memento.
  ///
  /// This name must be unique.
  String get name;

  bool _saveToDisk = false;

  @override
  void notifyListeners({bool saveToDisk = false}) {
    _saveToDisk = saveToDisk;
    super.notifyListeners();
    _saveToDisk = false;
  }
}

class BenchmarkModel extends ChangeNotifier with Memento {
  BenchmarkModel({
    @required this.service,
    @required this.userSettingsModel,
  });

  final ApplicationService service;
  final UserSettingsModel userSettingsModel;

  List<BenchmarkData> get benchmarks => _filteredBenchmarks ?? _benchmarks;
  List<BenchmarkData> _benchmarks;

  List<BenchmarkData> _filteredBenchmarks;

  /// Whether to additionally show archived benchmark data..
  bool get showArchived => _showArchived;
  bool _showArchived = false;
  set showArchived(bool value) {
    if (value == _showArchived) {
      return;
    }
    _showArchived = value;
    _filterBenchmarks();
    notifyListeners();
  }

  /// Whether to show only favorited benchmarks.
  bool get showFavorites => _showFavorites;
  bool _showFavorites = false;
  set showFavorites(bool value) {
    if (value == _showFavorites) {
      return;
    }
    _showFavorites = value;
    _filterBenchmarks();
    notifyListeners();
  }

  bool get showFailures => _showFailures;
  bool _showFailures = false;
  set showFailures(bool value) {
    if (value == _showFailures) {
      return;
    }
    _showFailures = value;
    _filterBenchmarks();
    notifyListeners();
  }

  String get nameQuery => _nameQuery;
  String _nameQuery;
  set nameQuery(String value) {
    if (value == _nameQuery) {
      return;
    }
    _nameQuery = value;
    _filterBenchmarks();
    notifyListeners();
  }

  /// Whether the benchmarks are loaded.
  bool get isLoaded => _benchmarks != null;

  BenchmarkData getById(String id) {
    return _benchmarks.firstWhere((BenchmarkData data) {
      return data.timeseries.timeseries.id == id;
    });
  }

  /// Request that benchmarks are loaded, if they are not already.
  Future<void> requestBenchmarks({bool force = false}) async {
    if (_benchmarks != null && !force) {
      return;
    }
    var result = await service.fetchBenchmarks();
    _benchmarks = result.benchmarks;
    _processBenchmarks();
    _filterBenchmarks();
    notifyListeners(saveToDisk: true);
  }

  void _processBenchmarks() {
    // sort by task name.
    _benchmarks
      ..sort((BenchmarkData left, BenchmarkData right) =>
          left.timeseries.timeseries.taskName.compareTo(right.timeseries.timeseries.taskName));
  }

  void _filterBenchmarks() {
    var results = <BenchmarkData>[];
    for (var benchmark in _benchmarks) {
      if (!_showArchived && benchmark.timeseries.timeseries.isArchived) {
        continue;
      }
      if (_showFavorites && !userSettingsModel.favoriteBenchmarks.contains(benchmark.timeseries.timeseries.id)) {
        continue;
      }
      if (_showFailures && benchmark.values.last.value <= benchmark.timeseries.timeseries.baseline) {
        continue;
      }
      if (nameQuery != null &&
          nameQuery.isNotEmpty &&
          (!benchmark.timeseries.timeseries.taskName.contains(nameQuery) &&
              !benchmark.timeseries.timeseries.label.contains(nameQuery))) {
        continue;
      }
      results.add(benchmark);
    }
    _filteredBenchmarks = results;
    notifyListeners();
  }

  @override
  String get name => 'benchmarks';

  @override
  Object toData() {
    return {
      'data': {'Benchmarks': _benchmarks},
      'nameQuery': nameQuery,
    };
  }

  @override
  void fromData(Object data) {
    Map<String, Object> result = data;
    _nameQuery = result['nameQuery'];
    _benchmarks = GetBenchmarksResult.fromJson(result['data']).benchmarks;
    if (_benchmarks != null) {
      _processBenchmarks();
      _filterBenchmarks();
    }
    notifyListeners();
  }
}

class UserSettingsModel extends ChangeNotifier {
  UserSettingsModel() {
    SharedPreferences.getInstance().then((SharedPreferences sharedPreferences) {
      _preferences = sharedPreferences;
      _favoriteBenchmarks = Set.of(_preferences.getStringList('favoriteBenchmarks') ?? []);
      notifyListeners();
    });
  }

  SharedPreferences _preferences;

  Set<String> get favoriteBenchmarks => _favoriteBenchmarks;
  Set<String> _favoriteBenchmarks = Set();

  /// Add the benchmark identified by [key] to the user favorites list.
  void addFavoriteBenchmark(String key) {
    _favoriteBenchmarks.add(key);
    notifyListeners();
    _preferences.setStringList('favoriteBenchmarks', _favoriteBenchmarks.toList()).then((bool result) {
      if (!result) {
        _favoriteBenchmarks.remove(key);
        notifyListeners();
      }
    });
  }

  /// Add the benchmark identified by [key] to the user favorites list.
  void removeFavoriteBenchmark(String key) {
    _favoriteBenchmarks.remove(key);
    notifyListeners();
    _preferences.setStringList('favoriteBenchmarks', _favoriteBenchmarks.toList()).then((bool result) {
      if (!result) {
        _favoriteBenchmarks.add(key);
        notifyListeners();
      }
    });
  }

  /// Whether the shared preferences have been initialized.
  bool get isLoaded => _preferences != null;
}

class BuildBrokenModel extends ChangeNotifier {
  BuildBrokenModel({@required this.service});

  final ApplicationService service;

  Future<void> requestStatus() async {
    if (_pending) {
      return;
    }
    _pending = true;
    _isBuildBroken = await service.fetchBuildBroken();
    _pending = false;
    notifyListeners();
  }

  bool get isBuildBroken => _isBuildBroken;
  bool _isBuildBroken = false;

  bool _pending = false;
}

class BuildStatusModel extends ChangeNotifier with Memento {
  BuildStatusModel({@required this.service});

  final ApplicationService service;

  Future<void> requestBuildStatus({bool force = false}) async {
    if (isLoaded && !force) {
      return;
    }
    var result = await service.fetchBuildStatus();
    _buildStatus = result;
    _agentStatuses = result.agentStatuses ?? <AgentStatus>[];
    _statuses = result.statuses ?? <BuildStatus>[];
    notifyListeners(saveToDisk: true);
  }

  bool get isLoaded => _buildStatus != null;

  int get unhealthyAgents {
    if (!isLoaded) {
      return 0;
    }
    return agentStatuses.where((status) => !status.isHealthy).length;
  }

  Future<void> resetTask(String id) async {
    return service.resetTask(id);
  }

  /// Returns the most recent commit, or null if it is not loaded.
  CommitInfo get lastCommit {
    if (!isLoaded || statuses.isEmpty) {
      return null;
    }
    return statuses.last.checklist.checklist.commit;
  }

  List<AgentStatus> get agentStatuses => _agentStatuses;
  List<AgentStatus> _agentStatuses;

  List<BuildStatus> get statuses => _statuses;
  List<BuildStatus> _statuses;

  GetStatusResult _buildStatus;

  @override
  String get name => 'build_status';

  @override
  Object toData() {
    return _buildStatus;
  }

  @override
  void fromData(Object data) {
    var result = GetStatusResult.fromJson(data);
    _buildStatus = result;
    _agentStatuses = result.agentStatuses;
    _statuses = result.statuses;
    notifyListeners();
  }
}

class ClockModel extends ChangeNotifier {
  DateTime currentTime() {
    return DateTime.now();
  }
}

class CommitModel extends ChangeNotifier with Memento {
  CommitModel({
    @required this.signInModel,
    @required this.service,
  });

  final ApplicationService service;
  final SignInModel signInModel;

  final _commits = <String, Map<String, Object>>{};

  Future<void> requestCommit(String sha) async {
    if (_commits.containsKey(sha)) {
      return;
    }
    if (!signInModel.isSignedIntoGithub) {
      return;
    }
    var saveToDisk = false;
    var result = await service.fetchCommitInfo(sha, signInModel._githubUsername, signInModel._githubToken);
    if (result != null) {
      _commits[sha] = result;
      saveToDisk = true;
    }
    notifyListeners(saveToDisk: saveToDisk);
  }

  Map<String, Object> getCommit(String sha) {
    return _commits[sha];
  }

  @override
  String get name => 'commits';

  @override
  Object toData() {
    return _commits;
  }

  @override
  void fromData(Object data) {
    Map<String, Object> result = data;
    for (var key in result.keys) {
      if (_commits[key] == null) {
        _commits[key] = result[key];
      }
    }
    notifyListeners();
  }
}

class SignInModel extends ChangeNotifier {
  SignInModel({@required this.service, this.googleSignIn}) {
    googleSignIn.signInSilently().then((account) {
      if (account != null) {
        _googleAccount = account;
      }
    });
  }

  final ApplicationService service;
  final GoogleSignIn googleSignIn;
  final _storage = FlutterSecureStorage();

  GoogleSignInAccount get googleAccount => _googleAccount;
  GoogleSignInAccount _googleAccount;

  Future<void> checkGithubStatus() async {
    if (_githubToken != null && _githubUsername != null) {
      return;
    }
    _githubToken = await _storage.read(key: 'metapod-token');
    _githubUsername = await _storage.read(key: 'metapod-username');
    if (_githubToken == null || _githubToken.isEmpty || _githubUsername == null || _githubUsername.isEmpty) {
      return;
    }
    notifyListeners();
  }

  Future<void> signIntoGoogle() async {
    try {
      _googleAccount = await googleSignIn.signIn();
    } finally {
      notifyListeners();
    }
  }

  Future<void> signOutGoogle() async {
    try {
      await googleSignIn.signOut();
      _googleAccount = null;
    } finally {
      notifyListeners();
    }
  }

  Future<void> signIntoGithub(String username, String token) async {
    _githubToken = token;
    _githubUsername = username;
    await _storage.write(key: 'metapod-username', value: username);
    await _storage.write(key: 'metapod-token', value: token);
    notifyListeners();
  }

  Future<void> signOutGithub() async {
    _githubToken = null;
    _githubUsername = null;
    await _storage.delete(key: 'metapod-username');
    await _storage.delete(key: 'metapod-token');
    notifyListeners();
  }

  String get githubToken => _githubToken;
  String _githubToken;

  String get githubUsername => _githubUsername;
  String _githubUsername;

  bool get isSignedIntoCocoon => _isSignedIntoCocoon;
  bool _isSignedIntoCocoon = false;

  bool get isSignedIntoGithub => _githubToken != null && _githubUsername != null;
}
