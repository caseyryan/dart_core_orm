import 'package:dart_core_orm/src/annotations/table_column_annotations.dart';

class Car {

  @PrimaryKeyColumn()
  @NotNullColumn()
  @UniqueColumn(autoIncrement: true)
  int? id;

  @LimitColumn(limit: 20)
  String? manufacturer;

  /// don't let the car be more powerful than 500 horsepower)
  @LimitColumn(limit: 300)
  int? enginePower;
}