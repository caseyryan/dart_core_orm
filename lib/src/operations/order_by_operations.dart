import 'package:dart_core_orm/src/exports.dart';

class OrderByOperation {
  OrderByOperation({
    required this.byFieldNames,
    this.direction = OrderByDirection.asc,
  }) : assert(
          byFieldNames.isNotEmpty,
          'You must provide at least one field to order by',
        );

  /// [byFieldNames] is a list of fields to order by
  /// e.g. ['name', 'age'] will order by name and then by age
  /// it must contain at least one field to order by
  /// [direction] is used to specify the direction of the ordering
  final List<String> byFieldNames;
  final OrderByDirection direction;

  String toDatabaseOperation() {
    if (orm.family == DatabaseFamily.postgres) {
      return 'ORDER BY ${byFieldNames.join(', ')} ${direction.toDatabaseOperation()}';
    }
    throw databaseFamilyNotSupportedYet();
  }
}

enum OrderByDirection {
  asc,
  desc;

  String toDatabaseOperation() {
    if (orm.family == DatabaseFamily.postgres) {
      switch (this) {
        case OrderByDirection.asc:
          return 'ASC';
        case OrderByDirection.desc:
          return 'DESC';
      }
    }
    return '';
  }
}
