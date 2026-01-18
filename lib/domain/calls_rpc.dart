import 'dart:async';
import 'dart:collection';

import 'package:grpc/src/server/call.dart';
import 'package:schat_api/data/chat/chat.dart';
import 'package:schat_api/data/db.dart';
import 'package:schat_api/data/message/message.dart';
import 'package:schat_api/data/user/user.dart';
import 'package:schat_api/generated/call.pbgrpc.dart';
import 'package:schat_api/utils.dart';
import 'package:stormberry/stormberry.dart';
import 'package:uuid/uuid.dart';


class CallRpc extends CallRpcServiceBase {

  final Uuid uuid = Uuid();

Map<String, CallRoom> rooms = {};
  final StreamController<UpdateDTO> _streamControllerEvent =
      StreamController.broadcast();
  @override
  Future<ResponseDto> createGroupCall(ServiceCall call, UpdateDTO request) async{
 final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
String roomName = uuid.v8();

//проверка на существующий звонок
bool checkExistCall = false;

rooms.forEach((key, value)async{
 if(value.requestUsers.containsKey(request.users.first.username)&&value.requestUsers.containsKey(user!.username)) 
  {
      final String userAvatar = await Utils.getLincToFile(user.imageAvatar, true);
    request.users.add(UserDto(username: user.username, imageAvatar: userAvatar));
    _streamControllerEvent.add(request);
    roomName = key;
    checkExistCall = true;
  }
  if(value.requestUsers.containsKey(request.users.first.username)&&!value.requestUsers.containsKey(user!.username)) 
  {
roomName = 'The user is busy';
    roomName = key;
    checkExistCall = true;
  }


});
if(checkExistCall)
{
  
  return ResponseDto(message: roomName);
}



   
    int chatId = -1;
   List<ShortChatView> chats = await db.chats.queryShortViews(QueryParams(where: "'${user!.username}' = ANY(members) AND '${request.users.first.username}' = ANY(members)"));
   for(ShortChatView chat in chats)
   {
    if(chat.members.length == 2)
    {
chatId = chat.id;
break;
    }
   }

db.messages.insertOne(MessageInsertRequest(body:  Utils.encryptField('📞📞📞'), originalDate: DateTime.now(), forwarded: false, authorId: id, content: [], button: [], authorName: user.username, 
stickerContent: 0, dateMessage: DateTime.now(), delivered: false, originalAuthor: user.username, chatId: chatId));

    request.room = roomName;
    final String userAvatar = await Utils.getLincToFile(user!.imageAvatar, true);
    request.users.add(UserDto(username: user.username, imageAvatar: userAvatar));
    rooms[request.room] = CallRoom(request);
    _streamControllerEvent.add(request);
    return ResponseDto(message: request.room);
  }

 

   @override
  Future<ResponseDto> exitToRoom(ServiceCall call, RequestDto request) async{
    print(rooms);
     final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
if(rooms.containsKey(request.room))
{
 final bool checkRemove = await rooms[request.room]?.exitUser(user!.username)??false;
 if(checkRemove)
 {
  rooms.remove(request.room);
 }
}
    return ResponseDto(message: 'succes');
  }

  @override
  Stream<UpdateDTO> listenCall(ServiceCall call, RequestDto request) async*{
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
     // Сначала проверяем существующие комнаты
  for (CallRoom room in rooms.values) {
    if (room.requestUsers.containsKey(user!.username)) {
      List <UserDto> users =[];
room.requestUsers.forEach((String key, UpdateDTO value){
  users.add(UserDto(username: key, imageAvatar: ''));
});
      yield UpdateDTO(
        users: users,
        room: room.id,
        exitCall: false,
        callData: CallDto(soundData: [], videoData: []),
        video: room.video
      );
    }
  }
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
   yield  rooms[roomId]!.requestUsers[user.username]!;
  }
  }
  
}

class CallRoom {
  final StreamController<RequestDto> streamReq = StreamController.broadcast();
  final StreamController<UpdateDTO> streamResponse = StreamController.broadcast();
  
  // Буферы для аудио-данных по пользователям
  final Map<String, AudioBuffer> _audioBuffers = {};
  Timer? _audioSendTimer;
  
  CallRoom(UpdateDTO request) {
    id = request.room;
    for (var user in request.users) {
      requestUsers[user.username] = UpdateDTO(
        users: [], 
        video: video, 
        exitCall: false, 
        room: id, 
        callData: CallDto(soundData: [], videoData: [])
      );
    }
    video = request.video;
    start();
  }
  
  bool video = false;
  bool exit = false;
  late String id;
  Map<String, UpdateDTO> requestUsers = {};
  List linkUsers = [];
  
  void start() {
    // Инициализация таймера для отправки буферизированного аудио
    // Клиент отправляет кадры по 512 сэмплов при 16000 Гц
    // Длительность кадра: 512 / 16000 = 32 мс
    // Отправляем каждые 32 мс для синхронизации с клиентом
    _audioSendTimer = Timer.periodic(const Duration(milliseconds: 32), (_) {
      _sendBufferedAudio();
    });
    
    streamResponse.stream.listen((event) {
      requestUsers.forEach((key, value) { 
        if (key != event.room) {
          requestUsers[key] = event;
        }
      });
    });
    
    streamReq.stream.listen((event) {
      // Обработка аудио-данных с буферизацией
      if (event.callData.soundData.isNotEmpty) {
        _bufferAudioData(event.room, event.callData.soundData);
      } else {
        // Не-аудио данные отправляем сразу
        streamResponse.add(UpdateDTO(
          users: [], 
          video: video, 
          exitCall: exit, 
          room: event.room, 
          callData: CallDto(soundData: event.callData.soundData, videoData: [])
        ));
      }
    });
  }
  
  void _bufferAudioData(String username, List<int> audioData) {
    if (!_audioBuffers.containsKey(username)) {
      _audioBuffers[username] = AudioBuffer();
    }
    _audioBuffers[username]!.addData(audioData);
  }
  
  void _sendBufferedAudio() {
    _audioBuffers.forEach((username, buffer) {
      final dataToSend = buffer.getDataForSending();
      if (dataToSend.isNotEmpty) {
        streamResponse.add(UpdateDTO(
          users: [], 
          video: video, 
          exitCall: exit, 
          room: username, 
          callData: CallDto(soundData: dataToSend, videoData: [])
        ));
      }
    });
  }
  
  Future<bool> exitUser(String user) async {
    if (requestUsers.containsKey(user) && requestUsers.length == 2) { 
      exit = true;
      await Future.delayed(const Duration(seconds: 1));
      
      // Очистка таймера и буферов
      _audioSendTimer?.cancel();
      _audioSendTimer = null;
      _audioBuffers.clear();
      
      streamReq.close();
      streamResponse.close();
      requestUsers.remove(user);
      return true;
    }
    if (requestUsers.containsKey(user) && requestUsers.length > 2) {
      // Удаляем буфер для вышедшего пользователя
      _audioBuffers.remove(user);
      requestUsers.remove(user);
      return false;
    }
    return false;
  }
}

/// Класс для буферизации аудио-данных
class AudioBuffer {
  final Queue<List<int>> _bufferQueue = Queue<List<int>>();
  final List<int> _accumulatedData = [];
  int _totalBytes = 0;
  
  // Параметры из клиентского приложения
  final int _sampleRate = 16000; // Гц
  final int _frameSize = 512; // сэмплов в кадре
  final int _bytesPerSample = 2; // 16-бит = 2 байта
  
  // Размер буфера: 0.25 секунды = 250 мс
  final int _targetBufferMs = 250;
  
  // Количество кадров в буфере
  final int _targetFrames;
  
  // Текущее количество накопленных кадров
  int _bufferedFrames = 0;
  
  AudioBuffer() : _targetFrames = (250 * 16000 ~/ 512) ~/ 1000 {
    // 250 мс при 16000 Гц и 512 сэмплов на кадр:
    // 0.25 сек * 16000 Гц / 512 сэмплов = 7.8 кадров
    // Округляем до 8 кадров для буфера
  }
  
  void addData(List<int> data) {
    // Проверяем размер данных (ожидаем 512 * 2 = 1024 байта)
    if (data.length == _frameSize * _bytesPerSample) {
      _bufferQueue.add(data);
      _bufferedFrames++;
      
      // Поддерживаем размер буфера
      while (_bufferedFrames > _targetFrames * 2) {
        // Если буфер слишком большой, удаляем самые старые данные
        if (_bufferQueue.isNotEmpty) {
          _bufferQueue.removeFirst();
          _bufferedFrames--;
        }
      }
    } else {
      // Если размер данных не соответствует ожидаемому, все равно буферизируем
      _bufferQueue.add(data);
      _bufferedFrames++;
    }
  }
  
  List<int> getDataForSending() {
    // Отправляем данные, только если в буфере достаточно кадров
    if (_bufferedFrames >= _targetFrames && _bufferQueue.isNotEmpty) {
      // Берем самый старый кадр из буфера
      final data = _bufferQueue.removeFirst();
      _bufferedFrames--;
      return data;
    }
    
    // Если данных недостаточно, возвращаем пустой список
    // Можно также генерировать тишину, но лучше пропустить отправку
    return [];
  }
  
  // Альтернативная версия: отправка с интерполяцией при недостатке данных
  List<int> getDataForSendingWithInterpolation() {
    if (_bufferQueue.isEmpty) {
      // Генерируем тишину (нулевые значения)
      return List.filled(_frameSize * _bytesPerSample, 0);
    }
    
    if (_bufferedFrames >= _targetFrames) {
      // Достаточно данных в буфере
      final data = _bufferQueue.removeFirst();
      _bufferedFrames--;
      return data;
    } else if (_bufferedFrames > 0) {
      // Данных меньше, чем нужно, но что-то есть
      // Можно отправить с небольшим ускорением или интерполяцией
      final data = _bufferQueue.removeFirst();
      _bufferedFrames--;
      
      // Небольшая оптимизация: если буфер почти пуст, ускоряем отправку
      // чтобы догнать реальное время
      if (_bufferedFrames < _targetFrames ~/ 2) {
        // Удаляем еще один кадр, чтобы ускорить очистку буфера
        if (_bufferQueue.isNotEmpty) {
          _bufferQueue.removeFirst();
          _bufferedFrames--;
        }
      }
      
      return data;
    } else {
      // Буфер полностью пуст - генерируем тишину
      return List.filled(_frameSize * _bytesPerSample, 0);
    }
  }
  
  void clear() {
    _bufferQueue.clear();
    _accumulatedData.clear();
    _totalBytes = 0;
    _bufferedFrames = 0;
  }
  
  // Получить текущую задержку в миллисекундах
  double getCurrentDelayMs() {
    return _bufferedFrames * (_frameSize / _sampleRate) * 1000;
  }
}
