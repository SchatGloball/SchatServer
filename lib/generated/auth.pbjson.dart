///
//  Generated code. Do not modify.
//  source: auth.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use listUsersDtoDescriptor instead')
const ListUsersDto$json = const {
  '1': 'ListUsersDto',
  '2': const [
    const {'1': 'users', '3': 1, '4': 3, '5': 11, '6': '.UserDto', '10': 'users'},
  ],
};

/// Descriptor for `ListUsersDto`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listUsersDtoDescriptor = $convert.base64Decode('CgxMaXN0VXNlcnNEdG8SHgoFdXNlcnMYASADKAsyCC5Vc2VyRHRvUgV1c2Vycw==');
@$core.Deprecated('Use findDtoDescriptor instead')
const FindDto$json = const {
  '1': 'FindDto',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
  ],
};

/// Descriptor for `FindDto`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List findDtoDescriptor = $convert.base64Decode('CgdGaW5kRHRvEhAKA2tleRgBIAEoCVIDa2V5');
@$core.Deprecated('Use userDtoDescriptor instead')
const UserDto$json = const {
  '1': 'UserDto',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
    const {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    const {'1': 'email', '3': 3, '4': 1, '5': 9, '10': 'email'},
    const {'1': 'password', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'password'},
    const {'1': 'image_avatar', '3': 5, '4': 1, '5': 9, '9': 0, '10': 'imageAvatar'},
  ],
  '8': const [
    const {'1': 'optional_password'},
  ],
};

/// Descriptor for `UserDto`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userDtoDescriptor = $convert.base64Decode('CgdVc2VyRHRvEg4KAmlkGAEgASgFUgJpZBIaCgh1c2VybmFtZRgCIAEoCVIIdXNlcm5hbWUSFAoFZW1haWwYAyABKAlSBWVtYWlsEhwKCHBhc3N3b3JkGAQgASgJSABSCHBhc3N3b3JkEiMKDGltYWdlX2F2YXRhchgFIAEoCUgAUgtpbWFnZUF2YXRhckITChFvcHRpb25hbF9wYXNzd29yZA==');
@$core.Deprecated('Use tokensDtoDescriptor instead')
const TokensDto$json = const {
  '1': 'TokensDto',
  '2': const [
    const {'1': 'access_token', '3': 1, '4': 1, '5': 9, '10': 'accessToken'},
    const {'1': 'refresh_token', '3': 2, '4': 1, '5': 9, '10': 'refreshToken'},
  ],
};

/// Descriptor for `TokensDto`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tokensDtoDescriptor = $convert.base64Decode('CglUb2tlbnNEdG8SIQoMYWNjZXNzX3Rva2VuGAEgASgJUgthY2Nlc3NUb2tlbhIjCg1yZWZyZXNoX3Rva2VuGAIgASgJUgxyZWZyZXNoVG9rZW4=');
@$core.Deprecated('Use requestDtoDescriptor instead')
const RequestDto$json = const {
  '1': 'RequestDto',
};

/// Descriptor for `RequestDto`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestDtoDescriptor = $convert.base64Decode('CgpSZXF1ZXN0RHRv');
@$core.Deprecated('Use responseDtoDescriptor instead')
const ResponseDto$json = const {
  '1': 'ResponseDto',
  '2': const [
    const {'1': 'message', '3': 1, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ResponseDto`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseDtoDescriptor = $convert.base64Decode('CgtSZXNwb25zZUR0bxIYCgdtZXNzYWdlGAEgASgJUgdtZXNzYWdl');
@$core.Deprecated('Use fileDtoDescriptor instead')
const FileDto$json = const {
  '1': 'FileDto',
  '2': const [
    const {'1': 'data', '3': 1, '4': 1, '5': 12, '10': 'data'},
  ],
};

/// Descriptor for `FileDto`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileDtoDescriptor = $convert.base64Decode('CgdGaWxlRHRvEhIKBGRhdGEYASABKAxSBGRhdGE=');
