// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:cocoon/model.dart';
import 'package:http/http.dart' as http;

@Component(
  selector: 'benchmark-grid',
  template: '''
  This is a grid.
''',
  directives: const [NgIf, NgFor, NgClass]
)
class BenchmarkGrid implements OnInit {
  BenchmarkGrid(this._httpClient);

  final http.Client _httpClient;
  bool isLoading = true;

  @override
  void ngOnInit() {

  }
}
