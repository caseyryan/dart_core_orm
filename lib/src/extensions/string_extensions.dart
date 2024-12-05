import 'package:dart_core_orm/src/orm.dart';

extension StringExtensions on String {
  String sanitize() {
    DatabaseFamily? family = orm.family;
    if (family == null) {
      return this;
    }
    if (family == DatabaseFamily.postgres) {
      final result = replaceAll(RegExp('[\']{1}'), "''");
      if (result.contains('Heart')) {
        print(result);
      }
      return "'$result'";
    }
    return this;
  }
}
