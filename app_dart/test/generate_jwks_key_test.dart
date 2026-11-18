// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:googleapis/secretmanager/v1.dart' as gapis;
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
    '--upload creates APP_DART_JWKS_PUBLIC_<kid> and APP_DART_JWKS_PRIVATE_<kid> in Secret Manager',
    () async {
      final fakeApi = _FakeSecretManagerApi();
      final out = StringBuffer();
      final err = StringBuffer();

      final exitCode = await cli.run(
        const <String>['--upload', '--project', 'my-gcp-project'],
        out: out,
        err: err,
        keyPairFactory: () => deterministicKeyPair,
        secretManagerApiFactory: () async => fakeApi,
      );

      expect(exitCode, 0);
      expect(err.toString(), isEmpty);
      expect(out.toString(), isNot(contains('-----BEGIN PRIVATE KEY-----')));

      final kid = deterministicKeyPair.kid;
      final publicSecretId = 'APP_DART_JWKS_PUBLIC_$kid';
      final privateSecretId = 'APP_DART_JWKS_PRIVATE_$kid';

      expect(fakeApi.secretsResource.createdSecrets, <String>[
        'projects/my-gcp-project/$publicSecretId',
        'projects/my-gcp-project/$privateSecretId',
      ]);
      expect(
        fakeApi
            .secretsResource
            .addedVersions['projects/my-gcp-project/secrets/$publicSecretId'],
        deterministicKeyPair.toPublicKeyPem(),
      );
      expect(
        fakeApi
            .secretsResource
            .addedVersions['projects/my-gcp-project/secrets/$privateSecretId'],
        deterministicKeyPair.toPrivateKeyPem(),
      );
    },
  );

  test(
    '--upload adds new secret version when secret container already exists (409)',
    () async {
      final kid = deterministicKeyPair.kid;
      final fakeApi = _FakeSecretManagerApi(
        existingSecretIds: <String>{
          'APP_DART_JWKS_PUBLIC_$kid',
          'APP_DART_JWKS_PRIVATE_$kid',
        },
      );
      final out = StringBuffer();
      final err = StringBuffer();

      final exitCode = await cli.run(
        const <String>['--upload', '--project', 'my-gcp-project'],
        out: out,
        err: err,
        keyPairFactory: () => deterministicKeyPair,
        secretManagerApiFactory: () async => fakeApi,
      );

      expect(exitCode, 0);
      expect(err.toString(), isEmpty);
      expect(out.toString(), contains('already exists; adding new version'));
      expect(fakeApi.secretsResource.addedVersions, hasLength(2));
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

final class _FakeSecretManagerApi implements gapis.SecretManagerApi {
  _FakeSecretManagerApi({Set<String>? existingSecretIds})
    : secretsResource = _FakeProjectsSecretsResource(
        existingSecretIds ?? const <String>{},
      );

  final _FakeProjectsSecretsResource secretsResource;

  @override
  late final gapis.ProjectsResource projects = _FakeProjectsResource(
    secretsResource,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeProjectsResource implements gapis.ProjectsResource {
  const _FakeProjectsResource(this.secrets);

  @override
  final gapis.ProjectsSecretsResource secrets;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeProjectsSecretsResource
    implements gapis.ProjectsSecretsResource {
  _FakeProjectsSecretsResource(this._existingSecretIds);

  final Set<String> _existingSecretIds;
  final List<String> createdSecrets = <String>[];
  final Map<String, String> addedVersions = <String, String>{};

  @override
  Future<gapis.Secret> create(
    gapis.Secret request,
    String parent, {
    String? secretId,
    String? $fields,
  }) async {
    expect(request.replication?.automatic, isNotNull);
    if (_existingSecretIds.contains(secretId)) {
      throw gapis.DetailedApiRequestError(409, 'Secret already exists');
    }
    createdSecrets.add('$parent/$secretId');
    return gapis.Secret(name: '$parent/secrets/$secretId');
  }

  @override
  Future<gapis.SecretVersion> addVersion(
    gapis.AddSecretVersionRequest request,
    String parent, {
    String? $fields,
  }) async {
    final pem = utf8.decode(request.payload!.dataAsBytes);
    addedVersions[parent] = pem;
    return gapis.SecretVersion(name: '$parent/versions/1');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
