import 'dart:async';
import 'package:grpc/grpc.dart';
import 'package:schat_api/data/db.dart';
import 'package:schat_api/data/grpc_interceptors.dart';
import 'package:schat_api/data/migration.dart';
import 'package:schat_api/data/minio_storage.dart';
import 'package:schat_api/domain/auth_rpc.dart';
import 'package:schat_api/domain/calls_rpc.dart';
import 'package:schat_api/domain/chats_rpc.dart';
import 'package:schat_api/domain/social_rpc.dart';
import 'package:schat_api/env.dart';



Future<void> startServer() async {
  runZonedGuarded(() async {
    final serverAPI = Server([
      AuthRpc(),
      ChatRpc(),
      SocialRpc(),
      CallRpc()
    ], <Interceptor>[
      GrpcInterceptors.tokenInterceptor,
    ], CodecRegistry(codecs: [GzipCodec()]));
    await serverAPI.serve(port: Env().port);
    print("server started");
    try {
      await Future.delayed(Duration(seconds: 10));
      print(Env().dbPort);
      print(Env().dbHost);
      db = await initDatabase();
      //    await startMigration();
    } catch (e) {
      print(e.toString());
      print('errooooooooooooooooooooor');
    }
  }, (error, stack) {
    print(error);
    //log("Error", error: error);
  });
}
