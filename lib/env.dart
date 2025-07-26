import 'dart:io';

class Env {
  final String sk =  Platform.environment['DB_SK'] ??'*************************';  
  static const int accessTokenLife = 5;
  static const int refreshTokenLife = 10;
  final String dbHost = Platform.environment['DB_HOST_ADDRESS'] ?? 'localhost';
  final int dbPort =
      int.parse(Platform.environment['DB_PORT'] ?? '5432'.toString());
  final String dbUser = Platform.environment['DB_USERNAME'] ?? '***********';
  final String dbPass = Platform.environment['DB_PASSWORD'] ?? '***********';

  final int port = int.parse(Platform.environment['PORT'] ?? '4700');

  static const int storagePort = 9000;
  final String minioLogin =
      Platform.environment['MINIO_ROOT_USER'] ?? '******************';
  final String minioPassword =
      Platform.environment['MINIO_ROOT_PASSWORD'] ?? '******************';
  final String storageHost = Platform.environment['STORAGEHOST'] ?? '0.0.0.0';
  static const String chatsBucket = 'userchats';
  static const String usersBucket = 'useravatars';
  static const int version = 1;
}
