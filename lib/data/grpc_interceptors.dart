import 'dart:async';

import 'package:grpc/grpc.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:schat_api/env.dart';

const _excludeMethods = ['SignUp', 'SignIn', 'RefreshToken', 'ServerInfo'];

abstract class GrpcInterceptors {
  static FutureOr<GrpcError?> tokenInterceptor(
      ServiceCall call, ServiceMethod serviceMethod) {
    try {
      if (_excludeMethods.contains(serviceMethod.name)) {
        return null;
      }
      final token = call.clientMetadata?['access_token'] ?? '';
      final JwtClaim = verifyJwtHS256Signature(token, env.sk);
      JwtClaim.validate();
      return null;
    } catch (e) {
      return GrpcError.unauthenticated('access_token error');
    }
  }
}
