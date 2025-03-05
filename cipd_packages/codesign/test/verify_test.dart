// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:codesign/verify.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'src/fake_process_manager.dart';

void main() {
  const binaryPath = '/path/to/binary';

  late FakeProcessManager processManager;
  late FileSystem fs;
  late Logger logger;
  late VerificationService service;
  late List<LogRecord> logs;

  setUp(() {
    fs = MemoryFileSystem.test();
    fs.file(binaryPath).createSync(recursive: true);
    processManager = FakeProcessManager.empty();
    logs = <LogRecord>[];
    logger = Logger.detached('test');
    logger.onRecord.listen((LogRecord record) => logs.add(record));
    service = VerificationService(
      binaryPath: binaryPath,
      fs: fs,
      logger: logger,
      pm: processManager,
    );
  });

  test('parses codesign output and can present', () async {
    processManager.addCommands(const <FakeCommand>[
      FakeCommand(
        command: <String>['codesign', '--display', '-vv', binaryPath],
        stderr: '''
Executable=$binaryPath
Identifier=mybinary
Format=Mach-O thin (x86_64)
CodeDirectory v=20500 size=38000 flags=0x10000(runtime) hashes=1177+7 location=embedded
Signature size=8979
Authority=Developer ID Application: Dev Shop ABC (ABCC0VV123)
Authority=Developer ID Certification Authority
Authority=Apple Root CA
Timestamp=Jan 9, 2023 at 9:39:07 AM
Info.plist=not bound
TeamIdentifier=ABCC0VV123
Runtime Version=13.1.0
Sealed Resources=none
Internal requirements count=1 size=164
''',
      ),
      FakeCommand(
        command: <String>[
          'codesign',
          '--verify',
          '-v',
          '-R=notarized',
          '--check-notarization',
          binaryPath,
        ],
        stderr: '''
$binaryPath: valid on disk
$binaryPath: satisfies its Designated Requirement
$binaryPath: explicit requirement satisfied
''',
      ),
    ]);
    final result = await service.run();
    expect(processManager, hasNoRemainingExpectations);
    expect(result, VerificationResult.codesignedAndNotarized);
    expect(
      service.present(),
      '''
Authority:      Developer ID Application: Dev Shop ABC (ABCC0VV123)
Time stamp:     Jan 9, 2023 at 9:39:07 AM
Format:         Mach-O thin (x86_64)
Signature size: 8979
Notarization:   true
''',
    );
  });

  test('detects codesigned but not notarized binary', () async {
    processManager.addCommands(const <FakeCommand>[
      FakeCommand(
        command: <String>['codesign', '--display', '-vv', binaryPath],
        stderr: '''
Executable=$binaryPath
Identifier=mybinary
Format=Mach-O thin (x86_64)
CodeDirectory v=20500 size=38000 flags=0x10000(runtime) hashes=1177+7 location=embedded
Signature size=8979
Authority=Developer ID Application: Dev Shop ABC (ABCC0VV123)
Authority=Developer ID Certification Authority
Authority=Apple Root CA
Timestamp=Jan 9, 2023 at 9:39:07 AM
Info.plist=not bound
TeamIdentifier=ABCC0VV123
Runtime Version=13.1.0
Sealed Resources=none
Internal requirements count=1 size=164
''',
      ),
      FakeCommand(
        command: <String>[
          'codesign',
          '--verify',
          '-v',
          '-R=notarized',
          '--check-notarization',
          binaryPath,
        ],
        stderr: '''
$binaryPath: valid on disk
$binaryPath: satisfies its Designated Requirement
test-requirement: code failed to satisfy specified code requirement(s)
''',
        exitCode: 3,
      ),
    ]);
    final result = await service.run();
    expect(processManager, hasNoRemainingExpectations);
    expect(result, VerificationResult.codesignedOnly);
    expect(
      service.present(),
      '''
Authority:      Developer ID Application: Dev Shop ABC (ABCC0VV123)
Time stamp:     Jan 9, 2023 at 9:39:07 AM
Format:         Mach-O thin (x86_64)
Signature size: 8979
Notarization:   false
''',
    );
  });

  test('detects unsigned binary', () async {
    processManager.addCommands(const <FakeCommand>[
      FakeCommand(
        command: <String>['codesign', '--display', '-vv', binaryPath],
        stderr: '$binaryPath: code object is not signed at all',
        exitCode: 1,
      ),
    ]);
    final result = await service.run();
    expect(processManager, hasNoRemainingExpectations);
    expect(result, VerificationResult.unsigned);
    expect(
      logs.first,
      isA<LogRecord>().having(
        (LogRecord record) => record.message,
        'message',
        contains('File $binaryPath is not codesigned.'),
      ),
    );
  });
}
