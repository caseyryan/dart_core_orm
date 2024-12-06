import 'package:dart_core_orm/src/orm.dart';

extension StringExtensions on String {
  String sanitize() {
    DatabaseFamily? family = orm.family;
    if (family == DatabaseFamily.postgres) {
      final result = replaceAll(RegExp('[\']{1}'), "''");
      if (result.contains('Heart')) {
        print(result);
      }
      return "'$result'";
    }
    return this;
  }

  /// in some databases like PostgreSQL
  /// the names of tables and columns are lowercase by default.
  /// This method will add double quotes around the string
  /// if the database is PostgreSQL and the names are not already
  /// wrapped in double quotes
  /// This will make them case sensitive
  String wrapInDoubleQuotesIfNeeded() {
    if (orm.useCaseSensitiveNames) {
      if (orm.family == DatabaseFamily.postgres) {
        if (!startsWith('"') && !endsWith('"')) {
          return '"$this"';
        }
      }
    }
    return this;
  }
}
