// ignore_for_file: annotate_overrides

part of 'channel_group.dart';

extension ChannelGroupRepositories on Session {
  ChannelGroupRepository get channelGroups => ChannelGroupRepository._(this);
}

abstract class ChannelGroupRepository
    implements
        ModelRepository,
        KeyedModelRepositoryInsert<ChannelGroupInsertRequest>,
        ModelRepositoryUpdate<ChannelGroupUpdateRequest>,
        ModelRepositoryDelete<int> {
  factory ChannelGroupRepository._(Session db) = _ChannelGroupRepository;

  Future<ShortChannelGroupView?> queryShortView(int id);
  Future<List<ShortChannelGroupView>> queryShortViews([QueryParams? params]);
  Future<FullChannelGroupView?> queryFullView(int id);
  Future<List<FullChannelGroupView>> queryFullViews([QueryParams? params]);
}

class _ChannelGroupRepository extends BaseRepository
    with
        KeyedRepositoryInsertMixin<ChannelGroupInsertRequest>,
        RepositoryUpdateMixin<ChannelGroupUpdateRequest>,
        RepositoryDeleteMixin<int>
    implements ChannelGroupRepository {
  _ChannelGroupRepository(super.db) : super(tableName: 'channel_groups', keyName: 'id');

  @override
  Future<ShortChannelGroupView?> queryShortView(int id) {
    return queryOne(id, ShortChannelGroupViewQueryable());
  }

  @override
  Future<List<ShortChannelGroupView>> queryShortViews([QueryParams? params]) {
    return queryMany(ShortChannelGroupViewQueryable(), params);
  }

  @override
  Future<FullChannelGroupView?> queryFullView(int id) {
    return queryOne(id, FullChannelGroupViewQueryable());
  }

  @override
  Future<List<FullChannelGroupView>> queryFullViews([QueryParams? params]) {
    return queryMany(FullChannelGroupViewQueryable(), params);
  }

  @override
  Future<List<int>> insert(List<ChannelGroupInsertRequest> requests) async {
    if (requests.isEmpty) return [];
    var values = QueryValues();
    var rows = await db.execute(
      Sql.named(
          'INSERT INTO "channel_groups" ( "name", "author_id", "user_blog", "channel_image", "tag", "members", "topik" )\n'
          'VALUES ${requests.map((r) => '( ${values.add(r.name)}:text, ${values.add(r.authorId)}:int8, ${values.add(r.userBlog)}:boolean, ${values.add(r.channelImage)}:text, ${values.add(r.tag)}:_text, ${values.add(r.members)}:_text, ${values.add(r.topik)}:_text )').join(', ')}\n'
          'RETURNING "id"'),
      parameters: values.values,
    );
    var result = rows.map<int>((r) => TextEncoder.i.decode(r.toColumnMap()['id'])).toList();

    return result;
  }

  @override
  Future<void> update(List<ChannelGroupUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    var values = QueryValues();
    await db.execute(
      Sql.named('UPDATE "channel_groups"\n'
          'SET "name" = COALESCE(UPDATED."name", "channel_groups"."name"), "author_id" = COALESCE(UPDATED."author_id", "channel_groups"."author_id"), "user_blog" = COALESCE(UPDATED."user_blog", "channel_groups"."user_blog"), "channel_image" = COALESCE(UPDATED."channel_image", "channel_groups"."channel_image"), "tag" = COALESCE(UPDATED."tag", "channel_groups"."tag"), "members" = COALESCE(UPDATED."members", "channel_groups"."members"), "topik" = COALESCE(UPDATED."topik", "channel_groups"."topik")\n'
          'FROM ( VALUES ${requests.map((r) => '( ${values.add(r.id)}:int8::int8, ${values.add(r.name)}:text::text, ${values.add(r.authorId)}:int8::int8, ${values.add(r.userBlog)}:boolean::boolean, ${values.add(r.channelImage)}:text::text, ${values.add(r.tag)}:_text::_text, ${values.add(r.members)}:_text::_text, ${values.add(r.topik)}:_text::_text )').join(', ')} )\n'
          'AS UPDATED("id", "name", "author_id", "user_blog", "channel_image", "tag", "members", "topik")\n'
          'WHERE "channel_groups"."id" = UPDATED."id"'),
      parameters: values.values,
    );
  }
}

class ChannelGroupInsertRequest {
  ChannelGroupInsertRequest({
    required this.name,
    required this.authorId,
    required this.userBlog,
    required this.channelImage,
    required this.tag,
    required this.members,
    required this.topik,
  });

  final String name;
  final int authorId;
  final bool userBlog;
  final String channelImage;
  final List<String> tag;
  final List<String> members;
  final List<String> topik;
}

class ChannelGroupUpdateRequest {
  ChannelGroupUpdateRequest({
    required this.id,
    this.name,
    this.authorId,
    this.userBlog,
    this.channelImage,
    this.tag,
    this.members,
    this.topik,
  });

  final int id;
  final String? name;
  final int? authorId;
  final bool? userBlog;
  final String? channelImage;
  final List<String>? tag;
  final List<String>? members;
  final List<String>? topik;
}

class ShortChannelGroupViewQueryable extends KeyedViewQueryable<ShortChannelGroupView, int> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(int key) => TextEncoder.i.encode(key);

  @override
  String get query => 'SELECT "channel_groups".*'
      'FROM "channel_groups"';

  @override
  String get tableAlias => 'channel_groups';

  @override
  ShortChannelGroupView decode(TypedMap map) => ShortChannelGroupView(
      id: map.get('id'),
      name: map.get('name'),
      authorId: map.get('author_id'),
      userBlog: map.get('user_blog'),
      channelImage: map.get('channel_image'),
      tag: map.getListOpt('tag') ?? const [],
      members: map.getListOpt('members') ?? const [],
      topik: map.getListOpt('topik') ?? const []);
}

class ShortChannelGroupView {
  ShortChannelGroupView({
    required this.id,
    required this.name,
    required this.authorId,
    required this.userBlog,
    required this.channelImage,
    required this.tag,
    required this.members,
    required this.topik,
  });

  final int id;
  final String name;
  final int authorId;
  final bool userBlog;
  final String channelImage;
  final List<String> tag;
  final List<String> members;
  final List<String> topik;
}

class FullChannelGroupViewQueryable extends KeyedViewQueryable<FullChannelGroupView, int> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(int key) => TextEncoder.i.encode(key);

  @override
  String get query => 'SELECT "channel_groups".*, "posts"."data" as "posts"'
      'FROM "channel_groups"'
      'LEFT JOIN ('
      '  SELECT "posts"."channel_group_id",'
      '    to_jsonb(array_agg("posts".*)) as data'
      '  FROM (${PostViewQueryable().query}) "posts"'
      '  GROUP BY "posts"."channel_group_id"'
      ') "posts"'
      'ON "channel_groups"."id" = "posts"."channel_group_id"';

  @override
  String get tableAlias => 'channel_groups';

  @override
  FullChannelGroupView decode(TypedMap map) => FullChannelGroupView(
      id: map.get('id'),
      name: map.get('name'),
      authorId: map.get('author_id'),
      userBlog: map.get('user_blog'),
      channelImage: map.get('channel_image'),
      tag: map.getListOpt('tag') ?? const [],
      members: map.getListOpt('members') ?? const [],
      topik: map.getListOpt('topik') ?? const [],
      posts: map.getListOpt('posts', PostViewQueryable().decoder) ?? const []);
}

class FullChannelGroupView {
  FullChannelGroupView({
    required this.id,
    required this.name,
    required this.authorId,
    required this.userBlog,
    required this.channelImage,
    required this.tag,
    required this.members,
    required this.topik,
    required this.posts,
  });

  final int id;
  final String name;
  final int authorId;
  final bool userBlog;
  final String channelImage;
  final List<String> tag;
  final List<String> members;
  final List<String> topik;
  final List<PostView> posts;
}
