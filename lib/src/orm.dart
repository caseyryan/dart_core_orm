import 'package:postgres/postgres.dart' as psql;

Orm? _orm;
Orm? get orm => _orm;

class Orm {
  Orm({
    required this.host,
    required this.database,
    required this.password,
    required this.username,
    required this.family,
    required this.isSecureConnection,
  }) {
    if (family == DatabaseFamily.postgres) {
      _endpoint = psql.Endpoint(
        host: host,
        database: database,
        username: username,
        password: password,
      );
      _settings = psql.ConnectionSettings(
        sslMode: isSecureConnection ? psql.SslMode.require : psql.SslMode.disable,
      );
    }
    _orm = this;
  }

  final String host;
  final String database;
  final String password;
  final String username;
  final DatabaseFamily family;
  final bool isSecureConnection;

  late final psql.Endpoint _endpoint;
  late final psql.ConnectionSettings? _settings;

  Future<psql.Connection> _createPostgresConnection() async {
    return psql.Connection.open(
      _endpoint,
      settings: _settings,
    );
  }

  Future<List<Map>> executeSimpleQuery({
    required String query,
    Duration? timeout,
  }) async {
    if (family == DatabaseFamily.postgres) {
      psql.Connection? conn;
      try {
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
                list.add(map);
              }
            }
          }
          return list;
        }
      } catch (_) {
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
