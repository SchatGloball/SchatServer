import 'dart:isolate';
import 'dart:typed_data';

import 'package:grpc/grpc.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:schat_api/data/user/user.dart';
import 'package:schat_api/generated/auth.pbgrpc.dart';
import 'package:schat_api/schat_api.dart';
import 'package:schat_api/utils.dart';
import 'package:stormberry/stormberry.dart';
import 'package:uuid/uuid.dart';

import '../data/db.dart';
import '../env.dart';

class AuthRpc extends AuthRpcServiceBase {
  var uuid = Uuid();

  @override
  Future<ResponseDto> deleteUser(ServiceCall call, RequestDto request) async {
    final id = Utils.getIdFromMetadata(call);
    await db.users.deleteOne(id);
    return ResponseDto(message: "succes");
  }

  @override
  Future<UserDto> fetchUser(ServiceCall call, RequestDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    String linkImage = '';
    if (user == null) {
      throw GrpcError.notFound("User not found");
    }

    if (user.imageAvatar != '') {
      linkImage = await Utils.getLincToFile(user.imageAvatar, true);
    }
    return Utils.convertUserDto(user, linkImage);
  }

  @override
  Future<TokensDto> refreshToken(ServiceCall call, TokensDto request) async {
    if (request.refreshToken.isEmpty) {
      throw GrpcError.invalidArgument('Token not found');
    }

    final id = Utils.getIdFromToken(request.refreshToken);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.notFound('User not found');
    }
    return _createTokens(user.id.toString(), user.username);
  }

  @override
  Future<TokensDto> signIn(ServiceCall call, UserDto request) async {
    if (request.email.isEmpty) {
      throw GrpcError.invalidArgument('Email not found');
    }
    if (request.password.isEmpty) {
      throw GrpcError.invalidArgument('Password not found');
    }
    final hashPassword = Utils.getHastPasswors(request.password);
    final users = await db.users.queryUsers(QueryParams(
        where: "email = '${Utils.getHastPasswors(request.email)}' "));

    if (users.isEmpty) {
      throw GrpcError.notFound("User not found");
    }
    final user = users.first;

    if (hashPassword != user.password) {
      throw GrpcError.unimplemented("Password wrong");
    }

    return _createTokens(user.id.toString(), user.username);
  }

  @override
  Future<TokensDto> signUp(
      ServiceCall call, UserDto request) //регистрация пользователя
  async {
    if (request.email.isEmpty) {
      throw GrpcError.invalidArgument('Email not found');
    }
    if (request.password.isEmpty) {
      throw GrpcError.invalidArgument('Password not found');
    }
    if (request.username.isEmpty) {
      throw GrpcError.invalidArgument('Username not found');
    }
    if (request.username.split(' ').length > 1) {
      throw GrpcError.invalidArgument('Do not use spaces');
    }
    if (request.email.split(' ').length > 1) {
      throw GrpcError.invalidArgument('Do not use spaces');
    }

    final id = await db.users.insertOne(
      UserInsertRequest(
          username: request.username,
          email: Utils.getHastPasswors(request.email),
          password: Utils.getHastPasswors(request.password),
          imageAvatar: '',
          isBot: false,
          nameCreator: ''),
    );

    return _createTokens(id.toString(), request.username);
  }

  @override
  Future<UserDto> updateUser(ServiceCall call, UserDto request) async {
    final int id = Utils.getIdFromMetadata(call);
    final userOld = db.users.queryUser(id); 
    await db.users.updateOne(UserUpdateRequest(
        id: id,
        username: request.username.isEmpty ? null : request.username,
        email: request.email.isEmpty ? null : Utils.encryptField(request.email),
        password: request.password.isEmpty
            ? null
            : Utils.getHastPasswors(request.password),
        imageAvatar: request.imageAvatar.isEmpty ? null : request.imageAvatar));
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.notFound('user not found');
    }

    String linkImage = '';
    if (user.imageAvatar != '') {
      linkImage = await Utils.getLincToFile(user.imageAvatar, true);
    }

    return Utils.convertUserDto(user, linkImage);
  }

  TokensDto _createTokens(String id, String userName) {
    final accessTokenSet = JwtClaim(
        maxAge: Duration(hours: Env.accessTokenLife),
        otherClaims: {'user_id': id, 'user_name': userName});

    final refreshTokenSet = JwtClaim(
        maxAge: Duration(hours: Env.refreshTokenLife),
        otherClaims: {'user_id': id});

    return TokensDto(
        accessToken: issueJwtHS256(accessTokenSet, Env().sk),
        refreshToken: issueJwtHS256(refreshTokenSet, Env().sk));
  }

  @override
  Future<ListUsersDto> findUser(ServiceCall call, FindDto request) async {
    final key = request.key;
    if (key.isEmpty) {
      throw GrpcError.invalidArgument('Search is empty');
    }
    final query = "username LIKE '%$key%'";
    final List<UserView> listUsers = await db.users
        .queryUsers(QueryParams(orderBy: 'username', where: query));
    List<String> imageList = [];
    String linkImage = '';
    for (var element in listUsers) {
      if (element.imageAvatar != '') {
        linkImage = await Utils.getLincToFile(element.imageAvatar, true);
        imageList.add(linkImage);
      } else {
        imageList.add('');
      }
    }

    return Isolate.run(() => Utils.parseUsers(listUsers, imageList));
  }

  @override
  Future<ResponseDto> putAvatar(ServiceCall call, FileDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.notFound('user not found');
    }
    if (user.imageAvatar != '') {
      final removeName = user.imageAvatar
          .split('/${Env.usersBucket}/')
          .last
          .split('?X-Amz-')[0];
      await storage.removeFile(bucket: Env.usersBucket, name: removeName);
    }
    final String name = uuid.v8();
    await storage.putFile(
        bucket: Env.usersBucket, name: name, data: request.data as Uint8List);
    final String link =
        await storage.getFile(bucket: Env.usersBucket, name: name);
    await db.users.updateOne(UserUpdateRequest(id: id, imageAvatar: name));
    return ResponseDto(message: link);
  }
}
