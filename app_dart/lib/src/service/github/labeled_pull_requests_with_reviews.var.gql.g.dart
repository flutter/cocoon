// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'labeled_pull_requests_with_reviews.var.gql.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<GLabeledPullRequestsWithReviewsVars> _$gLabeledPullRequestsWithReviewsVarsSerializer =
    new _$GLabeledPullRequestsWithReviewsVarsSerializer();

class _$GLabeledPullRequestsWithReviewsVarsSerializer
    implements StructuredSerializer<GLabeledPullRequestsWithReviewsVars> {
  @override
  final Iterable<Type> types = const [GLabeledPullRequestsWithReviewsVars, _$GLabeledPullRequestsWithReviewsVars];
  @override
  final String wireName = 'GLabeledPullRequestsWithReviewsVars';

  @override
  Iterable<Object> serialize(Serializers serializers, GLabeledPullRequestsWithReviewsVars object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'sOwner',
      serializers.serialize(object.sOwner, specifiedType: const FullType(String)),
      'sName',
      serializers.serialize(object.sName, specifiedType: const FullType(String)),
      'sLabelName',
      serializers.serialize(object.sLabelName, specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  GLabeledPullRequestsWithReviewsVars deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new GLabeledPullRequestsWithReviewsVarsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'sOwner':
          result.sOwner = serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          break;
        case 'sName':
          result.sName = serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          break;
        case 'sLabelName':
          result.sLabelName = serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$GLabeledPullRequestsWithReviewsVars extends GLabeledPullRequestsWithReviewsVars {
  @override
  final String sOwner;
  @override
  final String sName;
  @override
  final String sLabelName;

  factory _$GLabeledPullRequestsWithReviewsVars([void Function(GLabeledPullRequestsWithReviewsVarsBuilder) updates]) =>
      (new GLabeledPullRequestsWithReviewsVarsBuilder()..update(updates)).build();

  _$GLabeledPullRequestsWithReviewsVars._({this.sOwner, this.sName, this.sLabelName}) : super._() {
    if (sOwner == null) {
      throw new BuiltValueNullFieldError('GLabeledPullRequestsWithReviewsVars', 'sOwner');
    }
    if (sName == null) {
      throw new BuiltValueNullFieldError('GLabeledPullRequestsWithReviewsVars', 'sName');
    }
    if (sLabelName == null) {
      throw new BuiltValueNullFieldError('GLabeledPullRequestsWithReviewsVars', 'sLabelName');
    }
  }

  @override
  GLabeledPullRequestsWithReviewsVars rebuild(void Function(GLabeledPullRequestsWithReviewsVarsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GLabeledPullRequestsWithReviewsVarsBuilder toBuilder() =>
      new GLabeledPullRequestsWithReviewsVarsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GLabeledPullRequestsWithReviewsVars &&
        sOwner == other.sOwner &&
        sName == other.sName &&
        sLabelName == other.sLabelName;
  }

  @override
  int get hashCode {
    return $jf($jc($jc($jc(0, sOwner.hashCode), sName.hashCode), sLabelName.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('GLabeledPullRequestsWithReviewsVars')
          ..add('sOwner', sOwner)
          ..add('sName', sName)
          ..add('sLabelName', sLabelName))
        .toString();
  }
}

class GLabeledPullRequestsWithReviewsVarsBuilder
    implements Builder<GLabeledPullRequestsWithReviewsVars, GLabeledPullRequestsWithReviewsVarsBuilder> {
  _$GLabeledPullRequestsWithReviewsVars _$v;

  String _sOwner;
  String get sOwner => _$this._sOwner;
  set sOwner(String sOwner) => _$this._sOwner = sOwner;

  String _sName;
  String get sName => _$this._sName;
  set sName(String sName) => _$this._sName = sName;

  String _sLabelName;
  String get sLabelName => _$this._sLabelName;
  set sLabelName(String sLabelName) => _$this._sLabelName = sLabelName;

  GLabeledPullRequestsWithReviewsVarsBuilder();

  GLabeledPullRequestsWithReviewsVarsBuilder get _$this {
    if (_$v != null) {
      _sOwner = _$v.sOwner;
      _sName = _$v.sName;
      _sLabelName = _$v.sLabelName;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GLabeledPullRequestsWithReviewsVars other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$GLabeledPullRequestsWithReviewsVars;
  }

  @override
  void update(void Function(GLabeledPullRequestsWithReviewsVarsBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$GLabeledPullRequestsWithReviewsVars build() {
    final _$result =
        _$v ?? new _$GLabeledPullRequestsWithReviewsVars._(sOwner: sOwner, sName: sName, sLabelName: sLabelName);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
