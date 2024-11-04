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
  /// the foreign hame of the column in other table 
  /// that this field is referencing
  /// e.g. you add a foreign key column to a table on an
  /// [authorId] field and you want to reference the [id] field
  /// of the [Author] table
  final String foreignKey;
  
  /// The type of the table you want to reference. 
  final Type referenceTableType;

  const ForeignKeyColumn({
    required this.foreignKey,
    required this.referenceTableType,
  });

  @override
  String getValueForType(
    Type type,
    String fieldName,
  ) {
    return 'FOREIGN KEY ($fieldName) REFERENCES ${referenceTableType.toTableName()}($foreignKey)';
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
  const NotNullColumn();

  @override
  String getValueForType(
    Type type,
    String fieldName,
  ) {
    if (orm?.family == DatabaseFamily.postgres) {
      return 'NOT NULL';
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
