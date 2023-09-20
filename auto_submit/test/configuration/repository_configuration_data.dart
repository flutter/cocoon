// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

const String sampleConfigNoOverride = '''
  default_branch: main
  allow_config_override: false
  auto_approval_accounts:
    - dependabot[bot]
    - dependabot
    - DartDevtoolWorkflowBot
  approving_reviews: 2
  approval_group: flutter-hackers
  run_ci: true
  support_no_review_revert: true
  required_checkruns_on_revert:
    - ci.yaml validation
''';

const String sampleConfigRevertReviewRequired = '''
  default_branch: main
  allow_config_override: false
  auto_approval_accounts:
    - dependabot[bot]
    - dependabot
    - DartDevtoolWorkflowBot
  approving_reviews: 2
  approval_group: flutter-hackers
  run_ci: true
  support_no_review_revert: false
  required_checkruns_on_revert:
    - ci.yaml validation
''';

const String sampleConfigWithOverride = '''
  default_branch: main
  allow_config_override: true
  auto_approval_accounts:
    - dependabot[bot]
    - dependabot
    - DartDevtoolWorkflowBot
  approving_reviews: 2
  approval_group: flutter-hackers
  run_ci: true
  support_no_review_revert: true
  required_checkruns_on_revert:
    - ci.yaml validation
''';
