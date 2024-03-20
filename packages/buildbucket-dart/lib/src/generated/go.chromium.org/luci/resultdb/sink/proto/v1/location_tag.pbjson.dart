//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/sink/proto/v1/location_tag.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use locationTagsDescriptor instead')
const LocationTags$json = {
  '1': 'LocationTags',
  '2': [
    {'1': 'repos', '3': 1, '4': 3, '5': 11, '6': '.luci.resultsink.v1.LocationTags.ReposEntry', '10': 'repos'},
  ],
  '3': [LocationTags_Repo$json, LocationTags_Dir$json, LocationTags_File$json, LocationTags_ReposEntry$json],
};

@$core.Deprecated('Use locationTagsDescriptor instead')
const LocationTags_Repo$json = {
  '1': 'Repo',
  '2': [
    {'1': 'dirs', '3': 1, '4': 3, '5': 11, '6': '.luci.resultsink.v1.LocationTags.Repo.DirsEntry', '10': 'dirs'},
    {'1': 'files', '3': 2, '4': 3, '5': 11, '6': '.luci.resultsink.v1.LocationTags.Repo.FilesEntry', '10': 'files'},
  ],
  '3': [LocationTags_Repo_DirsEntry$json, LocationTags_Repo_FilesEntry$json],
};

@$core.Deprecated('Use locationTagsDescriptor instead')
const LocationTags_Repo_DirsEntry$json = {
  '1': 'DirsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.luci.resultsink.v1.LocationTags.Dir', '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use locationTagsDescriptor instead')
const LocationTags_Repo_FilesEntry$json = {
  '1': 'FilesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.luci.resultsink.v1.LocationTags.File', '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use locationTagsDescriptor instead')
const LocationTags_Dir$json = {
  '1': 'Dir',
  '2': [
    {'1': 'tags', '3': 1, '4': 3, '5': 11, '6': '.luci.resultdb.v1.StringPair', '10': 'tags'},
    {'1': 'bug_component', '3': 2, '4': 1, '5': 11, '6': '.luci.resultdb.v1.BugComponent', '10': 'bugComponent'},
  ],
};

@$core.Deprecated('Use locationTagsDescriptor instead')
const LocationTags_File$json = {
  '1': 'File',
  '2': [
    {'1': 'tags', '3': 1, '4': 3, '5': 11, '6': '.luci.resultdb.v1.StringPair', '10': 'tags'},
    {'1': 'bug_component', '3': 2, '4': 1, '5': 11, '6': '.luci.resultdb.v1.BugComponent', '10': 'bugComponent'},
  ],
};

@$core.Deprecated('Use locationTagsDescriptor instead')
const LocationTags_ReposEntry$json = {
  '1': 'ReposEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.luci.resultsink.v1.LocationTags.Repo', '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `LocationTags`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List locationTagsDescriptor = $convert.base64Decode(
    'CgxMb2NhdGlvblRhZ3MSQQoFcmVwb3MYASADKAsyKy5sdWNpLnJlc3VsdHNpbmsudjEuTG9jYX'
    'Rpb25UYWdzLlJlcG9zRW50cnlSBXJlcG9zGtMCCgRSZXBvEkMKBGRpcnMYASADKAsyLy5sdWNp'
    'LnJlc3VsdHNpbmsudjEuTG9jYXRpb25UYWdzLlJlcG8uRGlyc0VudHJ5UgRkaXJzEkYKBWZpbG'
    'VzGAIgAygLMjAubHVjaS5yZXN1bHRzaW5rLnYxLkxvY2F0aW9uVGFncy5SZXBvLkZpbGVzRW50'
    'cnlSBWZpbGVzGl0KCURpcnNFbnRyeRIQCgNrZXkYASABKAlSA2tleRI6CgV2YWx1ZRgCIAEoCz'
    'IkLmx1Y2kucmVzdWx0c2luay52MS5Mb2NhdGlvblRhZ3MuRGlyUgV2YWx1ZToCOAEaXwoKRmls'
    'ZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRI7CgV2YWx1ZRgCIAEoCzIlLmx1Y2kucmVzdWx0c2'
    'luay52MS5Mb2NhdGlvblRhZ3MuRmlsZVIFdmFsdWU6AjgBGnwKA0RpchIwCgR0YWdzGAEgAygL'
    'MhwubHVjaS5yZXN1bHRkYi52MS5TdHJpbmdQYWlyUgR0YWdzEkMKDWJ1Z19jb21wb25lbnQYAi'
    'ABKAsyHi5sdWNpLnJlc3VsdGRiLnYxLkJ1Z0NvbXBvbmVudFIMYnVnQ29tcG9uZW50Gn0KBEZp'
    'bGUSMAoEdGFncxgBIAMoCzIcLmx1Y2kucmVzdWx0ZGIudjEuU3RyaW5nUGFpclIEdGFncxJDCg'
    '1idWdfY29tcG9uZW50GAIgASgLMh4ubHVjaS5yZXN1bHRkYi52MS5CdWdDb21wb25lbnRSDGJ1'
    'Z0NvbXBvbmVudBpfCgpSZXBvc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EjsKBXZhbHVlGAIgAS'
    'gLMiUubHVjaS5yZXN1bHRzaW5rLnYxLkxvY2F0aW9uVGFncy5SZXBvUgV2YWx1ZToCOAE=');

