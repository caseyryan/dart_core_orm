import 'package:dart_core_orm/dart_core_orm.dart';
import 'package:dart_core_orm/src/orm.dart';

import 'models.dart';

Future main() async {
  /// if there is no custom database yet, you can connect to the 
  /// postgres database (with the password you have created on first launch, in this case 'default_pwd')
  /// and after the database is initialized create your own database with the name 
  /// credentials, and user access you need
  Orm.initialize(
    database: 'default_db',
    username: 'default_db_user',
    password: 'default_pwd',
    host: 'localhost',
    family: DatabaseFamily.postgres,
    isSecureConnection: false,
    printQueries: true,
    port: 5455,
  );
  await (Car).createTable(
    dryRun: false,
    ifNotExists: true,
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
  // insertManyBooks();
  // selectBooks();
  // createTableWithDefaultId();
}

Future createTableWithDefaultId() async {
  await (Reader).createTable(
    dryRun: false,
    ifNotExists: true,
  );
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

Future insertManyBooks() async {
  final author = Author()
    ..id = 7
    ..firstName = 'Mihail'
    ..lastName = 'Bulgakov';
  final values = [
    //   Book()
    //     ..author = author
    //     ..title = 'White Guard',
    //   Book()
    //     ..author = author
    //     ..title = 'Master and Margarita',
    Book()
      ..author = author
      ..title = "Dog's Heart and cat's liver",
  ];

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

Future selectBooks() async {
  final result = await (Book).select().execute(
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
