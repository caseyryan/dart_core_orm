/// Where operations
library;

import 'package:dart_core_orm/dart_core_orm.dart';

// TODO: add OR concatination 

class Equal extends WhereOperation {
  Equal({
    required super.key,
    required super.value,
    super.nextJoiner = Joiner.and,
  }) : super(
          operation: WhereOperationType.equal,
        );
}

class NotEqual extends WhereOperation {
  NotEqual({
    required super.key,
    required super.value,
    super.nextJoiner = Joiner.and,
  }) : super(
          operation: WhereOperationType.notEqual,
        );
}

class GreaterThan extends WhereOperation {
  GreaterThan({
    required super.key,
    required super.value,
    super.nextJoiner = Joiner.and,
  }) : super(
          operation: WhereOperationType.greater,
        );
}

class LessThan extends WhereOperation {
  LessThan({
    required super.key,
    required super.value,
    super.nextJoiner = Joiner.and,
  }) : super(
          operation: WhereOperationType.less,
        );
}

class GreaterThanOrEqual extends WhereOperation {
  GreaterThanOrEqual({
    required super.key,
    required super.value,
    super.nextJoiner = Joiner.and,
  }) : super(
          operation: WhereOperationType.greaterOrEqual,
        );
}

class LessThanOrEqual extends WhereOperation {
  LessThanOrEqual({
    required super.key,
    required super.value,
    super.nextJoiner = Joiner.and,
  }) : super(
          operation: WhereOperationType.lessOrEqual,
        );
}

class InList extends WhereOperation {
  InList({
    required super.key,
    required List<Object?> value,
    super.nextJoiner = Joiner.and,
  }) : super(
          operation: WhereOperationType.inList,
          value: value,
        );
}

class Between extends WhereOperation {
  Between({
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

class Like extends WhereOperation {
  Like({
    required super.key,
    required super.value,
    super.nextJoiner = Joiner.and,
  }) : super(
          operation: WhereOperationType.like,
        );
}

abstract class WhereOperation {
  WhereOperation({
    required this.key,
    this.value,
    required this.operation,
    required this.nextJoiner,
  });

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
    Object? valueRepresentation;

    /// Som operations like IS NULL, IS NOT NULL
    /// don't require a value to compare with
    if (operation.canUseValue) {
      if (value is String) {
        valueRepresentation = "'${(value as String).sanitize()}'";
      } else if (value is List) {
        final list = value as List;
        if (operation == WhereOperationType.between) {
          return '$key ${operation.operation} ${list.first} AND ${list.last}';
        }
        valueRepresentation = list.map((e) {
          if (e is String) {
            return "'${e.sanitize()}'";
          }
          return e;
        }).join(',');
        valueRepresentation = '($valueRepresentation)';
      } else {
        valueRepresentation = value;
      }
    } else {
      valueRepresentation = '';
    }
    return '$key ${operation.operation} $valueRepresentation'.trim();
  }
}

enum Joiner {
  and(' AND '),
  or(' OR ');

  const Joiner(this.value);
  final String value;
}

enum WhereOperationType {
  equal('='),
  notEqual('!='),
  less('<'),
  greater('>'),
  lessOrEqual('<='),
  greaterOrEqual('>='),
  inList('IN'),
  isNull('IS NULL', false),
  isNotNull('IS NOT NULL', false),
  between('BETWEEN'),
  like('LIKE');

  final String operation;
  final bool canUseValue;

  const WhereOperationType(
    this.operation, [
    this.canUseValue = true,
  ]);
}
