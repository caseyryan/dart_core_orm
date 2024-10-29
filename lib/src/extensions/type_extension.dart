// ignore_for_file: depend_on_referenced_packages

import 'dart:mirrors';

import 'package:collection/collection.dart';
import 'package:dart_core_orm/src/annotations/class_annotations.dart';
import 'package:dart_core_orm/src/annotations/table_column_annotations.dart';
import 'package:dart_core_orm/src/orm.dart';
import 'package:dart_core_orm/src/where_operations.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

extension TypeExtension on Type {
  ChainedQuery _toChainedQuery() {
    final query = this is ChainedQuery ? this as ChainedQuery : ChainedQuery()
      .._type = this;
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
  /// [cascade] this will automatically drop any dependent objects, such as foreign key constraints.
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
        query.execute();
      } else {
        query.printQuery();
      }
    }
  }

  /// [dryRun] is used to only show the query itself not actually
  /// executing it
  Future createTable({
    bool dryRun = false,
  }) async {
    final query = _toChainedQuery();
    final tableName = toTableName();
    final typeMirror = reflectType(query._type!);
    final classMirror = typeMirror as ClassMirror;
    if (orm?.family == DatabaseFamily.postgres) {
      query.add('CREATE TABLE $tableName (');
      final json = query._type!.fromJson({});
      final convertedKeys = <String, String>{};
      json!.toJson(
        includeNullValues: true,
        onKeyConversion: (
          ConvertedKey keyConversionResult,
        ) {
          convertedKeys[keyConversionResult.oldKey] = keyConversionResult.newKey;
        },
      );

      final fields = classMirror.declarations.entries
          .where(
            (e) =>
                e.value is VariableMirror &&
                !(e.value as VariableMirror).isPrivate &&
                !(e.value as VariableMirror).isConst,
          )
          .toList();
      final fieldDescriptions = <FieldDescription>[];
      for (var i = 0; i < fields.length; i++) {
        final field = fields[i];
        if (field.value is VariableMirror) {
          var name = field.key.toName();
          name = convertedKeys[name] ?? name;
          final fieldType = (field.value as VariableMirror).type.reflectedType;
          fieldDescriptions.add(
            _getFieldDescription(
              fieldName: name,
              fieldType: fieldType,
              metadata: field.value.metadata,
            ),
          );
        }
      }
      query.add(fieldDescriptions.join(', '));
      query.add(')');
    }
    if (!dryRun) {
      query.execute();
    } else {
      query.printQuery();
    }
  }

  FieldDescription _getFieldDescription({
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
    otherColumnAnnotations.sort((a, b) => b.order.compareTo(a.order));

    final fieldDescription = FieldDescription._(
      fieldName: fieldName,
      dataTypes: [
        databaseType,
        ...otherColumnAnnotations.map(
          (e) => e.getValueForType(
            fieldType,
            fieldName,
          ),
        )
      ],
    );
    return fieldDescription;
  }

  ChainedQuery select([List<String>? paramsNames]) {
    final query = _toChainedQuery();
    final tableName = toTableName();
    query.add('SELECT');
    if (paramsNames?.isNotEmpty != true) {
      query.add('*');
    } else {
      query.add(paramsNames!.join(', '));
    }
    query.add('FROM $tableName');
    return query;
  }

  bool isSubclassOf<T>() {
    final classMirror = reflectType(this) as ClassMirror;
    return classMirror.isSubclassOf(reflectType(T) as ClassMirror);
  }

  String toTableName() {
    final typeMirror = reflectType(this);

    final metadata = reflectType(this).metadata;
    final classAnnotations = metadata.where(
      (e) {
        return e.reflectee.runtimeType.isSubclassOf<ClassAnnotation>();
      },
    ).toList();
    return (classAnnotations.lastOrNull?.reflectee as TableName?)?.name ??
        '${typeMirror.simpleName.toName().camelToSnake()}s';
  }
}

class ChainedQuery {
  Type? _type;

  final List<String> _parts = [];

  void add(String part) {
    _parts.add(part);
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

  ChainedQuery where(List<WhereOperation> operations) {
    if (operations.isEmpty) {
      return this;
    }
    _checkIfChainingIsAllowed();
    add('WHERE');
    add(operations.map((e) => e.toOperation()).join(' AND ').trim());
    return this;
  }

  void _checkIfChainingIsAllowed() {
    if (!_allowsChaining) {
      throw Exception('Chaining is not allowed for $queryType queries');
    }
  }

  void printQuery() {
    print('PREPARED QUERY: ${_getQueryString()}');
  }

  String _getQueryString() {
    return '${_parts.join(' ')};';
  }

  Future<List> execute() async {
    final query = _getQueryString();
    if (orm?.printQueries == true) {
      print('EXECUTING QUERY: $query');
    }
    final List mappedResult = await orm?.executeSimpleQuery(query: query) as List? ?? [];
    return mappedResult.map((e) {
      return _type!.fromJson(e);
    }).toList();
  }
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
  FieldDescription._({
    required this.dataTypes,
    required this.fieldName,
  });

  @override
  String toString() {
    return '$fieldName ${dataTypes.join(' ')}';
  }
}
