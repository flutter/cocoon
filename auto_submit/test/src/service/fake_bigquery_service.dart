// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/service/bigquery.dart';
import 'package:googleapis/bigquery/v2.dart';

import '../../utilities/mocks.mocks.dart';

class FakeBigqueryService extends BigqueryService {
  FakeBigqueryService(this.jobsResource) : super(MockAccessClientProvider());

  JobsResource jobsResource;

  @override
  Future<JobsResource> defaultJobs() async {
    return jobsResource;
  }
}
