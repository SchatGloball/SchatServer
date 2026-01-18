import 'dart:async';
import 'package:grpc/grpc.dart';
import 'package:schat_api/data/db.dart';
import 'package:schat_api/data/grpc_interceptors.dart';
import 'package:schat_api/domain/auth_rpc.dart';
import 'package:schat_api/domain/calls_rpc.dart';
import 'package:schat_api/domain/chats_rpc.dart';
import 'package:schat_api/domain/logService.dart';
import 'package:schat_api/domain/social_rpc.dart';
import 'package:schat_api/env.dart';



Future<void> startServer() async {
  runZonedGuarded(() async {
    final serverAPI = Server.create(services: [
      AuthRpc(),
      ChatRpc(),
      SocialRpc(),
      CallRpc()
    ], interceptors: [
      GrpcInterceptors.tokenInterceptor,
    ], 
    codecRegistry: CodecRegistry(codecs: [GzipCodec()]), 
    keepAliveOptions: ServerKeepAliveOptions(
      minIntervalBetweenPingsWithoutData: Duration(seconds: 30),
      maxBadPings: 3
    ),
   errorHandler: (error, trace) => createNewLog(error.toString() + trace.toString(), 0, true)
    );
    await serverAPI.serve(port: env.port, 
    backlog: 128,
        shared: false,  
        );
    print("server started");
    try {
      await Future.delayed(Duration(seconds: 10));
      print(env.dbPort);
      print(env.dbHost);
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
