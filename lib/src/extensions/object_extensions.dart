import 'dart:mirrors';

import 'package:dart_core_orm/dart_core_orm.dart';
import 'package:dart_core_orm/src/orm.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

extension ObjectExtensions on Object {
  
  /// Update or insert
  ChainedQuery upsert() {
    return insert(
      conflictResolution: ConflictResolution.update,
    );
  }

  /// [conflictResolution] is used to specify how to handle conflicts
  /// when inserting a row that already exists
  ChainedQuery insert({
    ConflictResolution conflictResolution = ConflictResolution.error,
  }) {
    final query = ChainedQuery()..type = runtimeType;
    final tableName = runtimeType.toTableName();
    final json = toJson(
      includeNullValues: false,
    ) as Map;
    final keys = <String>[];
    final values = <Object?>[];
    if (orm?.family == DatabaseFamily.postgres) {
      query.add('INSERT INTO $tableName');
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
      query.add('(${keys.join(', ')}) VALUES (${values.join(', ')})');
      if (conflictResolution == ConflictResolution.ignore) {
        query.add('ON CONFLICT DO NOTHING');
      } else if (conflictResolution == ConflictResolution.update) {
        final classReflection = reflectClass(query.type!);
        final fieldDescription = classReflection.getFieldsDescription(
          query.type!,
        );
        final uniqueColumns = fieldDescription.where((e) => e.hasUniqueConstraints).toList();
        if (uniqueColumns.isNotEmpty) {
          /// because update only makes sense when there is a unique constraint
          final uniqueKeys = keys.where((e) => uniqueColumns.any((c) => c.fieldName == e)).toList();
          if (uniqueKeys.isNotEmpty) {
            query.add('ON CONFLICT (${uniqueKeys.join(', ')}) DO UPDATE SET');
            for (var i = 0; i < keys.length; i++) {
              query.add('${keys[i]} = EXCLUDED.${keys[i]}');
              if (i != keys.length - 1) {
                query.add(', ');
              }
            }
          }
        }
      }
    }
    return query;
  }
}
