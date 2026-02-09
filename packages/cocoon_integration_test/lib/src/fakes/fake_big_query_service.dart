// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_service/src/service/big_query.dart';

import 'fake_tabledata_resource.dart';

class FakeBigQueryService extends BigQueryService {
  FakeBigQueryService()
    : super.forTesting(FakeTabledataResource(), MockJobsResource());
}
