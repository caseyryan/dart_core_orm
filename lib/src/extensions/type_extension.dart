// ignore_for_file: depend_on_referenced_packages

import 'dart:mirrors';

import 'package:collection/collection.dart';
import 'package:dart_core_orm/dart_core_orm.dart';
import 'package:dart_core_orm/src/annotations/table_column_annotations.dart';
import 'package:dart_core_orm/src/orm.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

extension TypeExtension on Type {
  ChainedQuery _toChainedQuery() {
    final query = this is ChainedQuery ? this as ChainedQuery : ChainedQuery()
      ..type = this;
    return query;
  }

  String toDatabaseType(
    List<TableColumnAnnotation> columnAnnotations,
    String fieldName,
  ) {
    if (this == String) {
      if (orm?.family == DatabaseFamily.postgres) {
        if (columnAnnotations.isNotEmpty) {
          final limitAnnotation = columnAnnotations.lastWhereOrNull(
            (e) => e is LimitColumn,
          );
          if (limitAnnotation != null) {
            return limitAnnotation.getValueForType(this, fieldName);
          }
        }

        return 'TEXT';
      }
    }
    if (this == int) {
      if (orm?.family == DatabaseFamily.postgres) {
        final limitAnnotation = columnAnnotations.lastWhereOrNull(
          (e) => e is LimitColumn,
        );
        if (limitAnnotation != null) {
          return limitAnnotation.getValueForType(this, fieldName);
        }
        final uniqueConstraint = columnAnnotations.whereType<UniqueColumn>().firstOrNull;
        if (uniqueConstraint != null) {
          /// for SERIAL type we don't need any of these
          columnAnnotations.removeWhere((e) => e is NotNullColumn);
          if (uniqueConstraint.autoIncrement == true) {
            /// uniqueConstraint?.autoIncrement adds SERIAL pseudo type
            /// that is automatically creating an INTEGER wo we don't need to return integer
            /// here
            return '';
          }
        }
        return 'INTEGER';
      }
    }
    if (this == bool) {
      if (orm?.family == DatabaseFamily.postgres) {
        return 'BOOLEAN';
      }
    }
    return '';
  }

  /// [dryRun] is used to only show the query itself not actually executing it
  /// [ifExists] is used to check if the table exists before dropping it
  /// to avoid error in case the table does not exist
  /// [cascade] this will automatically drop any dependent objects
  /// such as foreign key constraints.
  Future dropTable({
    bool dryRun = false,
    bool ifExists = false,
    bool cascade = false,
  }) async {
    final query = _toChainedQuery();
    final tableName = toTableName();
    if (orm?.family == DatabaseFamily.postgres) {
      if (ifExists) {
        query.add('DROP TABLE IF EXISTS $tableName');
      } else {
        query.add('DROP TABLE $tableName');
      }
      if (cascade) {
        query.add('CASCADE');
      }
      if (!dryRun) {
        await query.execute();
      } else {
        query.printQuery();
      }
    }
  }

  Map<String, String> toColumnKeys() {
    final objectType = this.fromJson({});
    final convertedKeys = <String, String>{};
    objectType!.toJson(
      includeNullValues: true,
      onKeyConversion: (
        ConvertedKey keyConversionResult,
      ) {
        convertedKeys[keyConversionResult.oldKey] = keyConversionResult.newKey;
      },
    );
    return convertedKeys;
  }

  /// [dryRun] is used to only show the query itself not actually
  /// executing it
  Future createTable({
    bool dryRun = false,
    bool ifNotExists = true,
  }) async {
    final query = _toChainedQuery();
    final tableName = toTableName();
    final typeMirror = reflectType(query.type!);
    final classMirror = typeMirror as ClassMirror;
    if (orm?.family == DatabaseFamily.postgres) {
      query.add('CREATE TABLE');
      if (ifNotExists) {
        query.add('IF NOT EXISTS');
      }
      query.add(tableName);
      query.add('(');

      final fieldDescriptions = classMirror.getFieldsDescription(query.type!);
      query.add(fieldDescriptions.join(', '));
      query.add(')');
    }
    if (!dryRun) {
      final result = await query.execute(dryRun: dryRun);
      return result;
    } else {
      query.printQuery();
    }
    return null;
  }

  /// [update] is an instance of your model with the changed
  /// fields you want to update
  /// e.g. you want to update a Car record and update the manufacturer:
  /// you create an instance of Car and set the manufacturer field
  /// and after that you write a where clause to specify which record
  /// to update
  /// like this:
  /*

    final updatedInstance = Car() 
     ..manufacturer = 'BYD Tang';
      (Car).update(updatedInstance).where([
        Equal(
          key: 'id',
          value: 7,
        ),
      ]).execute();
  
   */
  /// This will update the record with the id of 7
  /// and set the manufacturer to 'BYD Tang'

  ChainedQuery update<T>(T update) {
    final query = _toChainedQuery();
    final tableName = toTableName();
    if (orm?.family == DatabaseFamily.postgres) {
      query.add('UPDATE $tableName');
      final json = (update as Object).toJson(
        includeNullValues: false,
      ) as Map;
      query.add('SET');
      query.add(json.entries.map(
        (entry) {
          var value = entry.value;
          if (value is String) {
            value = "'${value.sanitize()}'";
          }
          return '${entry.key} = $value';
        },
      ).join(', '));
    }
    return query;
  }

  ChainedQuery insertMany<T>(
    List<T> inserts, {
    ConflictResolution conflictResolution = ConflictResolution.error,
  }) {
    // TODO: implement conflict resolution
    final query = _toChainedQuery();
    final tableName = toTableName();
    final values = StringBuffer();
    String? updateQuery;
    if (orm?.family == DatabaseFamily.postgres) {
      bool hasForeignKeys = false;
      for (var i = 0; i < inserts.length; i++) {
        final item = inserts[i] as Object;
        final isLast = i == inserts.length - 1;

        final foreignKeyObjects = item.getForeignKeyObjects();
        hasForeignKeys = foreignKeyObjects.isNotEmpty;
        if (hasForeignKeys) {
          /// Create a transaction for foreign keys
          // TODO: create queries with foreign keys
          final tempQueries = <String>['BEGIN;'];
          for (var fko in foreignKeyObjects) {
            final fkoQuery = fko.object.insert(
              conflictResolution: ConflictResolution.update,
            );
            tempQueries.add(fkoQuery.toQueryString());
          }
          final InsertQueries? insertQueries = item.toInsertQueries(
            item,
            foreignKeyObjects: foreignKeyObjects,
          );
          tempQueries.add('INSERT INTO $tableName ${insertQueries!.keys} VALUES ${insertQueries.values}');
          updateQuery = insertQueries.updateQuery;
          if (updateQuery?.isNotEmpty == true) {
            tempQueries.add(updateQuery!);
          }
          tempQueries.add(';');
          tempQueries.add('COMMIT');
          query._parts.clear();
          query._parts.addAll(tempQueries);
        } else {
          final insertQueries = item.toInsertQueries(
            item,
          );
          if (i == 0) {
            updateQuery = insertQueries!.updateQuery;
            values.write(insertQueries.keys);
            values.write(' VALUES ');
          }
          if (insertQueries != null) {
            values.write(insertQueries.values);
            if (!isLast) {
              values.write(', ');
            }
          }
        }
      }
      if (!hasForeignKeys) {
        query.add('INSERT INTO $tableName');
        query.add(values.toString());
        if (updateQuery?.isNotEmpty == true) {
          query.add(updateQuery!);
        }
      }
    }

    return query;
  }

  ChainedQuery select([
    List<String>? paramsNames,
  ]) {
    final query = _toChainedQuery();
    final tableName = toTableName();
    if (orm?.family == DatabaseFamily.postgres) {
      query.add('SELECT');
      if (paramsNames?.isNotEmpty != true) {
        query.add('*');
      } else {
        query.add(paramsNames!.join(', '));
      }
      query.add('FROM $tableName');
    }
    return query;
  }

  ChainedQuery delete() {
    final query = _toChainedQuery();
    final tableName = toTableName();
    if (orm?.family == DatabaseFamily.postgres) {
      query.add('DELETE FROM $tableName');
    }
    return query;
  }

  bool isSubclassOf<T>() {
    final classMirror = reflectType(this) as ClassMirror;
    return classMirror.isSubclassOf(reflectType(T) as ClassMirror);
  }

  /// [plural] by default the table names are pluralized
  /// e.g Author -> authors
  String toTableName({
    bool plural = true,
  }) {
    final typeMirror = reflectType(this);

    final metadata = reflectType(this).metadata;
    final classAnnotations = metadata.where(
      (e) {
        return e.reflectee.runtimeType.isSubclassOf<ClassAnnotation>();
      },
    ).toList();
    final ending = plural ? 's' : '';
    return (classAnnotations.lastOrNull?.reflectee as TableName?)?.name ??
        '${typeMirror.simpleName.toName().camelToSnake()}$ending';
  }
}

enum ConflictResolution {
  ignore,
  update,
  error,
}

class ChainedQuery {
  Type? type;

  final List<String> _parts = [];

  void add(String part) {
    _parts.add(part);
  }

  void prepend(String part) {
    _parts.insert(0, part);
  }

  String get queryType {
    if (_parts.isNotEmpty) {
      final first = _parts.first;
      if (first.contains('SELECT')) {
        return 'SELECT';
      }
      if (first.contains('INSERT')) {
        return 'INSERT';
      }
      if (first.contains('UPDATE')) {
        return 'UPDATE';
      }
      if (first.contains('DELETE')) {
        return 'DELETE';
      }
      if (first.contains('CREATE TABLE')) {
        return 'CREATE TABLE';
      }
    }
    return '';
  }

  bool get _canReturnResult {
    switch (queryType) {
      case 'INSERT':
      case 'UPDATE':
      case 'DELETE':
        return true;
      case 'SELECT':
      case 'CREATE TABLE':
        return false;
    }
    return false;
  }

  bool get _allowsChaining {
    switch (queryType) {
      case 'SELECT':
      case 'INSERT':
      case 'UPDATE':
      case 'DELETE':
        return true;
      case 'CREATE TABLE':
        return false;
    }
    return true;
  }

  bool get _isDeleteQuery {
    return queryType == 'DELETE';
  }

  ChainedQuery where(List<WhereOperation> operations) {
    if (operations.isEmpty) {
      return this;
    }
    _checkIfChainingIsAllowed();
    add('WHERE');
    if (operations.length == 1) {
      add(operations.first.toOperation());
    } else if (operations.length > 1) {
      for (var i = 0; i < operations.length; i++) {
        final operation = operations[i];
        add(operation.toOperation());
        if (i != operations.length - 1) {
          add(operation.nextJoiner.value);
        }
      }
    }
    return this;
  }

  void _checkIfChainingIsAllowed() {
    if (!_allowsChaining) {
      throw Exception('Chaining is not allowed for $queryType queries');
    }
  }

  void printQuery() {
    print('PREPARED QUERY: ${toQueryString()}');
  }

  String toQueryString() {
    return '${_parts.join(' ')};';
  }

  Future<List> toListAsync() async {
    final executeResult = await execute();
    if (executeResult is List) {
      return executeResult.map((e) {
        return type!.fromJson(e);
      }).toList();
    }
    return [];
  }

  Future<Object?> execute({
    Duration? timeout,
    bool dryRun = false,
    bool returnResult = false,
  }) async {
    if (returnResult) {
      if (_canReturnResult) {
        add('RETURNING *');
      }
    }
    final query = toQueryString();
    final result = await orm?.executeSimpleQuery(
      query: query,
      timeout: timeout,
      dryRun: dryRun,
    );
    if (result is List && result.isNotEmpty) {
      if (result.first is Map) {
        return result.map((e) {
          // print(e);
          return type!.fromJson(e);
        }).toList();
      }

      /// This might contain errors as String objects
      return result;
    }
    return [];
  }
}

FieldDescription getFieldDescription({
  required String fieldName,
  required Type fieldType,
  required List<InstanceMirror> metadata,
}) {
  List<TableColumnAnnotation> columnAnnotations = [];
  if (metadata.isNotEmpty) {
    /// row annotations are required to apply adjusted data types
    /// instead of the evaluated based on the field type
    columnAnnotations.addAll(
      metadata.where((e) {
        return e.reflectee is TableColumnAnnotation;
      }).map((e) => e.reflectee),
    );
  }
  final databaseType = fieldType.toDatabaseType(
    columnAnnotations,
    fieldName,
  );
  final otherColumnAnnotations = columnAnnotations.where((e) {
    return e is! LimitColumn;
  }).toList();
  otherColumnAnnotations.sort((a, b) => a.order.compareTo(b.order));
  bool hasUniqueConstraints = otherColumnAnnotations.any((e) => e is UniqueColumn || e is PrimaryKeyColumn);

  final fieldDescription = FieldDescription(
    fieldName: fieldName,
    hasUniqueConstraints: hasUniqueConstraints,
    dataTypes: [
      databaseType,
      ...otherColumnAnnotations.mapIndexed(
        (int index, TableColumnAnnotation e) {
          var value = e.getValueForType(
            fieldType,
            fieldName,
          );
          if (e is ForeignKeyColumn) {
            if (index > 0) {
              value = ', $value';
            }
          }
          return value;
        },
      )
    ],
  );
  return fieldDescription;
}

/// when a type is decomposed using mirrors, the SDK created a list of
/// [FieldDescription] objects that describe each field
/// of the type to prepare a database query
class FieldDescription {
  /// this can contain a list of data types
  /// for example [VARCHAR(50), 'SERIAL', 'PRIMARY KEY', 'NOT NULL'] etc.
  /// it will be joined when query is about to be executed
  final List<String> dataTypes;
  final String fieldName;
  final bool hasUniqueConstraints;
  FieldDescription({
    required this.dataTypes,
    required this.fieldName,
    required this.hasUniqueConstraints,
  });

  @override
  String toString() {
    return '$fieldName ${dataTypes.join(' ')}';
  }
}
