import 'package:dart_core_orm/dart_core_orm.dart';
import 'package:dart_core_orm/src/orm.dart';

import 'models.dart';

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

  // await createTable();

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
  // update();
  // select();
  // delete();
  // insertInstance();
  insertMany();
}

Future insertInstance() async {
  final car = Car()
    ..manufacturer = 'Bugatti'
    ..enginePower = 188;
  final result = await car
      .insert(
        conflictResolution: ConflictResolution.update,
      )
      .execute(
        dryRun: true,
        returnResult: true,
      );
  print(result);
}

Future insertMany() async {
  final author = Author()
    ..id = 7
    ..firstName = 'Mihail'
    ..lastName = 'Bulgakov';
  final values = [
    Book()
      ..author = author
      ..title = 'White Guard',
    Book()
      ..author = author
      ..title = 'Master and Margarita',
    Book()
      ..author = author
      // TODO: escape this
      ..title = "Dog's Heart",
  ];
  final record = ('Bob', 1);
  print(record.$1);

  final result = await (Book).insertMany(values).execute(
        dryRun: false,
        returnResult: true,
      );
  print(result);
}

Future createTable() async {
  await (Car).createTable(
    dryRun: false,
    ifNotExists: true,
  );
}

Future delete() async {
  final result = await (Car).delete().where([
    Equal(
      key: 'id',
      value: 1,
    ),
  ]).execute(
    returnResult: true,
    dryRun: false,
  );
  print(result);
}

Future select() async {
  final result = await (Car).select().where([
    Equal(
      key: 'id',
      value: 1,
      nextJoiner: Joiner.or,
    ),
    Equal(
      key: 'manufacturer',
      value: 'Toyota',
    ),
  ]).execute(
    returnResult: true,
    dryRun: false,
  );
  print(result);
}

Future update() async {
  final carUpdate = Car()
    ..manufacturer = 'Toyota'
    ..enginePower = 95;
  final result = await (Car).update(carUpdate).where([
    Equal(
      key: 'id',
      value: 7,
      nextJoiner: Joiner.or,
    ),
    Equal(
      key: 'manufacturer',
      value: 'Toyota',
    ),
  ]).execute(
    dryRun: false,
    returnResult: true,
  );

  print(result);
}
