// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_dashboard/service/cocoon.dart';
import 'package:flutter_dashboard/service/google_authentication.dart';
import 'package:flutter_dashboard/state/build.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks(
  <Type>[
    Client,
    CocoonService,
    BuildState,
    GoogleSignIn,
    GoogleSignInService,
  ],
  // FOR REVIEW
  // customMocks: [MockSpec<GoogleSignInService>(as: #MockGoogleSignInService)],
  // customMock gives a type warning that I could not circumvent
  // end up putting everything in general mock
)
void main() {}
