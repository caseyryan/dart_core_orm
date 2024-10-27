import 'package:dart_core_orm/src/extensions/type_extension.dart';
import 'package:dart_core_orm/src/orm.dart';

import 'dude.dart';

Future main() async {
  // final conn = await Connection.open(
  //     Endpoint(
  //       host: 'localhost',
  //       database: 'postgres',
  //       username: 'postgres',
  //       password: '',
  //     ),
  //     settings: ConnectionSettings(
  //       sslMode: SslMode.disable,
  //     ));
  // var result = await conn.execute(
  //   'CREATE TABLE IF NOT EXISTS dudes (id SERIAL PRIMARY KEY, name TEXT)',
  //   queryMode: QueryMode.extended,
  // );
  // print(conn);
  Orm(
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
  final result = await (Dude).select().execute();
  print(result);

}
