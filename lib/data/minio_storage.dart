import 'dart:typed_data';

import 'package:minio/minio.dart';
import 'package:schat_api/domain/i_storage.dart';
import 'package:schat_api/env.dart';



final class MinioStorage implements IStorage {
  late final Minio minio;

  MinioStorage() {
    minio = Minio(
        port: env.storagePort,
        endPoint: env.storageHost,
        accessKey: env.minioLogin,
        secretKey: env.minioPassword,
        useSSL: false);
  }

  @override
  Future<String> putFile(
      {required String bucket,
      required String name,
      required Uint8List data}) async {
    try {
      if (!await minio.bucketExists(bucket)) {
        await minio.makeBucket(bucket);
      }
      final String tag =
          await minio.putObject(bucket, name, Stream<Uint8List>.value(data));
      return tag;
    } catch (e) {
      print(e.toString());
      return e.toString();
    }
  }

  Future<String> getFile({required String bucket, required String name}) async {
    try {
      final String linc = await minio.presignedUrl('GET', bucket, name);
      return linc;
    } catch (e) {
      print(e.toString());
      return e.toString();
    }
  }

  removeFile({required String bucket, required String name}) {
    try {
      minio.removeObject(bucket, name);
    } catch (e) {
      print(e.toString());
    }
  }
}
