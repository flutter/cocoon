import 'dart:convert';

import 'package:buildbucket_proto/buildbucket_proto.dart';

void main() {
  // Create a BuildBucket build from a json string.
  Build build = Build();
  final String json = '{"builder": {"project": "flutter", "bucket": "try", "builder": "buildabc"}}';
  Map<String, dynamic> jsonObject = jsonDecode(json);
  build.mergeFromProto3Json(jsonObject);
  // Enconding the Build instance to a json object.
  print(build.toProto3Json());
}
