import 'package:dart_core_orm/src/extensions/type_extension.dart';
import 'package:dart_core_orm/src/orm.dart';

import 'dude.dart';

Future main() async {
  Orm.initialize(
    database: 'postgres',
    username: 'postgres',
    password: '',
    host: 'localhost',
    family: DatabaseFamily.postgres,
    isSecureConnection: false,
  );

  // result = await conn.execute(
  //   r'INSERT INTO dudes (name) VALUES ($1), ($2), ($3)',
  //   parameters: ['John', 'Jane', 'Jack'],
  // );
  final dude = Dude()..name = 'John';

  // final result = await (Dude).select(['name']).execute();
  // final result = await (Dude).select().execute();
  final result = await (Dude).select().where([
    WhereOperation(
      key: 'name',
      value: 'John',
      operation: WhereOperationType.equal,
    ),
    WhereOperation(
      key: 'id',
      value: 1,
      operation: WhereOperationType.equal,
    ),
  ]).execute();
  print(result);
}
