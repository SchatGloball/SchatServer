// ignore_for_file: annotate_overrides

part of 'user.dart';

extension UserRepositories on Session {
  UserRepository get users => UserRepository._(this);
}

abstract class UserRepository
    implements
        ModelRepository,
        KeyedModelRepositoryInsert<UserInsertRequest>,
        ModelRepositoryUpdate<UserUpdateRequest>,
        ModelRepositoryDelete<int> {
  factory UserRepository._(Session db) = _UserRepository;

  Future<UserView?> queryUser(int id);
  Future<List<UserView>> queryUsers([QueryParams? params]);
}

class _UserRepository extends BaseRepository
    with
        KeyedRepositoryInsertMixin<UserInsertRequest>,
        RepositoryUpdateMixin<UserUpdateRequest>,
        RepositoryDeleteMixin<int>
    implements UserRepository {
  _UserRepository(super.db) : super(tableName: 'users', keyName: 'id');

  @override
  Future<UserView?> queryUser(int id) {
    return queryOne(id, UserViewQueryable());
  }

  @override
  Future<List<UserView>> queryUsers([QueryParams? params]) {
    return queryMany(UserViewQueryable(), params);
  }

  @override
  Future<List<int>> insert(List<UserInsertRequest> requests) async {
    if (requests.isEmpty) return [];
    var values = QueryValues();
    var rows = await db.execute(
      Sql.named(
          'INSERT INTO "users" ( "username", "email", "password", "image_avatar", "is_bot", "name_creator" )\n'
          'VALUES ${requests.map((r) => '( ${values.add(r.username)}:text, ${values.add(r.email)}:text, ${values.add(r.password)}:text, ${values.add(r.imageAvatar)}:text, ${values.add(r.isBot)}:boolean, ${values.add(r.nameCreator)}:text )').join(', ')}\n'
          'RETURNING "id"'),
      parameters: values.values,
    );
    var result = rows.map<int>((r) => TextEncoder.i.decode(r.toColumnMap()['id'])).toList();

    return result;
  }

  @override
  Future<void> update(List<UserUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    var values = QueryValues();
    await db.execute(
      Sql.named('UPDATE "users"\n'
          'SET "username" = COALESCE(UPDATED."username", "users"."username"), "email" = COALESCE(UPDATED."email", "users"."email"), "password" = COALESCE(UPDATED."password", "users"."password"), "image_avatar" = COALESCE(UPDATED."image_avatar", "users"."image_avatar"), "is_bot" = COALESCE(UPDATED."is_bot", "users"."is_bot"), "name_creator" = COALESCE(UPDATED."name_creator", "users"."name_creator")\n'
          'FROM ( VALUES ${requests.map((r) => '( ${values.add(r.id)}:int8::int8, ${values.add(r.username)}:text::text, ${values.add(r.email)}:text::text, ${values.add(r.password)}:text::text, ${values.add(r.imageAvatar)}:text::text, ${values.add(r.isBot)}:boolean::boolean, ${values.add(r.nameCreator)}:text::text )').join(', ')} )\n'
          'AS UPDATED("id", "username", "email", "password", "image_avatar", "is_bot", "name_creator")\n'
          'WHERE "users"."id" = UPDATED."id"'),
      parameters: values.values,
    );
  }
}

class UserInsertRequest {
  UserInsertRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.imageAvatar,
    required this.isBot,
    required this.nameCreator,
  });

  final String username;
  final String email;
  final String password;
  final String imageAvatar;
  final bool isBot;
  final String nameCreator;
}

class UserUpdateRequest {
  UserUpdateRequest({
    required this.id,
    this.username,
    this.email,
    this.password,
    this.imageAvatar,
    this.isBot,
    this.nameCreator,
  });

  final int id;
  final String? username;
  final String? email;
  final String? password;
  final String? imageAvatar;
  final bool? isBot;
  final String? nameCreator;
}

class UserViewQueryable extends KeyedViewQueryable<UserView, int> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(int key) => TextEncoder.i.encode(key);

  @override
  String get query => 'SELECT "users".*'
      'FROM "users"';

  @override
  String get tableAlias => 'users';

  @override
  UserView decode(TypedMap map) => UserView(
      id: map.get('id'),
      username: map.get('username'),
      email: map.get('email'),
      password: map.get('password'),
      imageAvatar: map.get('image_avatar'),
      isBot: map.get('is_bot'),
      nameCreator: map.get('name_creator'));
}

class UserView {
  UserView({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.imageAvatar,
    required this.isBot,
    required this.nameCreator,
  });

  final int id;
  final String username;
  final String email;
  final String password;
  final String imageAvatar;
  final bool isBot;
  final String nameCreator;
}
