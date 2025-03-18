// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_status_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuildStatusResponse _$BuildStatusResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BuildStatusResponse', json, ($checkedConvert) {
      final val = BuildStatusResponse(
        buildStatus: $checkedConvert(
          'buildStatus',
          (v) => BuildStatus._byValue((v as num).toInt()),
        ),
        failingTasks: $checkedConvert(
          'failingTasks',
          (v) => (v as List<dynamic>?)?.map((e) => e as String) ?? [],
        ),
      );
      return val;
    });

Map<String, dynamic> _$BuildStatusResponseToJson(
  BuildStatusResponse instance,
) => <String, dynamic>{
  'buildStatus': BuildStatus._toValue(instance.buildStatus),
  'failingTasks': instance.failingTasks,
};
