///
//  Generated code. Do not modify.
//  source: google/protobuf/any.proto
///
// ignore_for_file: non_constant_identifier_names,library_prefixes,unused_import

// ignore: UNUSED_SHOWN_NAME
import 'dart:core' show int, bool, double, String, List, override;

import 'package:protobuf/protobuf.dart' as $pb;

class Any extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('Any',
      package: const $pb.PackageName('google.protobuf'))
    ..aOS(1, 'typeUrl')
    ..a<List<int>>(2, 'value', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  Any() : super();
  Any.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  Any.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  Any clone() => new Any()..mergeFromMessage(this);
  Any copyWith(void Function(Any) updates) =>
      super.copyWith((message) => updates(message as Any));
  $pb.BuilderInfo get info_ => _i;
  static Any create() => new Any();
  static $pb.PbList<Any> createRepeated() => new $pb.PbList<Any>();
  static Any getDefault() => _defaultInstance ??= create()..freeze();
  static Any _defaultInstance;
  static void $checkItem(Any v) {
    if (v is! Any) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get typeUrl => $_getS(0, '');
  set typeUrl(String v) {
    $_setString(0, v);
  }

  bool hasTypeUrl() => $_has(0);
  void clearTypeUrl() => clearField(1);

  List<int> get value => $_getN(1);
  set value(List<int> v) {
    $_setBytes(1, v);
  }

  bool hasValue() => $_has(1);
  void clearValue() => clearField(2);

  /// Unpacks the message in [value] into [instance].
  ///
  /// Throws a [InvalidProtocolBufferException] if [typeUrl] does not correspond
  /// to the type of [instance].
  ///
  /// A typical usage would be `any.unpackInto(new Message())`.
  ///
  /// Returns [instance].
  T unpackInto<T extends $pb.GeneratedMessage>(T instance,
      {$pb.ExtensionRegistry extensionRegistry = $pb.ExtensionRegistry.EMPTY}) {
    $pb.unpackIntoHelper(value, instance, typeUrl,
        extensionRegistry: extensionRegistry);
    return instance;
  }

  /// Returns `true` if the encoded message matches the type of [instance].
  ///
  /// Can be used with a default instance:
  /// `any.canUnpackInto(Message.getDefault())`
  bool canUnpackInto($pb.GeneratedMessage instance) {
    return $pb.canUnpackIntoHelper(instance, typeUrl);
  }

  /// Creates a new [Any] encoding [message].
  ///
  /// The [typeUrl] will be [typeUrlPrefix]/`fullName` where `fullName` is
  /// the fully qualified name of the type of [message].
  static Any pack($pb.GeneratedMessage message,
      {String typeUrlPrefix = 'type.googleapis.com'}) {
    return new Any()
      ..value = message.writeToBuffer()
      ..typeUrl = '${typeUrlPrefix}/${message.info_.qualifiedMessageName}';
  }
}
