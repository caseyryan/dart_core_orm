import 'dart:mirrors';

import 'package:dart_core_orm/dart_core_orm.dart';
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
  Object? tryConvertValueToDatabaseCompatible() {
    if (orm.family == DatabaseFamily.postgres) {
      if (this is String) {
        final str = (this as String).sanitize();
        if (str.startsWith("'") && str.endsWith("'")) {
          return str;
        }
        return "'$str'";
      } else if (this is bool) {
        return this == true ? 'TRUE' : 'FALSE';
      } else if (this is List) {
        print(this);
      }
    }
    throw 'Other types are not supported yet';
  }

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
      final foreignKeyAnnotation = (kv.value as VariableMirror)
          .getAnnotationsOfType<ForeignKeyColumn>()
          .lastOrNull;
      if (foreignKeyAnnotation == null) {
        continue;
      }
      var variableLevelKeyConvertor =
          (kv.value as VariableMirror).tryGetKeyNameConverter(
        variableName: kv.key.toName(),
      );
      final keyNameConverter =
          variableLevelKeyConvertor ?? classLevelKeyConvertor;

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
    bool withUpsert = false,
  }) {
    if (object == null) {
      return null;
    }
    final type = object is Type ? object : object.runtimeType;
    if (orm.family == DatabaseFamily.postgres) {
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
          } else {
            values.add(
                (kv.value as Object).tryConvertValueToDatabaseCompatible());
          }
        } 
        else if (kv.value is List) {
          keys.add(kv.key);
          values.add('ARRAY[${(kv.value as List).map((e) {
            if (e is String) {
              return "'$e'";
            }
            return e;
          }).join(', ')}]');
        }
        else if (kv.value != null) {
          print(kv.value);
        }
      }
      final classReflection = reflectClass(type);
      final fieldDescription = classReflection.getFieldsDescription(
        type,
      );
      final uniqueColumns =
          fieldDescription.where((e) => e.hasUniqueConstraints).toList();
      final parts = <String>[];
      final uniqueKeys = keys
          .where((e) => uniqueColumns.any((c) => c.fieldName == e))
          .toList();
      final uKeys =
          uniqueKeys.map((e) => e.wrapInDoubleQuotesIfNeeded()).join(', ');

      if (foreignKeyObjects.isNotEmpty) {
        keys.addAll(foreignKeyObjects.map((e) => e.fieldName));
        if (withUpsert) {
          /// this is required to return the real conflicting value
          /// (if there's any) but not the autogenerated one which LASTVAL() returns
          values.addAll(foreignKeyObjects.map(
              (e) => '(SELECT ${e.foreignKeyColumn.foreignKey} FROM upsert)'));
        } else {
          values.addAll(foreignKeyObjects.map((e) => 'LASTVAL()'));
        }
      }
      String valuesOnly = '(${values.join(', ')})';
      String keysOnly =
          '(${keys.map((e) => e.wrapInDoubleQuotesIfNeeded()).join(', ')})';
      if (uniqueColumns.isNotEmpty) {
        /// because update only makes sense when there is a unique constraint
        if (uniqueKeys.isNotEmpty) {
          parts.add(' ON CONFLICT ($uKeys) DO UPDATE SET ');

          for (var i = 0; i < keys.length; i++) {
            final keyName = keys[i];
            if (uniqueKeys.contains(keys[i])) {
              continue;
            }
            parts.add(
                '${keyName.wrapInDoubleQuotesIfNeeded()} = EXCLUDED.${keyName.wrapInDoubleQuotesIfNeeded()}');
            if (i < keys.length - 1) {
              parts.add(', ');
            }
          }
          if (parts.isNotEmpty && parts.last == ', ') {
            parts.removeLast();
          }
          parts.add(' RETURNING $uKeys');
        }
      }
      return InsertQueries(
        values: valuesOnly,
        keys: keysOnly,
        updateQuery: parts.join(),
      );
    }
    return null;
  }

  /// try update or insert one record
  Future<QueryResult<T>> tryUpsertOne<T>({
    bool dryRun = false,
  }) async {
    final result = await upsert().execute(
      dryRun: dryRun,
      returnResult: true,
    );
    if (result is List && result.length == 1 && result.first is T) {
      return QueryResult(
        value: result.first as T,
        error: null,
      );
    } else if (result is OrmError) {
      return QueryResult(
        value: null,
        error: result,
      );
    }
    return QueryResult(
      value: null,
      error: null,
    );
  }

  /// A simple wrapper for SELECT using AND operations for all set fields
  /// If you need a more complicated query
  /// use runtimeType.select().where([...]) where you can
  /// pass other Where clauses
  /// or use direct database query using orm?.executeSimpleQuery
  /// 
  /// [T] can be a list of objects or a single object
  Future<QueryResult<T>> tryFind<T>({
    bool dryRun = false,
  }) async {
    if (orm.family == DatabaseFamily.postgres) {
      final json = toJson(
        includeNullValues: false,
      ) as Map<String, Object?>;
      final equalsClause = <WhereOperation>[];
      for (var kv in json.entries) {
        equalsClause.add(
          Equal(
            key: kv.key,
            value: kv.value,
            nextJoiner: Joiner.and,
          ),
        );
      }
      if (equalsClause.isNotEmpty) {
        final query = runtimeType.select().where(equalsClause);
        final value = await query.execute(dryRun: dryRun);
        if (value is List) {
          if (T.isList) {
            return QueryResult(
              value: value as T,
              error: null,
            );
          }
          if (value.length == 1) {
            return QueryResult(
              value: value.first as T,
              error: null,
            );
          }
        } else if (value is OrmError) {
          return QueryResult(
            value: null,
            error: value,
          );
        }
      }
    }
    return QueryResult(
      value: null,
      error: null,
    );
  }

  /// [conflictResolution] is used to specify how to handle conflicts
  /// when inserting a row that already exists
  ChainedQuery insert({
    ConflictResolution conflictResolution = ConflictResolution.error,
    bool withUpsert = false,
  }) {
    final query = ChainedQuery()..type = runtimeType;
    final tableName = runtimeType.toTableName();
    if (orm.family == DatabaseFamily.postgres) {
      query.add('INSERT INTO $tableName');
      final valueKeys = toInsertQueries(
        query.type!,
        withUpsert: withUpsert,
      );
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
