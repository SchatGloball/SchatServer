// ignore_for_file: annotate_overrides

part of 'post.dart';

extension PostRepositories on Session {
  PostRepository get posts => PostRepository._(this);
}

abstract class PostRepository
    implements
        ModelRepository,
        KeyedModelRepositoryInsert<PostInsertRequest>,
        ModelRepositoryUpdate<PostUpdateRequest>,
        ModelRepositoryDelete<int> {
  factory PostRepository._(Session db) = _PostRepository;

  Future<PostView?> queryPost(int id);
  Future<List<PostView>> queryPosts([QueryParams? params]);
}

class _PostRepository extends BaseRepository
    with
        KeyedRepositoryInsertMixin<PostInsertRequest>,
        RepositoryUpdateMixin<PostUpdateRequest>,
        RepositoryDeleteMixin<int>
    implements PostRepository {
  _PostRepository(super.db) : super(tableName: 'posts', keyName: 'id');

  @override
  Future<PostView?> queryPost(int id) {
    return queryOne(id, PostViewQueryable());
  }

  @override
  Future<List<PostView>> queryPosts([QueryParams? params]) {
    return queryMany(PostViewQueryable(), params);
  }

  @override
  Future<List<int>> insert(List<PostInsertRequest> requests) async {
    if (requests.isEmpty) return [];
    var values = QueryValues();
    var rows = await db.execute(
      Sql.named(
          'INSERT INTO "posts" ( "body", "author_id", "tag", "content", "author_name", "sticker_content", "date_message", "topik", "likes", "channel_group_id" )\n'
          'VALUES ${requests.map((r) => '( ${values.add(r.body)}:text, ${values.add(r.authorId)}:int8, ${values.add(r.tag)}:_text, ${values.add(r.content)}:_text, ${values.add(r.authorName)}:text, ${values.add(r.stickerContent)}:int8, ${values.add(r.dateMessage)}:timestamp, ${values.add(r.topik)}:text, ${values.add(r.likes)}:_text, ${values.add(r.channelGroupId)}:int8 )').join(', ')}\n'
          'RETURNING "id"'),
      parameters: values.values,
    );
    var result = rows.map<int>((r) => TextEncoder.i.decode(r.toColumnMap()['id'])).toList();

    return result;
  }

  @override
  Future<void> update(List<PostUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    var values = QueryValues();
    await db.execute(
      Sql.named('UPDATE "posts"\n'
          'SET "body" = COALESCE(UPDATED."body", "posts"."body"), "author_id" = COALESCE(UPDATED."author_id", "posts"."author_id"), "tag" = COALESCE(UPDATED."tag", "posts"."tag"), "content" = COALESCE(UPDATED."content", "posts"."content"), "author_name" = COALESCE(UPDATED."author_name", "posts"."author_name"), "sticker_content" = COALESCE(UPDATED."sticker_content", "posts"."sticker_content"), "date_message" = COALESCE(UPDATED."date_message", "posts"."date_message"), "topik" = COALESCE(UPDATED."topik", "posts"."topik"), "likes" = COALESCE(UPDATED."likes", "posts"."likes"), "channel_group_id" = COALESCE(UPDATED."channel_group_id", "posts"."channel_group_id")\n'
          'FROM ( VALUES ${requests.map((r) => '( ${values.add(r.id)}:int8::int8, ${values.add(r.body)}:text::text, ${values.add(r.authorId)}:int8::int8, ${values.add(r.tag)}:_text::_text, ${values.add(r.content)}:_text::_text, ${values.add(r.authorName)}:text::text, ${values.add(r.stickerContent)}:int8::int8, ${values.add(r.dateMessage)}:timestamp::timestamp, ${values.add(r.topik)}:text::text, ${values.add(r.likes)}:_text::_text, ${values.add(r.channelGroupId)}:int8::int8 )').join(', ')} )\n'
          'AS UPDATED("id", "body", "author_id", "tag", "content", "author_name", "sticker_content", "date_message", "topik", "likes", "channel_group_id")\n'
          'WHERE "posts"."id" = UPDATED."id"'),
      parameters: values.values,
    );
  }
}

class PostInsertRequest {
  PostInsertRequest({
    required this.body,
    required this.authorId,
    required this.tag,
    required this.content,
    required this.authorName,
    required this.stickerContent,
    required this.dateMessage,
    required this.topik,
    required this.likes,
    this.channelGroupId,
  });

  final String body;
  final int authorId;
  final List<String> tag;
  final List<String> content;
  final String authorName;
  final int stickerContent;
  final DateTime dateMessage;
  final String topik;
  final List<String> likes;
  final int? channelGroupId;
}

class PostUpdateRequest {
  PostUpdateRequest({
    required this.id,
    this.body,
    this.authorId,
    this.tag,
    this.content,
    this.authorName,
    this.stickerContent,
    this.dateMessage,
    this.topik,
    this.likes,
    this.channelGroupId,
  });

  final int id;
  final String? body;
  final int? authorId;
  final List<String>? tag;
  final List<String>? content;
  final String? authorName;
  final int? stickerContent;
  final DateTime? dateMessage;
  final String? topik;
  final List<String>? likes;
  final int? channelGroupId;
}

class PostViewQueryable extends KeyedViewQueryable<PostView, int> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(int key) => TextEncoder.i.encode(key);

  @override
  String get query => 'SELECT "posts".*, "comment"."data" as "comment"'
      'FROM "posts"'
      'LEFT JOIN ('
      '  SELECT "comments"."post_id",'
      '    to_jsonb(array_agg("comments".*)) as data'
      '  FROM (${CommentViewQueryable().query}) "comments"'
      '  GROUP BY "comments"."post_id"'
      ') "comment"'
      'ON "posts"."id" = "comment"."post_id"';

  @override
  String get tableAlias => 'posts';

  @override
  PostView decode(TypedMap map) => PostView(
      id: map.get('id'),
      body: map.get('body'),
      comment: map.getListOpt('comment', CommentViewQueryable().decoder) ?? const [],
      authorId: map.get('author_id'),
      tag: map.getListOpt('tag') ?? const [],
      content: map.getListOpt('content') ?? const [],
      authorName: map.get('author_name'),
      stickerContent: map.get('sticker_content'),
      dateMessage: map.get('date_message'),
      topik: map.get('topik'),
      likes: map.getListOpt('likes') ?? const []);
}

class PostView {
  PostView({
    required this.id,
    required this.body,
    required this.comment,
    required this.authorId,
    required this.tag,
    required this.content,
    required this.authorName,
    required this.stickerContent,
    required this.dateMessage,
    required this.topik,
    required this.likes,
  });

  final int id;
  final String body;
  final List<CommentView> comment;
  final int authorId;
  final List<String> tag;
  final List<String> content;
  final String authorName;
  final int stickerContent;
  final DateTime dateMessage;
  final String topik;
  final List<String> likes;
}
