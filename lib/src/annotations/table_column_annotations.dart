import 'package:dart_core_orm/src/orm.dart';

abstract class TableColumnAnnotation {
  const TableColumnAnnotation();

  String getValueForType(
    Type type, 
    String fieldName,
  );
  int get order;
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
      return 0;
    }
    return 0;
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
      return 0;
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
        return 'SERIAL UNIQUE';
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
