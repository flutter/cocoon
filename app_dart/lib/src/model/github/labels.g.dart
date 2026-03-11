// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'labels.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LabeledEvent _$LabeledEventFromJson(Map<String, dynamic> json) =>
    LabeledEvent(label: Label.fromJson(json['label'] as Map<String, dynamic>));

Map<String, dynamic> _$LabeledEventToJson(LabeledEvent instance) =>
    <String, dynamic>{'label': instance.label};

Label _$LabelFromJson(Map<String, dynamic> json) => Label(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  nodeId: json['node_id'] as String,
  url: Uri.parse(json['url'] as String),
  color: json['color'] as String,
  description: json['description'] as String,
);

Map<String, dynamic> _$LabelToJson(Label instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'node_id': instance.nodeId,
  'url': instance.url.toString(),
  'color': instance.color,
  'description': instance.description,
};
