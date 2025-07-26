import 'dart:async';

import 'package:grpc/src/server/call.dart';
import 'package:schat_api/data/db.dart';
import 'package:schat_api/data/user/user.dart';
import 'package:schat_api/generated/call.pbgrpc.dart';
import 'package:schat_api/utils.dart';
import 'package:uuid/uuid.dart';


class CallRpc extends CallRpcServiceBase {
  var uuid = Uuid();

Map<String, CallRoom> rooms = {};

  final StreamController<UpdateDTO> _streamControllerEvent =
      StreamController.broadcast();
  @override
  Future<ResponseDto> createGroupCall(ServiceCall call, UpdateDTO request) async{
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    request.room = uuid.v8();
    final String userAvatar = await Utils.getLincToFile(user!.imageAvatar, true);
    request.users.add(UserDto(username: user.username, imageAvatar: userAvatar));
    rooms[request.room] = CallRoom(request);
    _streamControllerEvent.add(request);
    return ResponseDto(message: request.room);
  }

 

  @override
  Future<ResponseDto> exitToRoom(ServiceCall call, RequestDto request) {
    throw UnimplementedError();
  }

  @override
  Stream<UpdateDTO> listenCall(ServiceCall call, RequestDto request) async*{
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    yield* _streamControllerEvent.stream.where((event)=> event.users
        .any((member) => member.username == user!.username));
  }
  
  @override
  Stream<UpdateDTO> enterToRoom(ServiceCall call, Stream<RequestDto> request)async* {
     final id = Utils.getIdFromMetadata(call);
     final user = await db.users.queryUser(id);
String roomId = '';


await for (RequestDto event in request) {
    roomId = event.room;
    event.room = user!.username;
   rooms[roomId]!.streamReq.add(event);
   yield  rooms[roomId]!.requestUsers[user.username];
  }
  }
  
}

class CallRoom
{
  final StreamController<RequestDto> streamReq=
      StreamController.broadcast();
final StreamController<UpdateDTO> streamResponse =
      StreamController.broadcast();

  CallRoom(UpdateDTO request)
  {
id = request.room;
for(var user in request.users)
{
  requestUsers[user.username] = UpdateDTO(users: [], video: video, exitCall: false, room: id, callData: CallDto(soundData: [], videoData: []));
}
video = request.video;
start();
  }
  bool video = false;
   late String id;
   Map requestUsers = {};
   List linkUsers = [];

   start()
   {
    
  streamResponse.stream.listen((event) {
    print(event.room);
    requestUsers.forEach((key, value) { 
      if(key!=event.room)
      {
        requestUsers[key] = event;
        }
    });});
   
    streamReq.stream.listen((event) {
      streamResponse.add(UpdateDTO(users: [], video: video, exitCall: false, room: event.room, callData: CallDto(soundData: event.callData.soundData, videoData: [])));  
      });
   }
  

   

}
