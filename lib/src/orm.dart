import 'package:postgres/postgres.dart' as psql;

Orm? _orm;
Orm get orm => _orm!;

class Orm {
  Orm._({
    required this.host,
    required this.database,
    required this.password,
    required this.username,
    required this.family,
    required this.isSecureConnection,
    required this.printQueries,
    this.port = 5432,
  }) {
    if (family == DatabaseFamily.postgres) {
      _endpoint = psql.Endpoint(
        host: host,
        database: database,
        username: username,
        password: password,
        port: port,
      );
      _settings = psql.ConnectionSettings(
        sslMode:
            isSecureConnection ? psql.SslMode.require : psql.SslMode.disable,
      );
    }
    _orm = this;
  }

  factory Orm.initialize({
    required String host,
    required String database,
    required String password,
    required String username,
    int port = 5432,
    required DatabaseFamily family,
    required bool isSecureConnection,
    bool printQueries = false,
  }) {
    return Orm._(
      host: host,
      database: database,
      password: password,
      username: username,
      family: family,
      isSecureConnection: isSecureConnection,
      printQueries: printQueries,
      port: port,
    );
  }

  final String host;
  final int port;
  final String database;
  final String password;
  final String username;
  final DatabaseFamily family;
  final bool isSecureConnection;

  /// if true, it will print all executing queries
  final bool printQueries;

  late final psql.Endpoint _endpoint;
  late final psql.ConnectionSettings? _settings;

  Future<psql.Connection> _createPostgresConnection() async {
    return psql.Connection.open(
      _endpoint,
      settings: _settings,
    );
  }

  Future createDatabase({
    required String database,
    bool dryRun = false,
    Duration? timeout,
  }) async {
    if (family == DatabaseFamily.postgres) {
      /// is the table exists it will generate an error but it can be ignored
      await executeSimpleQuery(
        query: 'CREATE DATABASE $database;',
        timeout: timeout,
        dryRun: dryRun,
      );
    }
  }

  Future<Object?> executeSimpleQuery({
    required String query,
    Duration? timeout,
    bool dryRun = false,
  }) async {
    if (family == DatabaseFamily.postgres) {
      psql.Connection? conn;
      try {
        if (orm?.printQueries == true) {
          if (dryRun) {
            print('(DRY RUN)>> $query');
          } else {
            print(query);
          }
        }
        if (dryRun) {
          return [];
        }
        conn = await _createPostgresConnection();
        final result = await conn.execute(
          query,
          timeout: timeout,
          queryMode: psql.QueryMode.simple,
          ignoreRows: false,
          parameters: null,
        );
        if (result.isNotEmpty) {
          final list = <Map>[];
          final keys = result.schema.columns.map((e) => e.columnName).toList();
          for (var i = 0; i < result.length; i++) {
            final psql.ResultRow row = result[i];
            if (row.length == keys.length) {
              final map = {};
              for (var j = 0; j < row.length; j++) {
                map[keys[j]] = row[j];
              }
              list.add(map);
            }
          }
          return list;
        }
      } on psql.ServerException catch (e) {
        print(e);
        return [
          e.message,
        ];
      } catch (e) {
        print(e);
      } finally {
        await conn?.close();
      }
    }
    return [];
  }
}

enum DatabaseFamily {
  postgres,
}
