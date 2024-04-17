//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/failure_reason.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use failureReasonDescriptor instead')
const FailureReason$json = {
  '1': 'FailureReason',
  '2': [
    {'1': 'primary_error_message', '3': 1, '4': 1, '5': 9, '10': 'primaryErrorMessage'},
    {'1': 'errors', '3': 2, '4': 3, '5': 11, '6': '.luci.resultdb.v1.FailureReason.Error', '10': 'errors'},
    {'1': 'truncated_errors_count', '3': 3, '4': 1, '5': 5, '10': 'truncatedErrorsCount'},
  ],
  '3': [FailureReason_Error$json],
};

@$core.Deprecated('Use failureReasonDescriptor instead')
const FailureReason_Error$json = {
  '1': 'Error',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `FailureReason`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List failureReasonDescriptor =
    $convert.base64Decode('Cg1GYWlsdXJlUmVhc29uEjIKFXByaW1hcnlfZXJyb3JfbWVzc2FnZRgBIAEoCVITcHJpbWFyeU'
        'Vycm9yTWVzc2FnZRI9CgZlcnJvcnMYAiADKAsyJS5sdWNpLnJlc3VsdGRiLnYxLkZhaWx1cmVS'
        'ZWFzb24uRXJyb3JSBmVycm9ycxI0ChZ0cnVuY2F0ZWRfZXJyb3JzX2NvdW50GAMgASgFUhR0cn'
        'VuY2F0ZWRFcnJvcnNDb3VudBohCgVFcnJvchIYCgdtZXNzYWdlGAEgASgJUgdtZXNzYWdl');
