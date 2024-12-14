/// Where operations
library;

import 'package:dart_core_orm/dart_core_orm.dart';

// TODO: add OR concatination

class WhereEqual extends WhereOperation {
  WhereEqual({
    required super.key,
    required super.value,
    super.nextJoiner = Joiner.and,
  }) : super(
          operation: WhereOperationType.equal,
        );
}


class WhereNotEqual extends WhereOperation {
  WhereNotEqual({
    required super.key,
    required super.value,
    super.nextJoiner = Joiner.and,
  }) : super(
          operation: WhereOperationType.notEqual,
        );
}

class WhereGreaterThan extends WhereOperation {
  WhereGreaterThan({
    required super.key,
    required super.value,
    super.nextJoiner = Joiner.and,
  }) : super(
          operation: WhereOperationType.greater,
        );
}

class WhereLessThan extends WhereOperation {
  WhereLessThan({
    required super.key,
    required super.value,
    super.nextJoiner = Joiner.and,
  }) : super(
          operation: WhereOperationType.less,
        );
}

class WhereGreaterThanOrEqual extends WhereOperation {
  WhereGreaterThanOrEqual({
    required super.key,
    required super.value,
    super.nextJoiner = Joiner.and,
  }) : super(
          operation: WhereOperationType.greaterOrEqual,
        );
}

class WhereLessThanOrEqual extends WhereOperation {
  WhereLessThanOrEqual({
    required super.key,
    required super.value,
    super.nextJoiner = Joiner.and,
  }) : super(
          operation: WhereOperationType.lessOrEqual,
        );
}

class WhereInList extends WhereOperation {
  WhereInList({
    required super.key,
    required List<Object?> value,
    super.nextJoiner = Joiner.and,
  }) : super(
          operation: WhereOperationType.inList,
          value: value,
        );
}

class WhereBetween extends WhereOperation {
  WhereBetween({
    required super.key,
    required List<Object> value,
  })  : assert(
          value.length == 2,
          'Between operation requires two values',
        ),
        super(
          operation: WhereOperationType.between,
          value: value,
          nextJoiner: Joiner.and,
        );
}

class WhereLike extends WhereOperation {
  WhereLike({
    required super.key,
    required super.value,
    super.nextJoiner = Joiner.and,
  }) : super(
          operation: WhereOperationType.like,
        );
}

abstract class WhereOperation {
  WhereOperation({
    required String key,
    this.value,
    required this.operation,
    required this.nextJoiner,
  }) : key = key.wrapInDoubleQuotesIfNeeded();

  /// column name
  final String key;

  /// the value to compare with
  final Object? value;
  final WhereOperationType operation;

  /// [nextJoiner] is used to specify how to join the operations
  /// e.g. if you want to use OR instead of AND
  /// it will have effect if you provide more than one operation
  final Joiner nextJoiner;

  String toOperation() {
    if (orm.family == DatabaseFamily.postgres) {
      Object? valueRepresentation;

      /// Som operations like IS NULL, IS NOT NULL
      /// don't require a value to compare with
      if (operation.canUseValue) {
        if (value is List) {
          final list = value as List;
          if (operation == WhereOperationType.between) {
            return '$key ${operation.toDatabaseWhereOperation()} ${list.first} AND ${list.last}';
          }
          valueRepresentation = list.map((e) {
            // if (e is String) {
            //   return e.sanitize();
            // }
            return (e as Object).tryConvertValueToDatabaseCompatible();
          }).join(',');
          valueRepresentation = '($valueRepresentation)';
        } else {
          valueRepresentation =
              (value as Object).tryConvertValueToDatabaseCompatible();
        }
      } else {
        valueRepresentation = '';
      }
      return '$key ${operation.toDatabaseWhereOperation()} $valueRepresentation'
          .trim();
    }
    throw databaseFamilyNotSupportedYet();
  }
}

enum Joiner {
  and,
  or;

  const Joiner();

  String toDatabaseOperation() {
    if (orm.family == DatabaseFamily.postgres) {
      switch (this) {
        case Joiner.and:
          return 'AND';
        case Joiner.or:
          return 'OR';
      }
    }
    return '';
  }
}

enum WhereOperationType {
  equal,
  notEqual,
  less,
  greater,
  lessOrEqual,
  greaterOrEqual,
  inList,
  isNull(false),
  isNotNull(false),
  between,
  all,
  like;

  final bool canUseValue;

  String toDatabaseWhereOperation() {
    if (orm.family == DatabaseFamily.postgres) {
      switch (this) {
        case WhereOperationType.all:
          return '*';
        case WhereOperationType.equal:
          return '=';
        case WhereOperationType.notEqual:
          return '!=';
        case WhereOperationType.less:
          return '<';
        case WhereOperationType.greater:
          return '>';
        case WhereOperationType.lessOrEqual:
          return '<=';
        case WhereOperationType.greaterOrEqual:
          return '>=';
        case WhereOperationType.like:
          return 'LIKE';
        case WhereOperationType.between:
          return 'BETWEEN';
        case WhereOperationType.inList:
          return 'IN';
        case WhereOperationType.isNull:
          return 'IS NULL';
        case WhereOperationType.isNotNull:
          return 'IS NOT NULL';
      }
    }
    throw databaseFamilyNotSupportedYet();
  }

  const WhereOperationType([
    this.canUseValue = true,
  ]);
}
