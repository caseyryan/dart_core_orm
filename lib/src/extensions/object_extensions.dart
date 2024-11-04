import 'dart:mirrors';

import 'package:dart_core_orm/dart_core_orm.dart';
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

extension ObjectExtensions on Object {
  /// Update or insert
  ChainedQuery upsert() {
    return insert(
      conflictResolution: ConflictResolution.update,
    );
  }

  /// [onlyValues] can be used for inserting many items
  /// where we don't need to build the whole query but just need
  /// value
  InsertQueries? toInsertQueries(
    Type type,
  ) {
    if (orm?.family == DatabaseFamily.postgres) {
      final json = toJson(
        includeNullValues: false,
      ) as Map;
      final keys = <String>[];
      final values = <Object?>[];
      for (var kv in json.entries) {
        // TODO: Support non primitive types and foreign keys
        if (kv.key.runtimeType.isPrimitive) {
          keys.add(kv.key);
          if (kv.value == null) {
            values.add('NULL');
          } else if (kv.value is String) {
            values.add("'${kv.value}'");
          } else {
            values.add(kv.value);
          }
        }
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
