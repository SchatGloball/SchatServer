import 'package:schat_api/env.dart';
import 'package:stormberry/stormberry.dart';


late Connection db;

Future<Connection> initDatabase() async => await Connection.open(
      Endpoint(
        port: Env().dbPort,
        password:  Env().dbPass,
        username: Env().dbUser,
        database: 'schat',
        host: Env().dbHost,
      ),
      settings: ConnectionSettings(
        sslMode: SslMode.disable,
      ),
    );
