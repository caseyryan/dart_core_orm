import 'package:dart_core_orm/dart_core_orm.dart';

abstract class TableColumnAnnotation {
  const TableColumnAnnotation();

  /// [alternativeParams] sometimes you might not be happy with
  /// what the ORM adds by default to the column description.
  /// In this case you can provide your own params.
  /// They will override all default stuff
  /// e.g. updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
  String getValueForType(
    Type type,
    String fieldName, {
    String? alternativeParams,
  });
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
    String fieldName, {
    String? alternativeParams,
  }) {
    assert(alternativeParams == null,
        'alternativeParams is not supported for this annotation');
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
    String fieldName, {
    String? alternativeParams,
  }) {
    if (alternativeParams != null) {
      return alternativeParams;
    }
    if (type != int && type != String && type != bool && type != DateTime) {
      return '';
    }
    if (orm.family == DatabaseFamily.postgres) {
      return 'PRIMARY KEY';
    }
    return '';
  }

  @override
  int get order {
    if (orm.family == DatabaseFamily.postgres) {
      return 10;
    }
    return 10;
  }
}

enum DateType {
  date,
  time,
  timestamp,
  timestampWithZone;

  String toDatabaseType(DateTimeDefaultValue defaultValue,) {
    if (orm.family == DatabaseFamily.postgres) {
      switch (this) {
        case DateType.date:
          return 'DATE${defaultValue.toDatabaseType()}';
        case DateType.time:
          return 'TIME${defaultValue.toDatabaseType()}';
        case DateType.timestamp:
          return 'TIMESTAMP WITHOUT TIME ZONE${defaultValue.toDatabaseType()}';
        case DateType.timestampWithZone:
          return 'TIMESTAMP WITH TIME ZONE${defaultValue.toDatabaseType()}';
      }
    }
    throw Exception('${orm.family} is not supported');
  }
}

enum DateTimeDefaultValue {
  currentDate,
  currentTime,
  currentTimestamp,
  localTimestamp,
  empty;

  String toDatabaseType() {
    if (orm.family  == DatabaseFamily.postgres) {
      switch (this) {
        case DateTimeDefaultValue.currentDate:
          return ' DEFAULT CURRENT_DATE';
        case DateTimeDefaultValue.currentTime:
          return ' DEFAULT CURRENT_TIME';
        case DateTimeDefaultValue.currentTimestamp:
          return ' DEFAULT CURRENT_TIMESTAMP';
        case DateTimeDefaultValue.localTimestamp:
          return ' DEFAULT LOCALTIMESTAMP';
        case DateTimeDefaultValue.empty:
          return '';
      }
    }
    throw Exception('${orm.family} is not supported');
  }
}

class DateColumn extends TableColumnAnnotation {
  const DateColumn({
    this.defaultValue = DateTimeDefaultValue.empty,
    required this.dateType,
  });   
  final DateTimeDefaultValue defaultValue; 
  final DateType dateType;

  @override
  String getValueForType(
    Type type,
    String fieldName, {
    String? alternativeParams,
  }) {
    if (type != DateTime) {
      throw Exception('`DateColumn` can be used with `DateTime` type only. [$type] is not supported');
    }
    if (alternativeParams != null) {
      return alternativeParams;
    }
    if (orm.family == DatabaseFamily.postgres) {
      return dateType.toDatabaseType(defaultValue);
    }
    return '';
  } 
  @override
  int get order {
    if (orm.family == DatabaseFamily.postgres) {
      return 0;
    }
    return 0;
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
    String fieldName, {
    String? alternativeParams,
  }) {
    if (alternativeParams != null) {
      return alternativeParams;
    }
    if (orm.family == DatabaseFamily.postgres) {
      if (type == DateTime) {
        print('You used `NotNullColumn` on a `DateTime` field in $type. To have more flexibility use `DateColumn` anotation instead');
        return ' TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP';
      }
      var defaultsTo = '';
      if (defaultValue != null) {
        if (defaultValue is String) {
          defaultsTo = " DEFAULT '$defaultValue'";
        } 
        else if (defaultValue is bool) {
          defaultsTo = " DEFAULT ${defaultValue.toString().toUpperCase()}";
        }
        else {
          defaultsTo = ' DEFAULT $defaultValue';
        }
      }
      return 'NOT NULL$defaultsTo';
    }
    return '';
  }

  @override
  int get order {
    if (orm.family == DatabaseFamily.postgres) {
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
    String fieldName, {
    String? alternativeParams,
  }) {
    if (alternativeParams != null) {
      return alternativeParams;
    }
    if (orm.family == DatabaseFamily.postgres) {
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
    if (orm.family == DatabaseFamily.postgres) {
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
    String fieldName, {
    String? alternativeParams,
  }) {
    assert(alternativeParams == null,
        'alternativeParams is not supported for this annotation');
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
    String fieldName, {
    String? alternativeParams,
  }) {
    if (alternativeParams != null) {
      return alternativeParams;
    }
    if (orm.family == DatabaseFamily.postgres) {
      if (autoIncrement && type == int) {
        return 'SERIAL';
      }
      return 'UNIQUE';
    }
    return '';
  }

  @override
  int get order {
    if (orm.family == DatabaseFamily.postgres) {
      return 0;
    }
    return 0;
  }
}
