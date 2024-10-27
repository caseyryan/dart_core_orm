
/// Where operations
library;

class Equal extends WhereOperation {
  Equal({
    required super.key,
    required super.value,
  }) : super(
          operation: WhereOperationType.equal,
        );
}

class NotEqual extends WhereOperation {
  NotEqual({
    required super.key,
    required super.value,
  }) : super(
          operation: WhereOperationType.notEqual,
        );
}

class GreaterThan extends WhereOperation {
  GreaterThan({
    required super.key,
    required super.value,
  }) : super(
          operation: WhereOperationType.greater,
        );
}

class LessThan extends WhereOperation {
  LessThan({
    required super.key,
    required super.value,
  }) : super(
          operation: WhereOperationType.less,
        );
}

class GreaterThanOrEqual extends WhereOperation {
  GreaterThanOrEqual({
    required super.key,
    required super.value,
  }) : super(
          operation: WhereOperationType.greaterOrEqual,
        );
}

class LessThanOrEqual extends WhereOperation {
  LessThanOrEqual({
    required super.key,
    required super.value,
  }) : super(
          operation: WhereOperationType.lessOrEqual,
        );
}

class InList extends WhereOperation {
  InList({
    required super.key,
    required List<Object?> value,
  }) : super(operation: WhereOperationType.inList, value: value);
}

class Between extends WhereOperation {
  Between({
    required super.key,
    required List<Object> value,
  }) : super(
          operation: WhereOperationType.between,
          value: value,
        );
}

class Like extends WhereOperation {
  Like({
    required super.key,
    required super.value,
  }) : super(
          operation: WhereOperationType.like,
        );
}

abstract class WhereOperation {
  WhereOperation({
    required this.key,
    this.value,
    required this.operation,
  });

  /// column name
  final String key;

  /// the value to compare with
  final Object? value;
  final WhereOperationType operation;

  String toOperation() {
    Object? valueRepresentation;

    /// Som operations like IS NULL, IS NOT NULL
    /// don't require a value to compare with
    if (operation.canUseValue) {
      if (value is String) {
        valueRepresentation = "'$value'";
      } else if (value is List) {
        final list = value as List;
        if (operation == WhereOperationType.between) {
          return '$key ${operation.operation} ${list.first} AND ${list.last}';
        }
        valueRepresentation = list.map((e) {
          if (e is String) {
            return "'$e'";
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
