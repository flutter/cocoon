import 'package:file/memory.dart';
import 'package:gcloud/storage.dart';
import 'package:gcs_cleaner/cleaner.dart';
import 'package:test/test.dart';

import 'src/fake_gcs.dart';
import 'src/fake_git.dart';

void main() {
  group(Cleaner, () {
    group('processEngineArtifact', () {
      const Bucket bucket = FakeBucket('fake_bucket');
      final Map<String, String> engineCommitTags = <String, String>{
        'release': '3.0.0',
      };
      final Cleaner cleaner = Cleaner(
        fs: MemoryFileSystem(),
        gcs: FakeGcs(),
        engineGit: FakeGit(),
        frameworkGit: FakeGit(),
        ttl: const Duration(days: 365),
        now: DateTime(2023, 10, 10),
      );

      <BucketEntry, String?>{
        const FakeBucketItem(name: 'random_file'): null,
        const FakeBucketItem(name: 'flutter/release'): null,
        const FakeBucketItem(name: 'flutter/old_sha'): 'old_sha',
        const FakeBucketItem(name: 'flutter/new_sha'): null,
        const FakeBucketItem(name: 'flutter/old_file', isDirectory: false): null,
      }.forEach((key, value) {
        test('${key.name} returns $value', () async {
          final got = await cleaner.processEngineArtifact(
            bucket: bucket,
            item: key,
            engineCommitTags: engineCommitTags,
          );
          expect(got, value);
        });
      });
    });
  });
}
