// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../bin/generate_jwks_key.dart' as cli;

void main() {
  useTestLoggerPerTest();

  late Ed25519KeyPair deterministicKeyPair;

  setUp(() {
    deterministicKeyPair = Ed25519KeyPair.generate(Random(99));
  });

  test('dry-run prints kid, secret names, JWK JSON, and PEM blocks', () async {
    final out = StringBuffer();
    final err = StringBuffer();

    final exitCode = await cli.run(
      const <String>[],
      out: out,
      err: err,
      keyPairFactory: () => deterministicKeyPair,
    );

    expect(exitCode, 0);
    expect(err.toString(), isEmpty);

    final output = out.toString();
    final kid = deterministicKeyPair.kid;
    expect(output, contains('kid (RFC 7638 thumbprint): $kid'));
    expect(output, contains('APP_DART_JWKS_PRIVATE_$kid'));
    expect(output, contains('APP_DART_JWKS_PUBLIC_$kid'));
    expect(output, contains('-----BEGIN PUBLIC KEY-----'));
    expect(output, contains('-----BEGIN PRIVATE KEY-----'));
    expect(output, contains('- $kid'));
  });

  test(
    '--output-dir writes PEM files and omits private key from stdout',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'cocoon_jwks_test_',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final out = StringBuffer();
      final err = StringBuffer();
      final exitCode = await cli.run(
        <String>['--output-dir', tempDir.path],
        out: out,
        err: err,
        keyPairFactory: () => deterministicKeyPair,
      );

      expect(exitCode, 0);
      expect(err.toString(), isEmpty);
      expect(out.toString(), isNot(contains('-----BEGIN PRIVATE KEY-----')));

      final kid = deterministicKeyPair.kid;
      final privateFile = File(
        p.join(tempDir.path, 'APP_DART_JWKS_PRIVATE_$kid.pem'),
      );
      final publicFile = File(
        p.join(tempDir.path, 'APP_DART_JWKS_PUBLIC_$kid.pem'),
      );

      expect(await privateFile.exists(), isTrue);
      expect(await publicFile.exists(), isTrue);

      final loadedPrivate = Ed25519KeyPair.fromPrivateKeyPem(
        await privateFile.readAsString(),
        expectedKid: kid,
      );
      final loadedPublic = Ed25519PublicJwk.fromPublicKeyPem(
        await publicFile.readAsString(),
        expectedKid: kid,
      );
      expect(loadedPrivate.publicJwk, deterministicKeyPair.publicJwk);
      expect(loadedPublic, deterministicKeyPair.publicJwk);
    },
  );

  test(
    '--upload verifies GCP connection before generating keys and creates secrets via stdin',
    () async {
      final events = <String>[];
      final uploadedPayloads = <String, String>{};
      final out = StringBuffer();
      final err = StringBuffer();

      final exitCode = await cli.run(
        const <String>['--upload', '--project', 'my-gcp-project'],
        out: out,
        err: err,
        keyPairFactory: () {
          events.add('generate_key');
          return deterministicKeyPair;
        },
        gcloudRunner: (args, {stdinBytes}) async {
          if (args.length >= 2 && args[0] == 'secrets' && args[1] == 'list') {
            events.add('list:${args.join(' ')}');
            return const cli.GcloudResult(exitCode: 0, stdout: '', stderr: '');
          }
          if (args.length >= 3 &&
              args[0] == 'secrets' &&
              args[1] == 'describe') {
            events.add('describe:${args[2]}');
            return const cli.GcloudResult(
              exitCode: 1,
              stdout: '',
              stderr: 'NOT_FOUND',
            );
          }
          if (args.length >= 3 && args[0] == 'secrets' && args[1] == 'create') {
            final secretId = args[2];
            events.add('create:$secretId');
            expect(args, contains('--project=my-gcp-project'));
            expect(args, contains('--replication-policy=automatic'));
            expect(args, contains('--data-file=-'));
            uploadedPayloads[secretId] = utf8.decode(stdinBytes!);
            return cli.GcloudResult(
              exitCode: 0,
              stdout: 'projects/my-gcp-project/secrets/$secretId\n',
              stderr: '',
            );
          }
          fail('Unexpected gcloud args: $args');
        },
      );

      expect(exitCode, 0);
      expect(err.toString(), isEmpty);
      expect(out.toString(), isNot(contains('-----BEGIN PRIVATE KEY-----')));

      final kid = deterministicKeyPair.kid;
      final publicSecretId = 'APP_DART_JWKS_PUBLIC_$kid';
      final privateSecretId = 'APP_DART_JWKS_PRIVATE_$kid';

      // Verify GCP connection check happened strictly BEFORE key generation.
      expect(events, <String>[
        'list:secrets list --project=my-gcp-project --limit=1 --format=value(name) --quiet',
        'generate_key',
        'describe:$publicSecretId',
        'create:$publicSecretId',
        'describe:$privateSecretId',
        'create:$privateSecretId',
      ]);
      expect(
        uploadedPayloads[publicSecretId],
        deterministicKeyPair.toPublicKeyPem(),
      );
      expect(
        uploadedPayloads[privateSecretId],
        deterministicKeyPair.toPrivateKeyPem(),
      );
    },
  );

  test(
    '--upload adds new secret version when secret container already exists',
    () async {
      final addedVersions = <String, String>{};
      final out = StringBuffer();
      final err = StringBuffer();

      final exitCode = await cli.run(
        const <String>['--upload', '--project', 'my-gcp-project'],
        out: out,
        err: err,
        keyPairFactory: () => deterministicKeyPair,
        gcloudRunner: (args, {stdinBytes}) async {
          if (args[1] == 'list' || args[1] == 'describe') {
            return const cli.GcloudResult(
              exitCode: 0,
              stdout: 'projects/my-gcp-project/secrets/existing\n',
              stderr: '',
            );
          }
          if (args[1] == 'versions' && args[2] == 'add') {
            final secretId = args[3];
            expect(args, contains('--data-file=-'));
            addedVersions[secretId] = utf8.decode(stdinBytes!);
            return cli.GcloudResult(
              exitCode: 0,
              stdout: 'projects/my-gcp-project/secrets/$secretId/versions/2\n',
              stderr: '',
            );
          }
          fail('Unexpected gcloud args: $args');
        },
      );

      expect(exitCode, 0);
      expect(err.toString(), isEmpty);
      expect(out.toString(), contains('already exists; adding new version'));
      expect(addedVersions, hasLength(2));
    },
  );

  test(
    '--upload does not generate keys and notifies user to run `gcloud auth login` when GCP connection fails',
    () async {
      var keyGenerated = false;
      final out = StringBuffer();
      final err = StringBuffer();

      final exitCode = await cli.run(
        const <String>['--upload', '--project', 'my-gcp-project'],
        out: out,
        err: err,
        keyPairFactory: () {
          keyGenerated = true;
          return deterministicKeyPair;
        },
        gcloudRunner: (args, {stdinBytes}) async {
          return const cli.GcloudResult(
            exitCode: 1,
            stdout: '',
            stderr:
                'ERROR: (gcloud.secrets.list) You do not currently have an active account selected.',
          );
        },
      );

      expect(exitCode, 1);
      expect(keyGenerated, isFalse);
      expect(out.toString(), isNot(contains('Generated Ed25519 key pair')));
      expect(
        err.toString(),
        allOf(
          contains('Failed to connect to GCP Secret Manager'),
          contains('gcloud auth login'),
        ),
      );
    },
  );

  test(
    '--upload does not generate keys and notifies user when gcloud binary is missing',
    () async {
      var keyGenerated = false;
      final out = StringBuffer();
      final err = StringBuffer();

      final exitCode = await cli.run(
        const <String>['--upload', '--project', 'my-gcp-project'],
        out: out,
        err: err,
        keyPairFactory: () {
          keyGenerated = true;
          return deterministicKeyPair;
        },
        gcloudRunner: (args, {stdinBytes}) async =>
            throw const ProcessException('gcloud', <String>[]),
      );

      expect(exitCode, 1);
      expect(keyGenerated, isFalse);
      expect(out.toString(), isNot(contains('Generated Ed25519 key pair')));
      expect(err.toString(), contains('gcloud auth login'));
    },
  );

  test(
    '--upload prints roles/secretmanager.admin and go/grants hint on IAM_PERMISSION_DENIED without printing generated keys',
    () async {
      final out = StringBuffer();
      final err = StringBuffer();

      final exitCode = await cli.run(
        const <String>['--upload'],
        out: out,
        err: err,
        keyPairFactory: () => deterministicKeyPair,
        gcloudRunner: (args, {stdinBytes}) async {
          if (args[1] == 'list') {
            return const cli.GcloudResult(exitCode: 0, stdout: '', stderr: '');
          }
          if (args[1] == 'describe') {
            return const cli.GcloudResult(
              exitCode: 1,
              stdout: '',
              stderr: 'NOT_FOUND',
            );
          }
          return const cli.GcloudResult(
            exitCode: 1,
            stdout: '',
            stderr:
                "Permission 'secretmanager.secrets.create' denied (reason: IAM_PERMISSION_DENIED)",
          );
        },
      );

      expect(exitCode, 1);
      expect(out.toString(), isNot(contains('Generated Ed25519 key pair')));
      expect(
        err.toString(),
        allOf(
          contains('roles/secretmanager.admin'),
          contains('flutter-infra-gcp-writers'),
          isNot(contains('gcloud auth login')),
        ),
      );
    },
  );

  test('--help and invalid arguments return expected exit codes', () async {
    final helpOut = StringBuffer();
    expect(await cli.run(const <String>['--help'], out: helpOut), 0);
    expect(helpOut.toString(), contains('APP_DART_JWKS_PRIVATE_<kid>'));

    final badErr = StringBuffer();
    expect(await cli.run(const <String>['--unknown-flag'], err: badErr), 64);
    expect(badErr.toString(), contains('Error parsing arguments'));
  });
}
