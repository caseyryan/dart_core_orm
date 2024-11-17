import 'package:dart_core_orm/dart_core_orm.dart';
import 'package:dart_core_orm/src/orm.dart';

abstract class TableColumnAnnotation {
  const TableColumnAnnotation();

  String getValueForType(
    Type type,
    String fieldName,
  );
  int get order;
}

class ForeignKeyColumn extends TableColumnAnnotation {
  /// the hame of the column in other table
  /// that this field is referencing
  /// e.g. you add a foreign key column to a table on an
  /// [author] field and you want to reference the [id] field
  /// of the [Author] table. When making a query it will convert the
  /// field name (`author` in this example, to `author_id` or `authorId`) because
  /// the table is `(Author).toTableName(plural: false) -> author` (NOT pluralized) + `_id` or `Id` if the foreign model
  /// does not require snake case conversion
  final String foreignKey;

  /// [referenceTableType] The type of the table you want to reference. E.g. `Author`
  /// if will automatically convert the object to a foreign key to the `authors` table.
  /// See [foreignKey] field description for details
  final Type referenceTableType;

  const ForeignKeyColumn({
    required this.foreignKey,
    required this.referenceTableType,
    this.cascade = true,
  });

  /// [cascade] indicates whether the delete operation
  /// should be cascaded to the referenced table. Basically
  /// it will add ` ON DELETE CASCADE` to the end of the query
  final bool cascade;

  @override
  String getValueForType(
    Type type,
    String fieldName,
  ) {
    final commandOnDelete = cascade ? ' ON DELETE CASCADE' : '';
    return ', FOREIGN KEY ($fieldName) REFERENCES ${referenceTableType.toTableName()}($foreignKey)$commandOnDelete';
  }

  @override
  int get order => 0;
}

class PrimaryKeyColumn extends TableColumnAnnotation {
  const PrimaryKeyColumn();

  @override
  String getValueForType(
    Type type,
    String fieldName,
  ) {
    if (type != int && type != String && type != bool && type != DateTime) {
      return '';
    }
    if (orm?.family == DatabaseFamily.postgres) {
      return 'PRIMARY KEY';
    }
    return '';
  }

  @override
  int get order {
    if (orm?.family == DatabaseFamily.postgres) {
      return 10;
    }
    return 10;
  }
}

class NotNullColumn extends TableColumnAnnotation {
  const NotNullColumn({
    this.defaultValue,
  });

  final Object? defaultValue;

  @override
  String getValueForType(
    Type type,
    String fieldName,
  ) {
    if (orm?.family == DatabaseFamily.postgres) {
      var defaultsTo = '';
      if (defaultValue != null) {
        if (defaultValue is String) {
          defaultsTo = " DEFAULT '$defaultValue'";
        } else {
          defaultsTo = ' DEFAULT $defaultValue';
        }
      }
      return 'NOT NULL$defaultsTo';
    }
    return '';
  }

  @override
  int get order {
    if (orm?.family == DatabaseFamily.postgres) {
      return 0;
    }
    return 0;
  }
}

/// can limit strings and integers
class LimitColumn extends TableColumnAnnotation {
  final int limit;

  const LimitColumn({
    required this.limit,
  });

  @override
  String getValueForType(
    Type type,
    String fieldName,
  ) {
    if (orm?.family == DatabaseFamily.postgres) {
      if (type == String) {
        return 'VARCHAR($limit)';
      }
      if (type == int) {
        return 'INTEGER CHECK ($fieldName <= $limit)';
      }
    }
    return '';
  }

  @override
  int get order {
    if (orm?.family == DatabaseFamily.postgres) {
      return 1;
    }
    return 0;
  }
}

/// This is just a syntactic sugar for the id field
/// What it will do is add 3 other annotations like this
/// instead of itself
// @PrimaryKeyColumn()
// @NotNullColumn()
// @UniqueColumn(autoIncrement: true)
class DefaultId extends TableColumnAnnotation {
  const DefaultId();

  @override
  String getValueForType(
    Type type,
    String fieldName,
  ) {
    return '';
  }

  @override
  int get order {
    return 0;
  }
}

class UniqueColumn extends TableColumnAnnotation {
  final bool autoIncrement;

  const UniqueColumn({
    this.autoIncrement = false,
  });

  @override
  String getValueForType(
    Type type,
    String fieldName,
  ) {
    if (orm?.family == DatabaseFamily.postgres) {
      if (autoIncrement && type == int) {
        return 'SERIAL';
      }
      return 'UNIQUE';
    }
    return '';
  }

  @override
  int get order {
    if (orm?.family == DatabaseFamily.postgres) {
      return 0;
    }
    return 0;
  }
}
