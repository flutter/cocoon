// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// When present on a pull request, instructs Cocoon to submit it
/// automatically as soon as all the required checks pass.
const String kAutosubmitLabel = 'autosubmit';

/// When present on a pull request, allows it to land without passing all the
/// checks, and jumps the merge queue.
const String kEmergencyLabel = 'emergency';

/// Applied by the bot when a pull request appears to be missing tests.
const String kMissingTestsLabel = 'missing-tests';

/// Applied by a tech lead to grant a test exemption to a pull request.
const String kTestExemptLabel = 'test-exempt';
