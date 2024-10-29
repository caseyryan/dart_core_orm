import 'package:dart_core_orm/src/annotations/table_column_annotations.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

/// The annotation comes from the [reflect_buddy] package
/// it is used to convert all field names to snake case
/// e.g. enginePower will be converted to engine_power and the
/// database column name will also be snake cased
@CamelToSnake()
class Car {
  @PrimaryKeyColumn()
  @NotNullColumn()
  @UniqueColumn(autoIncrement: true)
  int? id;

  @LimitColumn(limit: 20)
  String? manufacturer;

  /// don't let the car be more powerful than 300 horsepower)
  @LimitColumn(limit: 300)
  int? enginePower;
}
