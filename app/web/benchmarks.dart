// Copyright 2016 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;
import 'package:cocoon/benchmark/benchmark_grid.template.dart' as ng;

Future<Null> main() async {
  final http.Client httpClient = BrowserClient();
  runApp(ng.BenchmarkGridNgFactory, createInjector: ([Injector injector]) {
    return new Injector.map({
      http.Client: httpClient,
    }, injector);
  });
}
