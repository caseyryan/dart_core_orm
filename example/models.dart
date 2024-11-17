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

@CamelToSnake()
class Book {
  @PrimaryKeyColumn()
  @NotNullColumn()
  @UniqueColumn(autoIncrement: true)
  int? id;

  String? title;

  /// This foreign key will actually transform the field in the database
  /// in this case [author] will be transformed into [author_id] 
  /// (by using (Author).toTableName(plural: false) + '_${fieldName}')
  /// IMPORTANT: any foreign keys inside a model automatically transform 
  /// a simple query to a transaction (where it's possible, not any database supports it)
  /// to make sure everything is inserted correctly
  /// before inserting the main model
  @ForeignKeyColumn(
    foreignKey: 'id', // turns `author` to `author_id` in this case
    referenceTableType: Author,
    cascade: true,
  )
  Author? author;
}

@CamelToSnake()
class Author {
  @PrimaryKeyColumn()
  @NotNullColumn()
  @UniqueColumn(autoIncrement: true)
  int? id;

  String? firstName;
  String? lastName;
}


class Reader {
  @DefaultId()
  int? id;

  @NotNullColumn(defaultValue: 'John Doe')
  String? fullName;
}