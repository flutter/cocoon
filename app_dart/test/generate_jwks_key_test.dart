// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:test/test.dart';

import '../bin/generate_jwks_key.dart' as cli;

void main() {
  useTestLoggerPerTest();

  const defaultCryptoKeyName =
      'projects/flutter-dashboard/locations/global/keyRings/cocoon-jwks/cryptoKeys/pluggable-ci';
  const rfcPublicPem =
      '-----BEGIN PUBLIC KEY-----\n'
      'MCowBQYDK2VwAyEA11qYAYKxCrfVS/7TyWQHOg7hcvPapiMlrwIaaPcHURo=\n'
      '-----END PUBLIC KEY-----';
  const rfcExpectedKid = 'kPrK_qmxVWaYVA9wwBF6Iuo3vVzz7TxHCTwXBygrS4k';

  group('bin/generate_jwks_key.dart (Cloud KMS)', () {
    test(
      'dry-run prints gcloud kms commands without invoking gcloud',
      () async {
        final out = StringBuffer();
        final err = StringBuffer();
        var gcloudInvoked = false;

        final code = await cli.run(
          const <String>[],
          out: out,
          err: err,
          gcloudRunner: (_) async {
            gcloudInvoked = true;
            throw StateError('Should not invoke gcloud in dry-run');
          },
        );

        expect(code, 0);
        expect(gcloudInvoked, isFalse);
        expect(err.toString(), isEmpty);
        expect(out.toString(), contains('Dry-run for Cloud KMS CryptoKey'));
        expect(out.toString(), contains('--default-algorithm=ec-sign-ed25519'));
        expect(
          out.toString(),
          contains('jwksKmsKeyName: $defaultCryptoKeyName'),
        );
      },
    );

    test(
      '--create provisions missing keyring, CryptoKey, and version 1 in Cloud KMS',
      () async {
        final out = StringBuffer();
        final err = StringBuffer();
        final calls = <List<String>>[];

        final code = await cli.run(
          const <String>['--create', '--project', 'flutter-dashboard-dev'],
          out: out,
          err: err,
          retryDelay: Duration.zero,
          gcloudRunner: (List<String> args) async {
            calls.add(args);
            final cmd = args.take(4).join(' ');
            if (cmd.startsWith('kms keyrings list')) {
              return const cli.GcloudResult(
                exitCode: 0,
                stdout: '',
                stderr: '',
              );
            }
            if (cmd.startsWith('kms keyrings describe')) {
              return const cli.GcloudResult(
                exitCode: 1,
                stdout: '',
                stderr: 'ERROR: (gcloud.kms.keyrings.describe) NOT_FOUND',
              );
            }
            if (cmd.startsWith('kms keyrings create')) {
              return const cli.GcloudResult(
                exitCode: 0,
                stdout: '',
                stderr: '',
              );
            }
            if (cmd.startsWith('kms keys describe')) {
              return const cli.GcloudResult(
                exitCode: 1,
                stdout: '',
                stderr: 'ERROR: (gcloud.kms.keys.describe) NOT_FOUND',
              );
            }
            if (cmd.startsWith('kms keys create')) {
              return const cli.GcloudResult(
                exitCode: 0,
                stdout: '',
                stderr: '',
              );
            }
            if (cmd.startsWith('kms keys versions create')) {
              return const cli.GcloudResult(
                exitCode: 0,
                stdout:
                    'projects/flutter-dashboard-dev/locations/global/keyRings/cocoon-jwks/cryptoKeys/pluggable-ci/cryptoKeyVersions/1\n',
                stderr: '',
              );
            }
            if (cmd.startsWith('kms keys versions get-public-key')) {
              return const cli.GcloudResult(
                exitCode: 0,
                stdout: '$rfcPublicPem\n',
                stderr: '',
              );
            }
            fail('Unexpected gcloud invocation: $args');
          },
        );

        expect(code, 0);
        expect(err.toString(), isEmpty);
        expect(calls, hasLength(7));
        expect(
          calls[4],
          containsAll(<String>[
            '--purpose=asymmetric-signing',
            '--default-algorithm=ec-sign-ed25519',
            '--protection-level=software',
            '--skip-initial-version-creation',
          ]),
        );
        expect(calls[5].any((arg) => arg.startsWith('--algorithm')), isFalse);
        expect(
          out.toString(),
          contains('kid (RFC 7638 thumbprint): $rfcExpectedKid'),
        );
        expect(
          out.toString(),
          contains(
            'jwksKmsKeyName: projects/flutter-dashboard-dev/locations/global/keyRings/cocoon-jwks/cryptoKeys/pluggable-ci',
          ),
        );
      },
    );

    test(
      '--create skips creating existing keyring/key and retries PENDING_GENERATION',
      () async {
        final out = StringBuffer();
        final err = StringBuffer();
        final calls = <List<String>>[];
        var getPublicKeyAttempts = 0;

        final code = await cli.run(
          const <String>['--create'],
          out: out,
          err: err,
          retryDelay: Duration.zero,
          gcloudRunner: (List<String> args) async {
            calls.add(args);
            final cmd = args.take(4).join(' ');
            if (cmd.startsWith('kms keyrings list') ||
                cmd.startsWith('kms keyrings describe') ||
                cmd.startsWith('kms keys describe')) {
              return const cli.GcloudResult(
                exitCode: 0,
                stdout: 'exists\n',
                stderr: '',
              );
            }
            if (cmd.startsWith('kms keys versions create')) {
              return const cli.GcloudResult(
                exitCode: 0,
                stdout: '$defaultCryptoKeyName/cryptoKeyVersions/2\n',
                stderr: '',
              );
            }
            if (cmd.startsWith('kms keys versions get-public-key')) {
              getPublicKeyAttempts++;
              if (getPublicKeyAttempts == 1) {
                return const cli.GcloudResult(
                  exitCode: 1,
                  stdout: '',
                  stderr: 'Key version is in state PENDING_GENERATION',
                );
              }
              return const cli.GcloudResult(
                exitCode: 0,
                stdout: '$rfcPublicPem\n',
                stderr: '',
              );
            }
            fail('Unexpected gcloud invocation: $args');
          },
        );

        expect(code, 0);
        expect(err.toString(), isEmpty);
        expect(getPublicKeyAttempts, 2);
        expect(
          calls.any((args) => args.contains('create') && args[1] == 'keyrings'),
          isFalse,
        );
        expect(out.toString(), contains('cryptoKeyVersions/2'));
        expect(out.toString(), contains(rfcExpectedKid));
      },
    );

    test(
      'prints go/grants remediation hint on PERMISSION_DENIED for prod',
      () async {
        final out = StringBuffer();
        final err = StringBuffer();

        final code = await cli.run(
          const <String>['--create'],
          out: out,
          err: err,
          gcloudRunner: (_) async => const cli.GcloudResult(
            exitCode: 1,
            stdout: '',
            stderr: 'ERROR: PERMISSION_DENIED: Permission denied on resource',
          ),
        );

        expect(code, 1);
        expect(err.toString(), contains('roles/cloudkms.admin'));
        expect(err.toString(), contains('flutter-infra-gcp-writers'));
      },
    );

    test('prints API enable hint when Cloud KMS API is disabled', () async {
      final out = StringBuffer();
      final err = StringBuffer();

      final code = await cli.run(
        const <String>['--create'],
        out: out,
        err: err,
        gcloudRunner: (_) async => const cli.GcloudResult(
          exitCode: 1,
          stdout: '',
          stderr:
              'ERROR: Cloud Key Management Service (KMS) API has not been used in project before or it is disabled.',
        ),
      );

      expect(code, 1);
      expect(
        err.toString(),
        contains('gcloud services enable cloudkms.googleapis.com'),
      );
    });

    test('handles missing gcloud executable gracefully', () async {
      final out = StringBuffer();
      final err = StringBuffer();

      final code = await cli.run(
        const <String>['--create'],
        out: out,
        err: err,
        gcloudRunner: (_) async =>
            throw const ProcessException('gcloud', <String>[], 'No such file'),
      );

      expect(code, 1);
      expect(err.toString(), contains('Could not execute `gcloud`'));
    });

    test(
      'succeeds with warning when viewPublicKey is denied due to KMS separation of duties',
      () async {
        final out = StringBuffer();
        final err = StringBuffer();

        final code = await cli.run(
          const <String>['--create'],
          out: out,
          err: err,
          retryDelay: Duration.zero,
          gcloudRunner: (List<String> args) async {
            final cmd = args.take(4).join(' ');
            if (cmd.startsWith('kms keyrings list') ||
                cmd.startsWith('kms keyrings describe') ||
                cmd.startsWith('kms keys describe')) {
              return const cli.GcloudResult(
                exitCode: 0,
                stdout: 'exists\n',
                stderr: '',
              );
            }
            if (cmd.startsWith('kms keys versions create')) {
              return const cli.GcloudResult(
                exitCode: 0,
                stdout: '$defaultCryptoKeyName/cryptoKeyVersions/1\n',
                stderr: '',
              );
            }
            if (cmd.startsWith('kms keys versions get-public-key')) {
              return const cli.GcloudResult(
                exitCode: 1,
                stdout: '',
                stderr:
                    "PERMISSION_DENIED: Permission 'cloudkms.cryptoKeyVersions.viewPublicKey' denied",
              );
            }
            fail('Unexpected gcloud invocation: $args');
          },
        );

        expect(code, 0);
        expect(out.toString(), contains('cryptoKeyVersions/1'));
        expect(out.toString(), contains('roles/cloudkms.signerVerifier'));
        expect(out.toString(), contains('roles/cloudkms.viewer'));
        expect(err.toString(), contains('separation of duties'));
      },
    );

    test(
      'returns exit code 64 on invalid arguments or invalid resource IDs',
      () async {
        final err = StringBuffer();
        expect(await cli.run(const <String>['--unknown-flag'], err: err), 64);
        expect(
          await cli.run(const <String>['--keyring', '../bad'], err: err),
          64,
        );
      },
    );
  });
}
