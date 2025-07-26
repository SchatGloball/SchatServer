import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:grpc/grpc.dart';
import 'package:schat_api/data/chat/chat.dart';
import 'package:schat_api/data/message/message.dart';
import 'package:schat_api/data/reaction_message/reaction_message.dart';
import 'package:schat_api/data/user/user.dart';
import 'package:schat_api/env.dart';
import 'package:schat_api/generated/chats.pbgrpc.dart';
import 'package:schat_api/utils.dart';
import 'package:stormberry/stormberry.dart';
import 'package:uuid/uuid.dart';
import '../data/db.dart';

class ChatRpc extends ChatsRpcServiceBase {
  var uuid = Uuid();

  final StreamController<UpdateDTO> _streamControllerEvent =
      StreamController.broadcast();

  @override
  Future<ResponseDto> createChat(ServiceCall call, ChatDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.invalidArgument('Remove user');
    }

    if (request.name.isEmpty) {
      throw GrpcError.invalidArgument('Chat name not found');
    }
    if (request.members.isEmpty) {
      throw GrpcError.invalidArgument('Member not found');
    }
    List<String> members = [];

    for (var e in request.members) {
      //добавляем в массив участников чата
      members.add(e.memberUsername);
    }
    if (!members.contains(user.username)) {
      members.add(user.username);
    }

    final povtorChat = await db.chats.queryShortViews(QueryParams(
        where:
            "members='{${members[0]},${members[1]}}' OR members='{${members[1]},${members[0]}}'"));
    if (povtorChat.isNotEmpty && members.length == 2) {
      throw GrpcError.invalidArgument(
          'Chat exist'); //Если чат между двумя пользователями уже есть
    }

    int idChat = await db.chats.insertOne(ChatInsertRequest(
        name: request.name,
        authorId: id.toString(),
        chatImage: '',
        members: members));
    _streamControllerEvent.add(UpdateDTO(
        chat: ChatDto(
            id: idChat,
            name: request.name,
            authorId: id.toString(),
            chatImage: '',
            members: [...request.members])));

    return ResponseDto(message: 'success');
  }

  @override
  Future<ResponseDto> deleteChat(ServiceCall call, ChatDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final int chatId = request.id;
    final chat = await db.chats.queryShortView(chatId);
    if (chat == null) {
      throw GrpcError.notFound('Chat not found');
    }
    final user = await db.users.queryUser(id);

    if (chat.authorId == id.toString() ||
        chat.members.contains(user!.username)) {
      if (chat.members.length > 2) //исключаем пользователя из списка участников
      {
        chat.members.remove(user!.username);
        await db.chats
            .updateOne(ChatUpdateRequest(id: chat.id, members: chat.members));
        return ResponseDto(message: 'success');
      }

      //  удаляем все файлы из хранилища
      final messages = await db.execute(
          "SELECT json_build_object('content', messages.content) AS json_data FROM messages WHERE $chatId = chat_id");
      for (var element in messages) {
        String m = jsonEncode(element.first);
        Map<String, dynamic> elementJson = jsonDecode(m);
        for (var link in elementJson['content']) {
          storage.removeFile(bucket: Env.chatsBucket, name: link);
        }
      }

      //удаляем сообщения
      await db.execute("DELETE FROM messages WHERE $chatId = chat_id");
      await db.chats.deleteOne(chatId);

// Id автора 0, значит удаляем
      _streamControllerEvent.add(UpdateDTO(
          chat: ChatDto(
              id: chat.id,
              members: [
                MemberDto(memberUsername: chat.members.first),
                MemberDto(memberUsername: chat.members.last)
              ],
              authorId: '-1')));

      return ResponseDto(message: 'success');
    } else {
      throw GrpcError.permissionDenied();
    }
  }

  @override
  Future<ResponseDto> deleteMessage(
      ServiceCall call, MessageDto request) async {
    final int messageId = request.id;
    final message = await db.messages.queryMessage(messageId);
    if (message == null) {
      throw GrpcError.invalidArgument('Error id message');
    }
    final id = Utils.getIdFromMetadata(call);
    if (message.authorId == id) {
      final MessageView? message = await db.messages.queryMessage(messageId);
      for (var element in message!.content) {
        await storage.removeFile(bucket: Env.chatsBucket, name: element);
      }
      await db.messages.deleteOne(messageId);
      return ResponseDto(message: 'success');
    } else {
      throw GrpcError.permissionDenied('error');
    }
  }

  @override
  Future<ListChatsDto> fetchAllChats(
      ServiceCall call, RequestDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);

    if (user == null) {
      throw GrpcError.invalidArgument('Remove user');
    }

    final Result listChats = await db.execute(
        "SELECT json_build_object('id', chats.id, 'name', chats.name, 'author_id', chats.author_id, 'chat_image', chats.chat_image, 'members', (SELECT json_agg(json_build_object( 'username', users.username, 'image_avatar', users.image_avatar)) FROM users WHERE users.username = ANY(chats.members)), 'id_message', messages.id, 'body', messages.body, 'author_messsage_id', messages.author_id, 'content', messages.content, 'sticker_content', messages.sticker_content, 'chat_id', messages.chat_id, 'date_message', messages.date_message, 'delivered', messages.delivered, 'author_name', messages.author_name, 'forwarded', messages.forwarded, 'original_author', messages.original_author, 'original_date', messages.original_date) AS json_data FROM chats LEFT JOIN (SELECT DISTINCT ON (chat_id) * FROM messages ORDER BY chat_id, id DESC) AS messages ON chats.id = messages.chat_id WHERE '${user.username}' = ANY(chats.members)");

    if (listChats.isEmpty) {
      return ListChatsDto(chats: []);
    }

    List<Map> chats = [];
    for (var element in listChats) {
      String m = jsonEncode(element.first);
      Map<String, dynamic> elementJson = jsonDecode(m);

      if (elementJson['id_message'].runtimeType == Null) {
        elementJson['id_message'] = 0;
        elementJson['content'] = [];
        elementJson['chat_id'] = elementJson['id'];
        elementJson['date_message'] = '2024-01-30 02:59:25.704108';
        elementJson['delivered'] = true;
        elementJson['author_messsage_id'] = 0;
        elementJson['author_name'] = elementJson['author_id'].toString();
        elementJson['sticker_content'] = 0;
        elementJson['body'] = '';
      }

      List<String> contentLink = [];
      for (var content in elementJson['content']) {
        contentLink.add(await Utils.getLincToFile(content, false));
      }
      elementJson['content'] = contentLink;

      if (elementJson['chat_image'] != '') {
        elementJson['chat_image'] =
            await Utils.getLincToFile(elementJson['chat_image'], true);
      } else {
        if (elementJson['members'].length == 2) {
          if (elementJson['members'].first['username'] == user.username) {
            if (elementJson['members'][1]['image_avatar'] != '') {
              elementJson['chat_image'] = await Utils.getLincToFile(
                  elementJson['members'][1]['image_avatar'], true);
            }
          } else {
            if (elementJson['members'][0]['image_avatar'] != '') {
              elementJson['chat_image'] = await Utils.getLincToFile(
                  elementJson['members'][0]['image_avatar'], true);
            }
          }
        }
      }
      chats.add(elementJson);
    }
    return await Isolate.run(() => Utils.parseChats(chats));
  }

  @override
  Future<ChatDto> fetchChat(ServiceCall call, ChatDto request) async {
    final int chatId = request.id;
    final offset = int.tryParse(request.name) ?? 0;

    final chat = await db.chats.queryShortView(chatId);
    if (chat == null) {
      throw GrpcError.notFound('Chat not found');
    }

    final messages = await db.messages.queryMessages(QueryParams(
      offset: offset,
      where: "chat_id='$chatId'",
      limit: 100,
      orderBy: "id DESC",
    ));

    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);

    List content = [];

    String chatImage = '';

    for (var element in messages) {
      List<String> contentMessage = [];
      String link = '';
      for (var elementContent in element.content) {
        link = await Utils.getLincToFile(elementContent, false);
        contentMessage.add(link);
      }
      content.add(contentMessage);
    }
    if (chat.chatImage != '') {
      chatImage = await Utils.getLincToFile(chat.chatImage, false);
    }
    if (chat.members.length == 2) {
      if (chat.members.first != user!.username) {
        final userTwo = await db.users
            .queryUsers(QueryParams(where: "username='${chat.members.first}'"));

        if (userTwo.first.imageAvatar != '') {
          chatImage =
              await Utils.getLincToFile(userTwo.first.imageAvatar, true);
        }
      } else {
        if (user.imageAvatar != '') {
          chatImage = await Utils.getLincToFile(user.imageAvatar, true);
        }
      }
    }
    db.execute(
        "UPDATE messages SET delivered = true WHERE chat_id = '$chatId' AND author_id != '$id';"); //пометить сообщения прочитанными
    if (chat.members.contains(user!.username)) {
      return await Isolate.run(
          () => Utils.parseChat(chat, messages, chatImage, content));
    } else {
      throw GrpcError.permissionDenied();
    }
  }

  @override
  Future<ResponseDto> sendMessage(ServiceCall call, MessageDto request) async {
    final authorId = Utils.getIdFromMetadata(call);
    final String userName = Utils.getUserNameFromMetadata(call);
    final int chatId = request.chatId;

    final String messageBody =
        Utils.encryptField(request.body); //Шифруем сообщение

    final date = DateTime.now();
    final chatDB = await db.chats.queryShortView(chatId);
    List<ShortChatView> chatsListDB = [chatDB!];
    final chat = Utils.parseChatsIsDTO(chatsListDB).chats.first;

    List<String> content = [];

    if (request.content.length != request.data.length) {
      throw GrpcError.invalidArgument('Content error');
    }

    for (int i = 0; i < request.data.length; i++) {
      final String name = '${uuid.v8()}.separated.${request.content[i]}';
      await storage.putFile(
          bucket: Env.chatsBucket,
          name: name,
          data: request.data[i] as Uint8List);
      content.add(name);
    }

    final id = await db.messages.insertOne(MessageInsertRequest(
        chatId: chatId,
        body: messageBody,
        authorId: authorId,
        content: content,
        stickerContent: request.stickerContent,
        dateMessage: date,
        authorName: userName,
        originalAuthor: userName,
        originalDate: date,
        forwarded: false,
        delivered: false));

    List<String> linkContent = [];
    for (int i = 0; i < content.length; i++) {
      final c = await Utils.getLincToFile(content[i], false);
      linkContent.add(c);
    }

    chat.messages.add(MessageDto(
        id: id,
        chatId: chatId,
        body: request.body,
        authorId: authorId,
        content: linkContent,
        stickerContent: request.stickerContent,
        dateMessage: date.toString(),
        authorName: userName,
        delivered: false,
        forwarded: false,
        originalAuthor: userName,
        originalDate: date.toString(),
        reaction: []));
    _streamControllerEvent.add(UpdateDTO(chat: chat));
    return ResponseDto(message: 'success');
  }

  @override
  Stream<UpdateDTO> listenEvent(ServiceCall call, RequestDto request) async* {
    final id = Utils.getIdFromMetadata(call);

    final user = await db.users.queryUser(id);
    // yield* _streamControllerEvent.stream
    //     .where((event) => event.chats.members.contains(MemberDto(
    //           memberUsername: user!.username,
    //         )));

    yield* _streamControllerEvent.stream.where((event) => event.chat.members
        .any((member) => member.memberUsername == user!.username));
  }

  @override
  Future<ResponseDto> editGroupChat(ServiceCall call, ChatDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.invalidArgument('Remove user');
    }

    if (request.name.isEmpty) {
      throw GrpcError.invalidArgument('Chat name not found');
    }
    if (request.members.isEmpty) {
      throw GrpcError.invalidArgument('Member not found');
    }
    List<String> members = [];
    members.add(user.username);
    for (var e in request.members) {
      //добавляем в массив участников чата
      members.add(e.memberUsername);
    }

    final FullChatView? oldChat = await db.chats.queryFullView(request.id);

//     List<ShortChatView> chekNameChat = await db.chats.queryShortViews(QueryParams(where: "name='${request.name}'"));
//     if(chekNameChat.isNotEmpty)
//     {
//       if(chekNameChat.first.id != oldChat!.id)
//       {
//  throw GrpcError.invalidArgument('Name is too busy');
//       }
//     }

    if (!oldChat!.members.contains(user.username)) {
      throw GrpcError.invalidArgument('Permission denied');
    }
    members.addAll(oldChat.members);

    members = List<String>.from(
        members.toSet()); //оставляем только уникальные элементы

    String imageName = oldChat.chatImage;

    if (request.image.isNotEmpty) {
      await storage.removeFile(
          bucket: Env.usersBucket, name: oldChat.chatImage);
      imageName = uuid.v8();
      await storage.putFile(
          bucket: Env.usersBucket,
          name: imageName,
          data: request.image as Uint8List);
    }

    final String imageLink = await Utils.getLincToFile(imageName, true);

    await db.chats.updateOne(ChatUpdateRequest(
        id: oldChat.id,
        chatImage: imageName,
        members: members,
        name: request.name));

    _streamControllerEvent.add(UpdateDTO(
        chat: ChatDto(
            id: oldChat.id,
            name: request.name,
            authorId: oldChat.authorId,
            chatImage: imageLink,
            members: [
          ...request.members,
          MemberDto(memberUsername: user.username)
        ])));

    return ResponseDto(message: 'success');
  }

  @override
  Future<UpdateAppRes> updateApp(ServiceCall call, UpdateAppReq request) async {
    if (request.version == Env.version) {
      throw GrpcError.invalidArgument('Error update');
    } else {
      Directory directory = Directory('./clientRepo');

      Directory certdirectory = Directory.fromUri(directory.uri);

      List<FileSystemEntity> files = certdirectory.listSync();

      if (files.isEmpty) {
        throw GrpcError.invalidArgument('Error update');
      }
      for (var element in files) {
        if (element.path.split('.').last == request.platform) {
          File file = File.fromUri(element.uri);

          List<int> data = await file.readAsBytes();
          return UpdateAppRes(name: file.path, data: data);
        }
      }
      throw GrpcError.invalidArgument('Error update');
    }
  }

  @override
  Future<ResponseDto> notification(ServiceCall call, RequestDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    final Result listChats = await db.execute(
        "SELECT json_build_object('id_message', messages.id, 'author_messsage_id', messages.author_id, 'chat_id', messages.chat_id, 'delivered', messages.delivered) AS json_data FROM chats LEFT JOIN (SELECT DISTINCT ON (chat_id) * FROM messages ORDER BY chat_id,  id desc) AS messages ON chats.id = messages.chat_id WHERE '${user!.username}' = ANY(chats.members) AND messages.delivered = false and messages.author_id != '$id'");
    if (listChats.isEmpty) {
      return ResponseDto(message: 'false');
    } else {
      return ResponseDto(message: 'true');
    }
  }

  @override
  Future<ChatDto> searchMessage(
      ServiceCall call, SearchRequestDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.invalidArgument('Remove user');
    }
    if (request.searchRequest.length < 3) {
      throw GrpcError.invalidArgument('Search is empty');
    }
    final chat = await db.chats.queryShortView(request.chat.id);
    if (!chat!.members.contains(user.username)) {
      throw GrpcError.invalidArgument('Permission denied');
    }
    List<MessageDto> message = [];
    for (int i = 0; i < 100000; i += 1000) {
      final List<MessageView> messages =
          await db.messages.queryMessages(QueryParams(
        offset: i,
        where: "chat_id='${request.chat.id}'",
        limit: 1000,
        orderBy: "id DESC",
      ));
      if (messages.isEmpty) {
        break;
      } else {
        message.addAll(Utils.searchInMessage(messages, request.searchRequest));
      }
    }
    return ChatDto(id: request.chat.id, messages: message);
  }

  @override
  Future<ResponseDto> deleteReactionMessage(
      ServiceCall call, ReactionMessageDto request) async {
    final int id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.invalidArgument('Remove user');
    }
    final ReactionMessageView? reaction =
        await db.reactionMessages.queryReactionMessage(request.id);
    if (reaction!.authorId != user.id) {
      throw GrpcError.invalidArgument('Permission denied');
    }
    await db.reactionMessages.deleteOne(reaction.id);
    return ResponseDto(message: 'success');
  }

  @override
  Future<ResponseDto> forwardMessage(ServiceCall call, ChatDto request) async {
    final int id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.invalidArgument('Remove user');
    }
    if (request.messages.isEmpty) {
      throw GrpcError.invalidArgument('Message is empry');
    }
    ShortChatView? chat = await db.chats.queryShortView(request.id);
    if (!chat!.members.contains(user.username)) {
      throw GrpcError.invalidArgument('Permission denied');
    }
    List<int> chatsId = [];
    for (MessageDto m in request.messages) {
      final Result message =
          await db.execute("SELECT chat_id FROM messages WHERE id = '${m.id}'");
      if (message.first.first.runtimeType != int) {
        throw GrpcError.invalidArgument('Error message');
      }
      chatsId.add(int.parse(message.first.first.toString()));
    }
    chatsId = chatsId.toSet().toList();
    for (int chatId in chatsId) {
      ShortChatView? chatView = await db.chats.queryShortView(chatId);
      if (!chatView!.members.contains(user.username)) {
        throw GrpcError.invalidArgument('Permission denied');
      }
    }

    List<MessageInsertRequest> requestsMessages = [];
    List<MessageDto> sendMessage = [];
    for (MessageDto m in request.messages) {
      MessageView? messageOne = await db.messages.queryMessage(m.id);
      requestsMessages.add(MessageInsertRequest(
          body: messageOne!.body,
          forwarded: true,
          authorId: user.id,
          content: messageOne.content,
          authorName: user.username,
          stickerContent: messageOne.stickerContent,
          dateMessage: DateTime.now(),
          delivered: false,
          originalAuthor: messageOne.authorName,
          originalDate: messageOne.originalDate,
          chatId: chat.id));
    }
    List<int> forwardedMessageId =
        await db.messages.insertMany(requestsMessages);

    for (int i = 0; i < forwardedMessageId.length; i++) {
      List<String> linkContent = [];
      for (String cont in requestsMessages[i].content) {
        final c = await Utils.getLincToFile(cont, false);
        linkContent.add(c);
      }
      sendMessage.add(MessageDto(
          id: forwardedMessageId[i],
          chatId: chat.id,
          body: Utils.encryptField(requestsMessages[i].body, isDecode: true),
          authorId: user.id,
          content: linkContent,
          stickerContent: requestsMessages[i].stickerContent,
          dateMessage: requestsMessages[i].dateMessage.toString(),
          authorName: user.username,
          delivered: false,
          forwarded: true,
          originalAuthor: requestsMessages[i].originalAuthor,
          originalDate: requestsMessages[i].originalDate.toString(),
          reaction: []));
    }

    ChatDto chatUpdate = Utils.parseChatsIsDTO([chat]).chats.first;
    chatUpdate.messages.addAll(sendMessage);

    _streamControllerEvent.add(UpdateDTO(chat: chatUpdate));

    return ResponseDto(message: 'success');
  }

  @override
  Future<ResponseDto> reactionMessage(
      ServiceCall call, ReactionMessageDto request) async {
    final int id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.invalidArgument('Remove user');
    }
//MessageView? message = await db.messages.queryMessage(request.messageId);
    final Result message = await db.execute(
        "SELECT chat_id FROM messages WHERE id = '${request.messageId}'");
    if (message.first.first.runtimeType != int) {
      throw GrpcError.invalidArgument('Error message');
    }
    final ShortChatView? chat = await db.chats
        .queryShortView(int.parse(message.first.first.toString()));
    if (chat!.members.contains(user.username)) {
      await db.reactionMessages.insertOne(ReactionMessageInsertRequest(
          body: Utils.encryptField(request.body),
          authorId: user.id,
          authorName: user.username,
          stickerContent: request.stickerContent,
          dateReaction: DateTime.now(),
          messageId: request.messageId));
      bool delivered = false;
      final MessageView? messageFinal =
          await db.messages.queryMessage(request.messageId);
      delivered = messageFinal!.delivered;
      if (!messageFinal.delivered && messageFinal.authorId != user.id) {
        await db.messages.updateOne(
            MessageUpdateRequest(id: messageFinal.id, delivered: true));
        delivered = true;
      }

      List<String> linkContent = [];

      for (String c in messageFinal.content) {
        final cont = await Utils.getLincToFile(c, false);
        linkContent.add(cont);
      }

      List<ReactionMessageDto> reactions =
          Utils.parseReactions(messageFinal.reaction, messageFinal.id);

      ChatDto chatUpdate = Utils.parseChatsIsDTO([chat]).chats.first;
      chatUpdate.messages.add(MessageDto(
          id: request.messageId,
          chatId: chat.id,
          body: Utils.encryptField(messageFinal.body, isDecode: true),
          authorId: messageFinal.authorId,
          content: linkContent,
          stickerContent: request.stickerContent,
          dateMessage: messageFinal.dateMessage.toString(),
          authorName: messageFinal.authorName,
          delivered: delivered,
          forwarded: messageFinal.forwarded,
          originalAuthor: messageFinal.originalAuthor,
          originalDate: messageFinal.originalDate.toString(),
          reaction: reactions));

      _streamControllerEvent.add(UpdateDTO(chat: chatUpdate));
    } else {
      throw GrpcError.invalidArgument('Permission denied');
    }
    return ResponseDto(message: 'success');
  }
}
