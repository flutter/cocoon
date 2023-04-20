const String sampleConfig = '''
  default_branch: main
  issues_repository:
    owner: flutter
    repo: flutter
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