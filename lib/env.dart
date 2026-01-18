import 'dart:io';

class Env {
  final String sk =  Platform.environment['DB_SK'] ??'*************************';  
final  int accessTokenLife = 500;
   final int refreshTokenLife = 1000;
  final String dbHost = Platform.environment['DB_HOST_ADDRESS'] ?? 'localhost';
  final int dbPort =
      int.parse(Platform.environment['DB_PORT'] ?? '5432'.toString());
  final String dbUser = Platform.environment['DB_USERNAME'] ?? '***********';
  final String dbPass = Platform.environment['DB_PASSWORD'] ?? '***********';

  final int port = int.parse(Platform.environment['PORT'] ?? '4700');

  final int storagePort = 9000;
  final String minioLogin =
      Platform.environment['MINIO_ROOT_USER'] ?? '******************';
  final String minioPassword =
      Platform.environment['MINIO_ROOT_PASSWORD'] ?? '******************';
  final String storageHost = Platform.environment['STORAGEHOST'] ?? '0.0.0.0';
  final String chatsBucket = 'userchats';
  final String usersBucket = 'useravatars';
  final int version = 2;
    final int logLevel =  int.parse(Platform.environment['LOGLEVEL'] ?? '0');
  final int maxLogString =  int.parse(Platform.environment['MAXLOGSTRING'] ?? '1024');
}
final Env env = Env();