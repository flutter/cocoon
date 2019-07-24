// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:mirrors';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:gcloud/db.dart';
import 'package:test/test.dart';

// Statically reference something from the Cocoon library to keep the analyzer
// happy that we're importing it (which we're doing so the mirrors system sees
// the library).
const Type libraryReference = Config;

bool isKind(InstanceMirror annotation) => annotation.reflectee.runtimeType == Kind;
bool isProperty(InstanceMirror annotation) =>
    SymbolName(annotation.type.simpleName).toString().endsWith('Property');

const Map<Symbol, Symbol> propertyAnnotationsTypeToFieldType = <Symbol, Symbol>{
  #BlobProperty: #List,
  #BoolProperty: #bool,
  #DateTimeProperty: #Date,
  #DoubleProperty: #double,
  #IntProperty: #int,
  #ListProperty: #List,
  #ModelKeyProperty: #Key,
  #StringListProperty: #List,
  #StringProperty: #String,
};

void main() {
  Iterable<LibraryMirror> libraries = currentMirrorSystem()
      .libraries
      .entries
      .where((MapEntry<Uri, LibraryMirror> entry) => entry.key.path.contains('cocoon_service'))
      .map((MapEntry<Uri, LibraryMirror> entry) => entry.value);
  for (LibraryMirror library in libraries) {
    Iterable<ClassMirror> classes = library.declarations.values
        .whereType<ClassMirror>()
        .where((ClassMirror declaration) => declaration.hasReflectedType)
        .where((ClassMirror declaration) => declaration.metadata.any(isKind));
    for (ClassMirror modelClass in classes) {
      group('${modelClass.reflectedType}', () {
        test('extends Model', () {
          expect(modelClass.superclass.reflectedType, Model);
        });

        Iterable<VariableMirror> propertyVariables = modelClass.declarations.values
            .whereType<VariableMirror>()
            .where((DeclarationMirror declaration) => declaration.metadata.any(isProperty));

        for (VariableMirror variable in propertyVariables) {
          Iterable<InstanceMirror> propertyAnnotations = variable.metadata.where(isProperty);

          group(SymbolName(variable.simpleName), () {
            test('contains only one property annotation', () {
              expect(propertyAnnotations, hasLength(1));
            });

            test('type matches property annotation type', () {
              Symbol propertyType = variable.type.simpleName;
              expect(propertyAnnotationsTypeToFieldType[propertyAnnotations.single.type.simpleName],
                  propertyType);
            });

            test('is not static', () {
              expect(variable.isStatic, isFalse);
            });

            test('is not final', () {
              expect(variable.isFinal, isFalse);
            });
          });
        }

        Iterable<MethodMirror> propertyGetters = modelClass.declarations.values
            .whereType<MethodMirror>()
            .where((MethodMirror method) => method.isGetter)
            .where((DeclarationMirror declaration) => declaration.metadata.any(isProperty));

        for (MethodMirror getter in propertyGetters) {
          Iterable<InstanceMirror> propertyAnnotations = getter.metadata.where(isProperty);

          group(SymbolName(getter.simpleName), () {
            test('contains only one property annotation', () {
              expect(propertyAnnotations, hasLength(1));
            });

            test('type matches property annotation type', () {
              Symbol propertyType = getter.returnType.simpleName;
              expect(propertyAnnotationsTypeToFieldType[propertyAnnotations.single.type.simpleName],
                  propertyType);
            });

            test('is not static', () {
              expect(getter.isStatic, isFalse);
            });

            test('has corresponding setter', () {
              Iterable<MethodMirror> setter = modelClass.declarations.values
                  .whereType<MethodMirror>()
                  .where((MethodMirror method) => method.isSetter)
                  .where((MethodMirror setter) =>
                      setter.simpleName == SymbolName(getter.simpleName).asSetter);
              expect(setter, hasLength(1));
            });
          });
        }
      });
    }
  }

  test('SymbolName toString', () {
    expect(SymbolName(#Foo).toString(), 'Foo');
  });
}

class SymbolName {
  const SymbolName(this.symbol);

  final Symbol symbol;

  static final RegExp symbolToString = RegExp(r'^Symbol\("(.*)"\)$');

  Symbol get asSetter => Symbol('$this=');

  @override
  String toString() {
    String raw = symbol.toString();
    RegExpMatch match = symbolToString.firstMatch(raw);
    return match == null ? raw : match.group(1);
  }
}
