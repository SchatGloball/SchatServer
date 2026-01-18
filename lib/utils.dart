import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:grpc/grpc.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:schat_api/data/message/message.dart';
import 'package:schat_api/data/minio_storage.dart';
import 'package:schat_api/data/user/user.dart';
import 'package:schat_api/env.dart';
import 'package:schat_api/generated/auth.pbgrpc.dart';
import 'package:schat_api/generated/chats.pb.dart';
import 'package:xor_dart/xor_dart.dart';

import 'data/chat/chat.dart';
import 'data/reaction_message/reaction_message.dart';

final MinioStorage storage = MinioStorage();

class Utils {
  static String getHastPasswors(String password) {
    //солим пароль
    final bytes = utf8.encode(password + env.sk);
    return sha256.convert(bytes).toString();
  }

  static String encryptField(String value, {bool isDecode = false}) {
    var xor = Xor(env.sk);
    if (isDecode) {
      return xor.decode(value);
    } else {
      return xor.encode(value);
    }
  }

  static int getIdFromToken(String token) {
    //получаем id пользователя по токену
    final JwtClaim = verifyJwtHS256Signature(token, env.sk);
    final id = int.tryParse(JwtClaim['user_id']);
    if (id == null) {
      throw GrpcError.dataLoss("Error user id");
    }
    return id;
  }

  static int getIdFromMetadata(ServiceCall serviceCall) {
    final accessToken = serviceCall.clientMetadata?['access_token'] ?? '';
    return getIdFromToken(accessToken);
  }

 static bool getIsBotFromToken(ServiceCall serviceCall) {
  final token = serviceCall.clientMetadata?['access_token'] ?? '';
    final JwtClaim = verifyJwtHS256Signature(token, env.sk);
    return JwtClaim['isBot'];
  }

  static String getUserNameFromMetadata(ServiceCall serviceCall) {
    final accessToken = serviceCall.clientMetadata?['access_token'] ?? '';
    final JwtClaim = verifyJwtHS256Signature(accessToken, env.sk);
    return JwtClaim['user_name'];
  }

  static UserDto convertUserDto(UserView user, String imageLink) {
    //отдаём информацио о пользователе
    return UserDto(
        id: user.id, username: user.username, imageAvatar: imageLink, isBot: user.isBot);
  }

  static Future<String> getLincToFile(String name, bool isUserAvatar) async {
    String link = await storage.getFile(
        bucket: isUserAvatar ? env.usersBucket : env.chatsBucket, name: name);
    return link;
  }

  static ListChatsDto parseChatsIsDTO(List<ShortChatView> list) {
    try {
      return ListChatsDto(chats: [
        ...list.map((chat) => ChatDto(
                authorId: chat.authorId,
                id: chat.id,
                name: chat.name,
                members: [
                  ...chat.members
                      .map((e) => MemberDto(memberUsername: e.toString()))
                ]))
      ]);
    } catch (e) {
      rethrow;
    }
  }

  static ListChatsDto parseChats(List<Map> list) {
    try {
      ListChatsDto response = ListChatsDto(chats: []);
      for (var element in list) {
        List<MemberDto> members = [];
        String encryptBody = '';
        if (element['body'].toString() != 'null') {
          encryptBody = Utils.encryptField(element['body'], isDecode: true);
        }
        for (var elementMember in element['members']) {
          members.add(MemberDto(
              memberUsername: elementMember['username'],
              memberImage: elementMember['image_avatar']));
        }

                List<String> buttons = [];
for (var button in element['buttons']) {
          buttons.add(button.toString());
        }
        response.chats.add(ChatDto(
            id: element['id'],
            name: element['name'],
            authorId: element['author_id'].toString(),
            chatImage: element['chat_image'],
            members: members,
            messages: [
              MessageDto(
                id: element['id_message'],
                body: encryptBody,
                authorId: element['author_messsage_id'],
                forwarded: element['forwarded'],
                originalAuthor: element['original_author'],
                originalDate: element['original_date'].toString(),
                chatId: element['chat_id'],
                content: element['content'],
                stickerContent: element['sticker_content'],
                dateMessage: element['date_message'].toString(),
                delivered: element['delivered'] ?? false,
                authorName: element['author_name'].toString(),
                button: buttons,

              )
            ]));
      }
      response.chats
          .sort((a, b) => b.messages.first.id.compareTo(a.messages.first.id));
      return response;
    } catch (e) {
      rethrow;
    }
  }

  static ChatDto parseChat(ShortChatView chat, List<MessageView> messages,
      String chatImage, List content) {
    int chek = -1;
    return ChatDto(
        id: chat.id,
        name: chat.name,
        chatImage: chatImage,
        authorId: chat.authorId,
        messages: [
          ...messages.map((e) {
            ++chek;
            return parseMessage(e, content[chek]);
          })
        ],
        members: [
          ...chat.members
              .map((e) => MemberDto(memberUsername: e, memberImage: e))
        ]);
  }

  static MessageDto parseMessage(MessageView message, List<String> content) {
    List<ReactionMessageDto> reactions = [];
    for (ReactionMessageView r in message.reaction) {
      reactions.add(ReactionMessageDto(
          id: r.id,
          body: encryptField(r.body, isDecode: true),
          authorId: r.authorId,
          authorName: r.authorName,
          messageId: message.id,
          stickerContent: r.stickerContent,
          dateReaction: r.dateReaction.toString()));
    }
    return MessageDto(
        id: message.id,
        body: encryptField(message.body, isDecode: true),
        authorId: message.authorId,
        chatId: message.authorId,
        content: content,
        stickerContent: message.stickerContent,
        dateMessage: message.dateMessage.toString(),
        delivered: message.delivered,
        authorName: message.authorName,
        forwarded: message.forwarded,
        originalAuthor: message.originalAuthor,
        originalDate: message.originalDate.toString(),
        reaction: reactions,
        button: message.button
        );
  }

  static List<ReactionMessageDto> parseReactions(
      List<ReactionMessageView> list, int messageId) {
    try {
      List<ReactionMessageDto> reactions = [];
      for (ReactionMessageView r in list) {
        reactions.add(ReactionMessageDto(
            id: r.id,
            body: encryptField(r.body, isDecode: true),
            authorId: r.authorId,
            authorName: r.authorName,
            messageId: messageId,
            stickerContent: r.stickerContent,
            dateReaction: r.dateReaction.toString()));
      }
      return reactions;
    } catch (e) {
      rethrow;
    }
  }

  static ListUsersDto parseUsers(List<UserView> users, List<String> imageList) {
    try {
      int chek = -1;
      return ListUsersDto(users: [
        ...users.map((e) {
          ++chek;
          return convertUserDto(e, imageList[chek]);
        })
      ]);
    } catch (e) {
      throw GrpcError.internal('Error parde users');
    }
  }

  static List<MessageDto> searchInMessage(
      List<MessageView> messages, String searchRequest) {
    try {
      List<MessageDto> res = [];
      for (var element in messages) {
        final String messageBody =
            Utils.encryptField(element.body, isDecode: true);
        if (messageBody.contains(searchRequest)) {
          res.add(MessageDto(
              id: element.id,
              body: messageBody,
              authorId: element.authorId,
              chatId: element.id,
              authorName: element.authorName,
              delivered: element.delivered,
              data: [],
              content: [],
              stickerContent: 0,
              dateMessage: element.dateMessage.toString(),
              forwarded: element.forwarded,
              originalAuthor: element.authorName));
        }
      }
      return res;
    } catch (e) {
      throw GrpcError.internal('Error parde users');
    }
  }
}
