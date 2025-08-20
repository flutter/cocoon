// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_hash_lookup.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContentHashLookup _$ContentHashLookupFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ContentHashLookup', json, ($checkedConvert) {
      final val = ContentHashLookup(
        contentHash: $checkedConvert('contentHash', (v) => v as String),
        gitShas: $checkedConvert(
          'gitShas',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ContentHashLookupToJson(ContentHashLookup instance) =>
    <String, dynamic>{
      'contentHash': instance.contentHash,
      'gitShas': instance.gitShas,
    };
