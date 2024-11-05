import 'dart:mirrors';

import 'package:dart_core_orm/dart_core_orm.dart';
import 'package:dart_core_orm/src/annotations/table_column_annotations.dart';
import 'package:dart_core_orm/src/orm.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

class InsertQueries {
  final String values;
  final String keys;
  final String? updateQuery;

  InsertQueries({
    required this.values,
    required this.keys,
    this.updateQuery,
  });
}

class ForeignKeyedField {
  final Object object;
  final ForeignKeyColumn foreignKeyColumn;
  final String fieldName;

  ForeignKeyedField({
    required this.object,
    required this.foreignKeyColumn,
    required this.fieldName,
  });
}

extension ObjectExtensions on Object {
  /// Update or insert
  ChainedQuery upsert() {
    return insert(
      conflictResolution: ConflictResolution.update,
    );
  }

  /// searches the current object for any foreign key annotations
  /// and returns the objects that must be inserted before the current object
  List<ForeignKeyedField> getForeignKeyObjects() {
    final typeReflection = reflectType(runtimeType) as ClassMirror;
    var classLevelKeyConvertor = typeReflection.tryGetKeyNameConverter();
    final instanceReflection = reflect(this);
    final result = <ForeignKeyedField>[];
    for (var kv in typeReflection.declarations.entries) {
      if (kv.value is! VariableMirror) {
        continue;
      }
      final foreignKeyAnnotation = (kv.value as VariableMirror).getAnnotationsOfType<ForeignKeyColumn>().lastOrNull;
      if (foreignKeyAnnotation == null) {
        continue;
      }
      var variableLevelKeyConvertor = (kv.value as VariableMirror).tryGetKeyNameConverter(
        variableName: kv.key.toName(),
      );
      final keyNameConverter = variableLevelKeyConvertor ?? classLevelKeyConvertor;

      /// this is required because the foreign key conversion
      /// needs to be done according to the variable naming in the model
      var fieldSuffixName = foreignKeyAnnotation.foreignKey;
      if (keyNameConverter != null) {
        fieldSuffixName = keyNameConverter.convert(fieldSuffixName);
        if (keyNameConverter is CamelToSnake) {
          fieldSuffixName = '_$fieldSuffixName';
        } else if (keyNameConverter is SnakeToCamel) {
          fieldSuffixName = '_${fieldSuffixName.firstToUpperCase()}';
        }
      }
      final fieldValue = instanceReflection.getField(kv.key).reflectee;

      /// here we convert the type of the object to the table name (in singular form)
      /// to prepend it to a foreign key name
      var singleTableName = fieldValue.runtimeType.toTableName(
        plural: false,
      );
      if (keyNameConverter != null) {
        singleTableName = keyNameConverter.convert(singleTableName);
      }

      /// on this step, the field name is transformed into a foreign key name
      /// e.g. a variable with a type of `Author` and the foreign key named `id`
      /// will join and become either `author_id` or `authorId` depending
      /// on the the key name converter
      final fieldName = '$singleTableName$fieldSuffixName';
      result.add(
        ForeignKeyedField(
          object: fieldValue,
          fieldName: fieldName,
          foreignKeyColumn: foreignKeyAnnotation,
        ),
      );

      /// also recursively check internal objects as well
      /// and insert them first because they will need to be inserted (updated) first
      // TODO: support nested foreign keys
      // result.insertAll(0, (fieldValue as Object).getForeignKeyObjects());
    }

    return result;
  }

  /// [object] can be either a [Type] or an instance.
  /// [foreignKeyObjects] if provided, this will mean that a transaction is required 
  /// and the foreign keys must form a special transaction
  InsertQueries? toInsertQueries(
    Object? object, {
    List<ForeignKeyedField> foreignKeyObjects = const [],
  }) {
    if (object == null) {
      return null;
    }
    final type = object is Type ? object : object.runtimeType;
    if (orm?.family == DatabaseFamily.postgres) {
      final json = toJson(
        includeNullValues: false,
      ) as Map;
      final keys = <String>[];
      final values = <Object?>[];
      for (var kv in json.entries) {
        if (kv.value?.runtimeType.isPrimitive != false) {
          keys.add(kv.key);
          if (kv.value == null) {
            values.add('NULL');
          } else if (kv.value is String) {
            values.add("'${(kv.value as String).sanitize()}'");
          } else {
            values.add(kv.value);
          }
        } else if (kv.value != null) {
          print(kv.value);
        }
      }
      if (foreignKeyObjects.isNotEmpty) {
        keys.addAll(foreignKeyObjects.map((e) => e.fieldName));
        values.addAll(foreignKeyObjects.map((e) => 'LASTVAL()'));
      }
      String valuesOnly = '(${values.join(', ')})';
      String keysOnly = '(${keys.join(', ')})';
      // valuesQuery = '(${keys.join(', ')}) VALUES $valuesOnly';
      final classReflection = reflectClass(type);
      final fieldDescription = classReflection.getFieldsDescription(
        type,
      );
      final uniqueColumns = fieldDescription.where((e) => e.hasUniqueConstraints).toList();
      final stringBuffer = StringBuffer();
      if (uniqueColumns.isNotEmpty) {
        /// because update only makes sense when there is a unique constraint
        final uniqueKeys = keys.where((e) => uniqueColumns.any((c) => c.fieldName == e)).toList();
        if (uniqueKeys.isNotEmpty) {
          stringBuffer.write('ON CONFLICT (${uniqueKeys.join(', ')}) DO UPDATE SET ');
          for (var i = 0; i < keys.length; i++) {
            stringBuffer.write('${keys[i]} = EXCLUDED.${keys[i]}');
            if (i != keys.length - 1) {
              stringBuffer.write(', ');
            }
          }
        }
      }
      return InsertQueries(
        values: valuesOnly,
        keys: keysOnly,
        updateQuery: stringBuffer.toString(),
      );
    }
    return null;
  }

  /// [conflictResolution] is used to specify how to handle conflicts
  /// when inserting a row that already exists
  ChainedQuery insert({
    ConflictResolution conflictResolution = ConflictResolution.error,
  }) {
    final query = ChainedQuery()..type = runtimeType;
    final tableName = runtimeType.toTableName();
    if (orm?.family == DatabaseFamily.postgres) {
      query.add('INSERT INTO $tableName');
      final valueKeys = toInsertQueries(query.type!);
      query.add('${valueKeys!.keys} VALUES ${valueKeys.values}');
      if (conflictResolution == ConflictResolution.ignore) {
        query.add('ON CONFLICT DO NOTHING');
      } else if (conflictResolution == ConflictResolution.update) {
        if (valueKeys.updateQuery != null) {
          query.add(valueKeys.updateQuery!);
        }
      }
    }
    return query;
  }
}
