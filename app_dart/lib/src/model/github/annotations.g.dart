// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'annotations.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Annotation _$AnnotationFromJson(Map<String, dynamic> json) =>
    Annotation()
      ..annotationLevel = json['annotation_level'] as String?
      ..message = json['message'] as String?;

Map<String, dynamic> _$AnnotationToJson(Annotation instance) =>
    <String, dynamic>{
      'annotation_level': instance.annotationLevel,
      'message': instance.message,
    };
