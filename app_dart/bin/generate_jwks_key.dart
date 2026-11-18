// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

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

/// Signature for invoking `gcloud` commands, optionally piping [stdinBytes].
typedef GcloudRunner =
    Future<GcloudResult> Function(
      List<String> arguments, {
      List<int>? stdinBytes,
    });

Future<void> main(List<String> args) async {
  final exitCodeValue = await run(args);
  if (exitCodeValue != 0) {
    exit(exitCodeValue);
  }
}

/// Runs the JWKS Ed25519 key generation CLI and returns an exit code.
Future<int> run(
  List<String> args, {
  StringSink? out,
  StringSink? err,
  @visibleForTesting GcloudRunner gcloudRunner = defaultGcloudRunner,
  @visibleForTesting Ed25519KeyPair Function()? keyPairFactory,
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
Generates an Ed25519 key pair (PKCS#8 private key PEM & SPKI public key PEM)
with an RFC 7638 JWK Thumbprint Key ID (kid) for Cocoon Pluggable CI JWKS.

Secret Manager naming convention:
  Private key: APP_DART_JWKS_PRIVATE_<kid>
  Public key:  APP_DART_JWKS_PUBLIC_<kid>

Examples:
  # Preview generated key pair and JWK locally (dry-run):
  dart run app_dart/bin/generate_jwks_key.dart

  # Generate and upload directly to GCP Secret Manager (flutter-dashboard):
  dart run app_dart/bin/generate_jwks_key.dart --upload

  # Generate and upload to the dev project (flutter-dashboard-dev):
  dart run app_dart/bin/generate_jwks_key.dart --upload --project flutter-dashboard-dev

  # Generate and save PEM files locally:
  dart run app_dart/bin/generate_jwks_key.dart --output-dir /tmp/cocoon-jwks

Options:
${parser.usage}''');
    return 0;
  }

  final upload = parsedArgs['upload'] as bool;
  final projectId = parsedArgs['project'] as String;
  final outputDir = parsedArgs['output-dir'] as String?;
  final printPrivateKey = parsedArgs['print-private-key'] as bool;

  // Verify GCP connectivity and authentication BEFORE generating keys.
  // Uses `gcloud` CLI so Google corp BeyondCorp / ECP mTLS credentials work natively.
  if (upload) {
    stdoutSink.writeln(
      'Connecting to GCP Secret Manager (project: $projectId)...',
    );
    try {
      await verifyGcpConnection(gcloudRunner, projectId: projectId);
    } on GcloudCommandException catch (e) {
      stderrSink.writeln(
        'Failed to connect to GCP Secret Manager (project: $projectId): '
        '${e.message}',
      );
      _writeRemediationHint(stderrSink, e.message, projectId: projectId);
      return 1;
    }
  }

  final keyPair = (keyPairFactory ?? Ed25519KeyPair.generate)();
  final kid = keyPair.kid;
  final privateSecretName = Config.jwksPrivateKeySecretName(kid);
  final publicSecretName = Config.jwksPublicKeySecretName(kid);
  final privatePem = keyPair.toPrivateKeyPem();
  final publicPem = keyPair.toPublicKeyPem();
  final publicJwkJson = const JsonEncoder.withIndent(
    '  ',
  ).convert(keyPair.publicJwk.toJson());

  if (upload) {
    stdoutSink.writeln(
      'Uploading secrets to GCP Secret Manager (project: $projectId)...',
    );
    try {
      await uploadKeyPairToSecretManager(
        gcloudRunner,
        projectId: projectId,
        keyPair: keyPair,
        out: stdoutSink,
      );
    } on GcloudCommandException catch (e) {
      stderrSink.writeln(
        'Failed to upload secrets to Secret Manager: ${e.message}',
      );
      _writeRemediationHint(stderrSink, e.message, projectId: projectId);
      return 1;
    }
    stdoutSink.writeln('');
  }

  stdoutSink.writeln('Generated Ed25519 key pair:');
  stdoutSink.writeln('  kid (RFC 7638 thumbprint): $kid');
  stdoutSink.writeln('  Private secret name:       $privateSecretName');
  stdoutSink.writeln('  Public secret name:        $publicSecretName');
  stdoutSink.writeln('');
  stdoutSink.writeln('Public JWK (served by GET /api/v1/jwks):');
  stdoutSink.writeln(publicJwkJson);

  if (outputDir != null && outputDir.isNotEmpty) {
    final directory = Directory(outputDir);
    await directory.create(recursive: true);
    final privateFile = File(p.join(directory.path, '$privateSecretName.pem'));
    final publicFile = File(p.join(directory.path, '$publicSecretName.pem'));
    await privateFile.writeAsString('$privatePem\n');
    if (!Platform.isWindows) {
      await Process.run('chmod', <String>['600', privateFile.path]);
    }
    await publicFile.writeAsString('$publicPem\n');
    stdoutSink.writeln('');
    stdoutSink.writeln('Wrote PEM files:');
    stdoutSink.writeln('  Private key: ${privateFile.path}');
    stdoutSink.writeln('  Public key:  ${publicFile.path}');
  }

  final shouldPrintPems = (!upload && outputDir == null) || printPrivateKey;
  if (shouldPrintPems) {
    stdoutSink.writeln('');
    stdoutSink.writeln('$publicSecretName:');
    stdoutSink.writeln(publicPem);
    stdoutSink.writeln('');
    stdoutSink.writeln('$privateSecretName:');
    stdoutSink.writeln(privatePem);
  }

  stdoutSink.writeln('');
  stdoutSink.writeln('Next step (app_dart/config.yaml):');
  stdoutSink.writeln('  jwksPublicKids:');
  stdoutSink.writeln('    - $kid');
  if (!upload) {
    stdoutSink.writeln('');
    stdoutSink.writeln(
      'Tip: Re-run with `--upload --project $projectId` to store a newly '
      'generated key pair directly in GCP Secret Manager.',
    );
  }
  return 0;
}

void _writeRemediationHint(
  StringSink stderrSink,
  String errorMessage, {
  required String projectId,
}) {
  if (errorMessage.contains('IAM_PERMISSION_DENIED') ||
      errorMessage.contains('does not have permission')) {
    stderrSink.writeln(
      'Your account lacks Secret Manager write permissions (`roles/secretmanager.admin`) '
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
  stderrSink.writeln(
    'Please run `gcloud auth login` to authenticate and try again.',
  );
}

/// Verifies connectivity and authentication against GCP Secret Manager for [projectId].
@visibleForTesting
Future<void> verifyGcpConnection(
  GcloudRunner gcloudRunner, {
  required String projectId,
}) async {
  final GcloudResult result;
  try {
    result = await gcloudRunner(<String>[
      'secrets',
      'list',
      '--project=$projectId',
      '--limit=1',
      '--format=value(name)',
      '--quiet',
    ]);
  } on ProcessException catch (e) {
    throw GcloudCommandException(
      'Could not execute `gcloud` (${e.message}). Ensure Google Cloud SDK is installed and on PATH.',
    );
  }
  if (result.exitCode != 0) {
    final details = result.stderr.trim();
    throw GcloudCommandException(
      details.isNotEmpty
          ? details
          : '`gcloud secrets list` exited with code ${result.exitCode}.',
    );
  }
}

/// Uploads [keyPair]'s public and private PEM secrets to Google Cloud Secret Manager
/// via `gcloud secrets` (supporting BeyondCorp / ECP device-bound mTLS credentials).
@visibleForTesting
Future<void> uploadKeyPairToSecretManager(
  GcloudRunner gcloudRunner, {
  required String projectId,
  required Ed25519KeyPair keyPair,
  StringSink? out,
}) async {
  final kid = keyPair.kid;
  await _createOrAddSecretVersion(
    gcloudRunner,
    projectId: projectId,
    secretId: Config.jwksPublicKeySecretName(kid),
    pemValue: keyPair.toPublicKeyPem(),
    out: out,
  );
  await _createOrAddSecretVersion(
    gcloudRunner,
    projectId: projectId,
    secretId: Config.jwksPrivateKeySecretName(kid),
    pemValue: keyPair.toPrivateKeyPem(),
    out: out,
  );
}

Future<void> _createOrAddSecretVersion(
  GcloudRunner gcloudRunner, {
  required String projectId,
  required String secretId,
  required String pemValue,
  StringSink? out,
}) async {
  final pemBytes = utf8.encode(pemValue);
  final secretPath = 'projects/$projectId/secrets/$secretId';

  final describeResult = await gcloudRunner(<String>[
    'secrets',
    'describe',
    secretId,
    '--project=$projectId',
    '--format=value(name)',
    '--quiet',
  ]);

  if (describeResult.exitCode != 0) {
    final createResult = await gcloudRunner(<String>[
      'secrets',
      'create',
      secretId,
      '--project=$projectId',
      '--replication-policy=automatic',
      '--data-file=-',
      '--format=value(name)',
      '--quiet',
    ], stdinBytes: pemBytes);
    if (createResult.exitCode != 0) {
      final details = createResult.stderr.trim();
      throw GcloudCommandException(
        details.isNotEmpty
            ? details
            : 'Failed to create secret $secretPath (exit code ${createResult.exitCode}).',
      );
    }
    out?.writeln('  Created secret and added version for $secretPath');
    return;
  }

  out?.writeln('  Secret $secretPath already exists; adding new version');
  final addResult = await gcloudRunner(<String>[
    'secrets',
    'versions',
    'add',
    secretId,
    '--project=$projectId',
    '--data-file=-',
    '--format=value(name)',
    '--quiet',
  ], stdinBytes: pemBytes);
  if (addResult.exitCode != 0) {
    final details = addResult.stderr.trim();
    throw GcloudCommandException(
      details.isNotEmpty
          ? details
          : 'Failed to add version for $secretPath (exit code ${addResult.exitCode}).',
    );
  }
  final versionName = addResult.stdout.trim();
  out?.writeln(
    '  Added secret version ${versionName.isNotEmpty ? versionName : secretPath}',
  );
}

/// Default [GcloudRunner] invoking the `gcloud` CLI process.
Future<GcloudResult> defaultGcloudRunner(
  List<String> arguments, {
  List<int>? stdinBytes,
}) async {
  if (stdinBytes == null) {
    final result = await Process.run('gcloud', arguments);
    return GcloudResult(
      exitCode: result.exitCode,
      stdout: '${result.stdout}',
      stderr: '${result.stderr}',
    );
  }

  final process = await Process.start('gcloud', arguments);
  final stdoutFuture = utf8.decoder.bind(process.stdout).join();
  final stderrFuture = utf8.decoder.bind(process.stderr).join();
  process.stdin.done.ignore();
  try {
    process.stdin.add(stdinBytes);
    await process.stdin.close();
  } on IOException {
    // Process exited before consuming all stdin; exitCode and stderr report why.
  }

  return GcloudResult(
    exitCode: await process.exitCode,
    stdout: await stdoutFuture,
    stderr: await stderrFuture,
  );
}

/// Exception thrown when a `gcloud` command fails.
final class GcloudCommandException implements Exception {
  const GcloudCommandException(this.message);

  final String message;

  @override
  String toString() => message;
}

ArgParser _buildArgParser() {
  return ArgParser()
    ..addFlag(
      'upload',
      abbr: 'u',
      help:
          'Upload APP_DART_JWKS_PUBLIC_<kid> and APP_DART_JWKS_PRIVATE_<kid> '
          'directly to GCP Secret Manager.',
      negatable: false,
    )
    ..addOption(
      'project',
      abbr: 'p',
      defaultsTo: Config.flutterGcpProjectId,
      help: 'GCP project ID for Secret Manager.',
    )
    ..addOption(
      'output-dir',
      abbr: 'o',
      help: 'Optional directory to write generated .pem files locally.',
    )
    ..addFlag(
      'print-private-key',
      help:
          'Print the PKCS#8 private key PEM to stdout even when --upload or '
          '--output-dir is used.',
      negatable: false,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Display usage information.',
      negatable: false,
    );
}
