// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:meta/meta.dart';

/// Result of executing a `gcloud` CLI command.
@immutable
final class GcloudResult {
  const GcloudResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

/// Signature for invoking `gcloud` commands.
typedef GcloudRunner = Future<GcloudResult> Function(List<String> arguments);

Future<void> main(List<String> args) async {
  final exitCodeValue = await run(args);
  if (exitCodeValue != 0) {
    exit(exitCodeValue);
  }
}

/// Provisions or rotates an Ed25519 (`EC_SIGN_ED25519`) asymmetric signing key
/// version in Google Cloud KMS for Cocoon Pluggable CI JWKS and returns an exit code.
Future<int> run(
  List<String> args, {
  StringSink? out,
  StringSink? err,
  @visibleForTesting GcloudRunner gcloudRunner = defaultGcloudRunner,
  @visibleForTesting Duration retryDelay = const Duration(seconds: 1),
}) async {
  final stdoutSink = out ?? stdout;
  final stderrSink = err ?? stderr;

  final parser = _buildArgParser();
  final ArgResults parsedArgs;
  try {
    parsedArgs = parser.parse(args);
  } on FormatException catch (e) {
    stderrSink.writeln('Error parsing arguments: ${e.message}');
    stderrSink.writeln(parser.usage);
    return 64;
  }

  if (parsedArgs['help'] as bool) {
    stdoutSink.writeln('''
Provisions or rotates an Ed25519 (EC_SIGN_ED25519) asymmetric signing key
version in Google Cloud KMS for Cocoon Pluggable CI JWKS.

Private keys are generated and stored exclusively inside Google Cloud KMS and
never leave GCP. All ENABLED versions of the CryptoKey are served by
GET /api/v1/jwks.

Examples:
  # Preview the gcloud kms commands (dry-run):
  dart run app_dart/bin/generate_jwks_key.dart

  # Create keyring/key (if needed) and a new Ed25519 key version in prod:
  dart run app_dart/bin/generate_jwks_key.dart --create

  # Create/rotate a key version in the dev project:
  dart run app_dart/bin/generate_jwks_key.dart --create --project flutter-dashboard-dev

Options:
${parser.usage}''');
    return 0;
  }

  final create = parsedArgs['create'] as bool;
  final projectId = parsedArgs['project'] as String;
  final location = parsedArgs['location'] as String;
  final keyRing = parsedArgs['keyring'] as String;
  final cryptoKey = parsedArgs['key'] as String;

  final cryptoKeyName = Config.jwksKmsCryptoKeyName(
    projectId: projectId,
    location: location,
    keyRing: keyRing,
    cryptoKey: cryptoKey,
  );
  if (!CloudKmsService.isValidCryptoKeyName(cryptoKeyName)) {
    stderrSink.writeln(
      'Invalid Cloud KMS CryptoKey resource parameters: "$cryptoKeyName".',
    );
    return 64;
  }

  if (!create) {
    stdoutSink.writeln('Dry-run for Cloud KMS CryptoKey: $cryptoKeyName');
    stdoutSink.writeln('');
    stdoutSink.writeln('Commands that will be run with `--create`:');
    stdoutSink.writeln(
      '  1. gcloud kms keyrings create $keyRing '
      '--location=$location --project=$projectId',
    );
    stdoutSink.writeln(
      '  2. gcloud kms keys create $cryptoKey '
      '--keyring=$keyRing --location=$location --project=$projectId '
      '--purpose=asymmetric-signing --default-algorithm=ec-sign-ed25519 '
      '--protection-level=software --skip-initial-version-creation',
    );
    stdoutSink.writeln(
      '  3. gcloud kms keys versions create '
      '--key=$cryptoKey --keyring=$keyRing --location=$location '
      '--project=$projectId',
    );
    stdoutSink.writeln(
      '  4. gcloud kms keys versions get-public-key <version> '
      '--key=$cryptoKey --keyring=$keyRing --location=$location '
      '--project=$projectId',
    );
    stdoutSink.writeln('');
    stdoutSink.writeln('Next step (app_dart/config.yaml):');
    stdoutSink.writeln('  jwksKmsKeyName: $cryptoKeyName');
    stdoutSink.writeln('');
    stdoutSink.writeln(
      'Tip: Re-run with `--create --project $projectId` to create a new '
      'Ed25519 key version directly in Google Cloud KMS.',
    );
    return 0;
  }

  // Verify GCP connectivity and authentication BEFORE creating resources.
  // Uses `gcloud` CLI so Google corp BeyondCorp / ECP mTLS credentials work natively.
  stdoutSink.writeln(
    'Connecting to Google Cloud KMS (project: $projectId, location: $location)...',
  );
  try {
    await verifyGcpKmsConnection(
      gcloudRunner,
      projectId: projectId,
      location: location,
    );
  } on GcloudCommandException catch (e) {
    stderrSink.writeln(
      'Failed to connect to Google Cloud KMS (project: $projectId): ${e.message}',
    );
    _writeRemediationHint(stderrSink, e.message, projectId: projectId);
    return 1;
  }

  final String versionName;
  try {
    await ensureKeyRingExists(
      gcloudRunner,
      projectId: projectId,
      location: location,
      keyRing: keyRing,
      out: stdoutSink,
    );
    await ensureCryptoKeyExists(
      gcloudRunner,
      projectId: projectId,
      location: location,
      keyRing: keyRing,
      cryptoKey: cryptoKey,
      out: stdoutSink,
    );
    versionName = await createEd25519KeyVersion(
      gcloudRunner,
      projectId: projectId,
      location: location,
      keyRing: keyRing,
      cryptoKey: cryptoKey,
      out: stdoutSink,
    );
  } on GcloudCommandException catch (e) {
    stderrSink.writeln('Failed to provision key in Cloud KMS: ${e.message}');
    _writeRemediationHint(stderrSink, e.message, projectId: projectId);
    return 1;
  }

  String? publicPem;
  try {
    publicPem = await fetchPublicKeyPem(
      gcloudRunner,
      projectId: projectId,
      location: location,
      keyRing: keyRing,
      cryptoKey: cryptoKey,
      versionId: versionName.split('/').last,
      retryDelay: retryDelay,
    );
  } on GcloudCommandException catch (e) {
    if (e.message.contains('viewPublicKey') ||
        e.message.contains('PERMISSION_DENIED')) {
      stderrSink.writeln(
        'Warning: Created `$versionName`, but could not preview its public key '
        'because `roles/cloudkms.admin` / `roles/owner` does not include '
        '`cloudkms.cryptoKeyVersions.viewPublicKey` (Cloud KMS separation of duties).',
      );
    } else {
      stderrSink.writeln(
        'Failed to fetch public key from Cloud KMS: ${e.message}',
      );
      return 1;
    }
  }

  stdoutSink.writeln('');
  stdoutSink.writeln('Created Cloud KMS Ed25519 key version:');
  stdoutSink.writeln('  CryptoKey:                 $cryptoKeyName');
  stdoutSink.writeln('  CryptoKeyVersion:          $versionName');

  if (publicPem != null) {
    final Ed25519PublicJwk publicJwk;
    try {
      publicJwk = Ed25519PublicJwk.fromPublicKeyPem(publicPem);
    } on FormatException catch (e) {
      stderrSink.writeln(
        'Failed to parse Ed25519 public key PEM returned by Cloud KMS: ${e.message}',
      );
      return 1;
    }

    final publicJwkJson = const JsonEncoder.withIndent(
      '  ',
    ).convert(publicJwk.toJson());
    stdoutSink.writeln('  kid (RFC 7638 thumbprint): ${publicJwk.kid}');
    stdoutSink.writeln('');
    stdoutSink.writeln('Public JWK (served by GET /api/v1/jwks):');
    stdoutSink.writeln(publicJwkJson);
  }

  stdoutSink.writeln('');
  stdoutSink.writeln('Next step (app_dart/config.yaml):');
  stdoutSink.writeln('  jwksKmsKeyName: $cryptoKeyName');
  stdoutSink.writeln('');
  stdoutSink.writeln(
    'Ensure the App Engine service account (`$projectId@appspot.gserviceaccount.com`) '
    'has `roles/cloudkms.viewer` and `roles/cloudkms.signerVerifier` on `$cryptoKeyName`:',
  );
  stdoutSink.writeln(
    '  gcloud kms keys add-iam-policy-binding $cryptoKey '
    '--keyring=$keyRing --location=$location --project=$projectId '
    '--member="serviceAccount:$projectId@appspot.gserviceaccount.com" '
    '--role="roles/cloudkms.signerVerifier"',
  );
  stdoutSink.writeln(
    '  gcloud kms keys add-iam-policy-binding $cryptoKey '
    '--keyring=$keyRing --location=$location --project=$projectId '
    '--member="serviceAccount:$projectId@appspot.gserviceaccount.com" '
    '--role="roles/cloudkms.viewer"',
  );
  return 0;
}

void _writeRemediationHint(
  StringSink stderrSink,
  String errorMessage, {
  required String projectId,
}) {
  if (errorMessage.contains('PERMISSION_DENIED') ||
      errorMessage.contains('does not have permission')) {
    stderrSink.writeln(
      'Your account lacks Cloud KMS admin permissions (`roles/cloudkms.admin`) '
      'on project `$projectId`.',
    );
    if (projectId == Config.flutterGcpProjectId) {
      stderrSink.writeln(
        'For `flutter-dashboard`, request temporary write access to '
        '`flutter-infra-gcp-writers` via go/grants (or use '
        '`--project flutter-dashboard-dev` for dev).',
      );
    }
    return;
  }
  if (errorMessage.contains('API has not been used') ||
      errorMessage.contains('is disabled')) {
    stderrSink.writeln(
      'Enable the Cloud KMS API first: '
      '`gcloud services enable cloudkms.googleapis.com --project=$projectId`',
    );
    return;
  }
  if (errorMessage.contains('Reauthentication') ||
      errorMessage.contains('auth login') ||
      errorMessage.contains('UNAUTHENTICATED') ||
      errorMessage.contains('do not currently have an active account')) {
    stderrSink.writeln(
      'Please run `gcloud auth login` to authenticate and try again.',
    );
  }
}

/// Verifies connectivity and authentication against Google Cloud KMS for [projectId].
@visibleForTesting
Future<void> verifyGcpKmsConnection(
  GcloudRunner gcloudRunner, {
  required String projectId,
  required String location,
}) async {
  final result = await _runGcloud(gcloudRunner, <String>[
    'kms',
    'keyrings',
    'list',
    '--location=$location',
    '--project=$projectId',
    '--limit=1',
    '--format=value(name)',
    '--quiet',
  ]);
  if (result.exitCode != 0) {
    final details = result.stderr.trim();
    throw GcloudCommandException(
      details.isNotEmpty
          ? details
          : '`gcloud kms keyrings list` exited with code ${result.exitCode}.',
    );
  }
}

/// Creates [keyRing] in Cloud KMS if it does not already exist.
@visibleForTesting
Future<void> ensureKeyRingExists(
  GcloudRunner gcloudRunner, {
  required String projectId,
  required String location,
  required String keyRing,
  required StringSink out,
}) async {
  final describeResult = await _runGcloud(gcloudRunner, <String>[
    'kms',
    'keyrings',
    'describe',
    keyRing,
    '--location=$location',
    '--project=$projectId',
    '--format=value(name)',
    '--quiet',
  ]);
  if (describeResult.exitCode == 0) {
    out.writeln('  KeyRing `$keyRing` already exists.');
    return;
  }
  if (!_isNotFoundError(describeResult.stderr)) {
    throw GcloudCommandException(
      'Failed to check KeyRing `$keyRing`: ${describeResult.stderr.trim()}',
    );
  }

  out.writeln('  Creating KeyRing `$keyRing`...');
  final createResult = await _runGcloud(gcloudRunner, <String>[
    'kms',
    'keyrings',
    'create',
    keyRing,
    '--location=$location',
    '--project=$projectId',
    '--quiet',
  ]);
  if (createResult.exitCode != 0) {
    throw GcloudCommandException(
      'Failed to create KeyRing `$keyRing`: ${createResult.stderr.trim()}',
    );
  }
}

/// Creates asymmetric Ed25519 signing [cryptoKey] in Cloud KMS if it does not already exist.
@visibleForTesting
Future<void> ensureCryptoKeyExists(
  GcloudRunner gcloudRunner, {
  required String projectId,
  required String location,
  required String keyRing,
  required String cryptoKey,
  required StringSink out,
}) async {
  final describeResult = await _runGcloud(gcloudRunner, <String>[
    'kms',
    'keys',
    'describe',
    cryptoKey,
    '--keyring=$keyRing',
    '--location=$location',
    '--project=$projectId',
    '--format=value(name)',
    '--quiet',
  ]);
  if (describeResult.exitCode == 0) {
    out.writeln('  CryptoKey `$cryptoKey` already exists.');
    return;
  }
  if (!_isNotFoundError(describeResult.stderr)) {
    throw GcloudCommandException(
      'Failed to check CryptoKey `$cryptoKey`: ${describeResult.stderr.trim()}',
    );
  }

  out.writeln(
    '  Creating Ed25519 asymmetric signing CryptoKey `$cryptoKey`...',
  );
  final createResult = await _runGcloud(gcloudRunner, <String>[
    'kms',
    'keys',
    'create',
    cryptoKey,
    '--keyring=$keyRing',
    '--location=$location',
    '--project=$projectId',
    '--purpose=asymmetric-signing',
    '--default-algorithm=ec-sign-ed25519',
    '--protection-level=software',
    '--skip-initial-version-creation',
    '--quiet',
  ]);
  if (createResult.exitCode != 0) {
    throw GcloudCommandException(
      'Failed to create CryptoKey `$cryptoKey`: ${createResult.stderr.trim()}',
    );
  }
}

/// Creates a new `EC_SIGN_ED25519` CryptoKeyVersion and returns its full resource name.
@visibleForTesting
Future<String> createEd25519KeyVersion(
  GcloudRunner gcloudRunner, {
  required String projectId,
  required String location,
  required String keyRing,
  required String cryptoKey,
  required StringSink out,
}) async {
  out.writeln('  Creating new EC_SIGN_ED25519 CryptoKeyVersion...');
  final result = await _runGcloud(gcloudRunner, <String>[
    'kms',
    'keys',
    'versions',
    'create',
    '--key=$cryptoKey',
    '--keyring=$keyRing',
    '--location=$location',
    '--project=$projectId',
    '--format=value(name)',
    '--quiet',
  ]);
  if (result.exitCode != 0) {
    throw GcloudCommandException(
      'Failed to create CryptoKeyVersion: ${result.stderr.trim()}',
    );
  }
  final versionName = result.stdout.trim();
  if (!CloudKmsService.isValidCryptoKeyVersionName(versionName)) {
    throw GcloudCommandException(
      'Unexpected CryptoKeyVersion resource name from gcloud: "$versionName".',
    );
  }
  out.writeln('  Created version: $versionName');
  return versionName;
}

/// Fetches the SPKI public key PEM for [versionId], retrying briefly while
/// Cloud KMS finishes asynchronous key generation (`PENDING_GENERATION`).
@visibleForTesting
Future<String> fetchPublicKeyPem(
  GcloudRunner gcloudRunner, {
  required String projectId,
  required String location,
  required String keyRing,
  required String cryptoKey,
  required String versionId,
  int maxAttempts = 5,
  Duration retryDelay = const Duration(seconds: 1),
}) async {
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    final result = await _runGcloud(gcloudRunner, <String>[
      'kms',
      'keys',
      'versions',
      'get-public-key',
      versionId,
      '--key=$cryptoKey',
      '--keyring=$keyRing',
      '--location=$location',
      '--project=$projectId',
      '--quiet',
    ]);
    if (result.exitCode == 0 && result.stdout.trim().isNotEmpty) {
      return result.stdout.trim();
    }
    final isPending = result.stderr.contains('PENDING_GENERATION');
    if (!isPending) {
      throw GcloudCommandException(
        'Failed to fetch public key for version `$versionId`: '
        '${result.stderr.trim()}',
      );
    }
    if (attempt < maxAttempts) {
      await Future<void>.delayed(retryDelay);
    }
  }
  throw GcloudCommandException(
    'Timed out waiting for key version `$versionId` generation.',
  );
}

bool _isNotFoundError(String stderr) =>
    stderr.contains('NOT_FOUND') || stderr.contains('not found');

Future<GcloudResult> _runGcloud(
  GcloudRunner gcloudRunner,
  List<String> arguments,
) async {
  try {
    return await gcloudRunner(arguments);
  } on ProcessException catch (e) {
    throw GcloudCommandException(
      'Could not execute `gcloud` (${e.message}). Ensure Google Cloud SDK is installed and on PATH.',
    );
  }
}

/// Default [GcloudRunner] invoking the `gcloud` executable via [Process.run].
Future<GcloudResult> defaultGcloudRunner(List<String> arguments) async {
  final result = await Process.run('gcloud', arguments);
  return GcloudResult(
    exitCode: result.exitCode,
    stdout: '${result.stdout}',
    stderr: '${result.stderr}',
  );
}

/// Exception thrown when a `gcloud` CLI invocation fails.
final class GcloudCommandException implements Exception {
  const GcloudCommandException(this.message);

  final String message;

  @override
  String toString() => message;
}

ArgParser _buildArgParser() {
  return ArgParser()
    ..addFlag(
      'create',
      negatable: false,
      help:
          'Create the Cloud KMS keyring/key (if missing) and a new Ed25519 '
          'key version via gcloud. Without this flag, runs as a dry-run.',
    )
    ..addOption(
      'project',
      defaultsTo: Config.flutterGcpProjectId,
      help: 'GCP project ID for Cloud KMS.',
    )
    ..addOption(
      'location',
      defaultsTo: Config.jwksDefaultKmsLocation,
      help: 'Cloud KMS location (e.g., global, us-central1).',
    )
    ..addOption(
      'keyring',
      defaultsTo: Config.jwksDefaultKmsKeyRing,
      help: 'Cloud KMS key ring ID.',
    )
    ..addOption(
      'key',
      defaultsTo: Config.jwksDefaultKmsCryptoKey,
      help: 'Cloud KMS CryptoKey ID.',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show usage instructions.',
    );
}
