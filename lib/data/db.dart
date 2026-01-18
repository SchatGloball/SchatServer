import 'package:schat_api/env.dart';
import 'package:stormberry/stormberry.dart';


late Connection db;

Future<Connection> initDatabase() async => await Connection.open(
      Endpoint(
        port: env.dbPort,
        password:  env.dbPass,
        username: env.dbUser,
        database: 'schat',
        host: env.dbHost,
      ),
      settings: ConnectionSettings(
        sslMode: SslMode.disable,
      ),
    );
