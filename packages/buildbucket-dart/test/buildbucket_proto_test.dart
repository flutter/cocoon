import 'package:buildbucket_proto/buildbucket_proto.dart';
import 'package:test/test.dart';

Map<String, dynamic> buildJson = {
  'builder': {'project': 'flutter', 'bucket': 'try', 'builder': 'buildabc'}
};

void main() {
  group('Build proto', () {
    test('From json and to json', () {
      Build build = Build();
      build.mergeFromProto3Json(buildJson);
      expect(build.toProto3Json(), buildJson);
    });
  });
}
