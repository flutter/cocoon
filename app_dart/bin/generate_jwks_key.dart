// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:googleapis/secretmanager/v1.dart' as gapis;
import 'package:googleapis_auth/auth_io.dart' as gauth;
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

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
  @visibleForTesting
  Future<gapis.SecretManagerApi> Function()? secretManagerApiFactory,
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
  dart run bin/generate_jwks_key.dart

  # Generate and upload directly to GCP Secret Manager (flutter-dashboard):
  dart run bin/generate_jwks_key.dart --upload

  # Generate and save PEM files locally:
  dart run bin/generate_jwks_key.dart --output-dir /tmp/cocoon-jwks

Options:
${parser.usage}''');
    return 0;
  }

  final upload = parsedArgs['upload'] as bool;
  final projectId = parsedArgs['project'] as String;
  final outputDir = parsedArgs['output-dir'] as String?;
  final printPrivateKey = parsedArgs['print-private-key'] as bool;

  final keyPair = (keyPairFactory ?? Ed25519KeyPair.generate)();
  final kid = keyPair.kid;
  final privateSecretName = Config.jwksPrivateKeySecretName(kid);
  final publicSecretName = Config.jwksPublicKeySecretName(kid);
  final privatePem = keyPair.toPrivateKeyPem();
  final publicPem = keyPair.toPublicKeyPem();
  final publicJwkJson = const JsonEncoder.withIndent(
    '  ',
  ).convert(keyPair.publicJwk.toJson());

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

  if (upload) {
    stdoutSink.writeln('');
    stdoutSink.writeln(
      'Uploading secrets to GCP Secret Manager (project: $projectId)...',
    );
    try {
      final api = await (secretManagerApiFactory ?? _createSecretManagerApi)();
      await uploadKeyPairToSecretManager(
        api,
        projectId: projectId,
        keyPair: keyPair,
        out: stdoutSink,
      );
    } catch (e, s) {
      stderrSink.writeln('Failed to upload secrets to Secret Manager: $e');
      stderrSink.writeln(s);
      return 1;
    }
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

/// Uploads [keyPair]'s public and private PEM secrets to Google Cloud Secret Manager.
@visibleForTesting
Future<void> uploadKeyPairToSecretManager(
  gapis.SecretManagerApi api, {
  required String projectId,
  required Ed25519KeyPair keyPair,
  StringSink? out,
}) async {
  final kid = keyPair.kid;
  await _createAndAddSecretVersion(
    api,
    projectId: projectId,
    secretId: Config.jwksPublicKeySecretName(kid),
    pemValue: keyPair.toPublicKeyPem(),
    out: out,
  );
  await _createAndAddSecretVersion(
    api,
    projectId: projectId,
    secretId: Config.jwksPrivateKeySecretName(kid),
    pemValue: keyPair.toPrivateKeyPem(),
    out: out,
  );
}

Future<void> _createAndAddSecretVersion(
  gapis.SecretManagerApi api, {
  required String projectId,
  required String secretId,
  required String pemValue,
  StringSink? out,
}) async {
  final projectParent = 'projects/$projectId';
  final secretName = '$projectParent/secrets/$secretId';

  try {
    await api.projects.secrets.create(
      gapis.Secret(
        replication: gapis.Replication(automatic: gapis.Automatic()),
      ),
      projectParent,
      secretId: secretId,
    );
    out?.writeln('  Created secret $secretName');
  } on gapis.DetailedApiRequestError catch (e) {
    // HTTP 409 ALREADY_EXISTS means the secret container exists; add a new version.
    if (e.status != 409) {
      rethrow;
    }
    out?.writeln('  Secret $secretName already exists; adding new version');
  }

  final version = await api.projects.secrets.addVersion(
    gapis.AddSecretVersionRequest(
      payload: gapis.SecretPayload()..dataAsBytes = utf8.encode(pemValue),
    ),
    secretName,
  );
  out?.writeln('  Added secret version ${version.name ?? secretName}');
}

Future<gapis.SecretManagerApi> _createSecretManagerApi() async {
  const scopes = <String>[gapis.SecretManagerApi.cloudPlatformScope];
  final accessToken = Platform.environment['ACCESS_TOKEN'];
  final http.Client client;
  if (accessToken != null && accessToken.isNotEmpty) {
    client = gauth.authenticatedClient(
      http.Client(),
      gauth.AccessCredentials(
        gauth.AccessToken(
          'Bearer',
          accessToken,
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        null,
        scopes,
      ),
    );
  } else {
    client = await gauth.clientViaApplicationDefaultCredentials(scopes: scopes);
  }
  return gapis.SecretManagerApi(client);
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
