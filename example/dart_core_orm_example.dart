import 'package:dart_core_orm/dart_core_orm.dart';
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
  final result = await (Dude).select().where([
    Equal(
      key: 'name',
      value: 'John',
    ),
    Between(
      key: 'id',
      value: [1, 5],
    ),
  ]).execute();
  print(result);
}
