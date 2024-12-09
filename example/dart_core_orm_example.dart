import 'package:dart_core_orm/dart_core_orm.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

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
    // дописать оборачивание в двойные кавычки для postgres
    useCaseSensitiveNames: false,
  );
  alwaysIncludeParentFields = true;
  customGlobalKeyNameConverter = CamelToSnake();

  // await (User).alterTable(dryRun: false);

  // await (User).createTable(
  //   dryRun: true,

  //   /// In this case it will create a trigger that will
  //   /// set updatedAt field to the current timestamp
  //   /// when a row is inserted or updated
  //   createTriggerCode: createUpdatedAtTriggerCode(
  //     tableName: (User).toTableName(),
  //     columnName: 'updated_at',
  //   ),
  // );

  // return;

  final user = User()
    ..firstName = 'Sifon'
    ..phone = '+79909090909'
    ..isDeleted = false
    ..birthDate = DateTime.now()
    ..lastName = 'Pupkin'
    ..roles = [Role.editor, Role.user]
    ..email = 'sifa@dormoed.com';
  final queryResult = await user.tryInsertOne<User>(
    dryRun: false,
    conflictResolution: ConflictResolution.update,
  );

  // final queryResult = await user.tryFind<User>();
  print(queryResult.value);

  // final result = await user.insert().execute(
  //   final result = await user.upsert().execute(
  //   dryRun: false,
  //   returnResult: true,
  // );
  // print(result);
  // if (queryResult.isError) {
  //   if (queryResult.error!.isTableNotExists) {
  //     await (User).createTable(
  //       dryRun: false,

  //       /// In this case it will create a trigger that will
  //       /// set updatedAt field to the current timestamp
  //       /// when a row is inserted or updated
  //       createTriggerCode: createUpdatedAtTriggerCode(
  //         tableName: (User).toTableName(),
  //         columnName: 'updatedAt',
  //       ),
  //     );
  // final result = await user.upsert().execute(
  //       dryRun: false,
  //       returnResult: true,
  //     );
  // print(result);
  // }
  // }

  // await (User).createTable(dryRun: true);
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
