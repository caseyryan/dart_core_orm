import 'package:dart_core_orm/dart_core_orm.dart';
import 'package:dart_core_orm/src/orm.dart';

import 'car.dart';

Future main() async {
  Orm.initialize(
    database: 'postgres',
    username: 'postgres',
    password: '',
    host: 'localhost',
    family: DatabaseFamily.postgres,
    isSecureConnection: false,
    printQueries: true,
  );

  // result = await conn.execute(
  //   r'INSERT INTO dudes (name) VALUES ($1), ($2), ($3)',
  //   parameters: ['John', 'Jane', 'Jack'],
  // );
  // final dude = Dude()..name = 'Chester';

  // final dropResult = await (Car).dropTable(
  //   dryRun: false,
  //   ifExists: true,
  //   cascade: true,
  // );
  final createResult = await (Car).createTable(
    dryRun: false,
  );
  // print(createResult);
  // print(dropResult);
  // return;

  // final result = await (Car).select(['name']).execute();
  // final result = await (Dude).select().where([
  //   Equal(
  //     key: 'name',
  //     value: 'John',
  //   ),
  //   Between(
  //     key: 'id',
  //     value: [1, 5],
  //   ),
  // ]).toListAsync();
  // print(result);

  // final car = Car()
  //   ..id = 7
  //   ..manufacturer = 'Lada'
  //   ..enginePower = 120;
  // final result = await car
  //     .insert(
  //       conflictResolution: ConflictResolution.update,
  //     )
  //     .execute(dryRun: false);
  final carUpdate = Car()
    ..manufacturer = 'Toyota'
    ..enginePower = 95;
  (Car).update(carUpdate).where([
    Equal(
      key: 'id',
      value: 7,
      nextJoiner: Joiner.or,
    ),
    Equal(
      key: 'manufacturer',
      value: 'Toyota',
    ),
  ]).execute(dryRun: false);

  // print(result);
}
