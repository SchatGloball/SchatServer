// ignore_for_file: annotate_overrides

part of 'comment.dart';

extension CommentRepositories on Session {
  CommentRepository get comments => CommentRepository._(this);
}

abstract class CommentRepository
    implements
        ModelRepository,
        KeyedModelRepositoryInsert<CommentInsertRequest>,
        ModelRepositoryUpdate<CommentUpdateRequest>,
        ModelRepositoryDelete<int> {
  factory CommentRepository._(Session db) = _CommentRepository;

  Future<CommentView?> queryComment(int id);
  Future<List<CommentView>> queryComments([QueryParams? params]);
}

class _CommentRepository extends BaseRepository
    with
        KeyedRepositoryInsertMixin<CommentInsertRequest>,
        RepositoryUpdateMixin<CommentUpdateRequest>,
        RepositoryDeleteMixin<int>
    implements CommentRepository {
  _CommentRepository(super.db) : super(tableName: 'comments', keyName: 'id');

  @override
  Future<CommentView?> queryComment(int id) {
    return queryOne(id, CommentViewQueryable());
  }

  @override
  Future<List<CommentView>> queryComments([QueryParams? params]) {
    return queryMany(CommentViewQueryable(), params);
  }

  @override
  Future<List<int>> insert(List<CommentInsertRequest> requests) async {
    if (requests.isEmpty) return [];
    var values = QueryValues();
    var rows = await db.execute(
      Sql.named(
          'INSERT INTO "comments" ( "body", "author_id", "content", "author_name", "sticker_content", "date_comment", "likes", "post_id" )\n'
          'VALUES ${requests.map((r) => '( ${values.add(r.body)}:text, ${values.add(r.authorId)}:int8, ${values.add(r.content)}:_text, ${values.add(r.authorName)}:text, ${values.add(r.stickerContent)}:int8, ${values.add(r.dateComment)}:timestamp, ${values.add(r.likes)}:_text, ${values.add(r.postId)}:int8 )').join(', ')}\n'
          'RETURNING "id"'),
      parameters: values.values,
    );
    var result = rows.map<int>((r) => TextEncoder.i.decode(r.toColumnMap()['id'])).toList();

    return result;
  }

  @override
  Future<void> update(List<CommentUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    var values = QueryValues();
    await db.execute(
      Sql.named('UPDATE "comments"\n'
          'SET "body" = COALESCE(UPDATED."body", "comments"."body"), "author_id" = COALESCE(UPDATED."author_id", "comments"."author_id"), "content" = COALESCE(UPDATED."content", "comments"."content"), "author_name" = COALESCE(UPDATED."author_name", "comments"."author_name"), "sticker_content" = COALESCE(UPDATED."sticker_content", "comments"."sticker_content"), "date_comment" = COALESCE(UPDATED."date_comment", "comments"."date_comment"), "likes" = COALESCE(UPDATED."likes", "comments"."likes"), "post_id" = COALESCE(UPDATED."post_id", "comments"."post_id")\n'
          'FROM ( VALUES ${requests.map((r) => '( ${values.add(r.id)}:int8::int8, ${values.add(r.body)}:text::text, ${values.add(r.authorId)}:int8::int8, ${values.add(r.content)}:_text::_text, ${values.add(r.authorName)}:text::text, ${values.add(r.stickerContent)}:int8::int8, ${values.add(r.dateComment)}:timestamp::timestamp, ${values.add(r.likes)}:_text::_text, ${values.add(r.postId)}:int8::int8 )').join(', ')} )\n'
          'AS UPDATED("id", "body", "author_id", "content", "author_name", "sticker_content", "date_comment", "likes", "post_id")\n'
          'WHERE "comments"."id" = UPDATED."id"'),
      parameters: values.values,
    );
  }
}

class CommentInsertRequest {
  CommentInsertRequest({
    required this.body,
    required this.authorId,
    required this.content,
    required this.authorName,
    required this.stickerContent,
    required this.dateComment,
    required this.likes,
    this.postId,
  });

  final String body;
  final int authorId;
  final List<String> content;
  final String authorName;
  final int stickerContent;
  final DateTime dateComment;
  final List<String> likes;
  final int? postId;
}

class CommentUpdateRequest {
  CommentUpdateRequest({
    required this.id,
    this.body,
    this.authorId,
    this.content,
    this.authorName,
    this.stickerContent,
    this.dateComment,
    this.likes,
    this.postId,
  });

  final int id;
  final String? body;
  final int? authorId;
  final List<String>? content;
  final String? authorName;
  final int? stickerContent;
  final DateTime? dateComment;
  final List<String>? likes;
  final int? postId;
}

class CommentViewQueryable extends KeyedViewQueryable<CommentView, int> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(int key) => TextEncoder.i.encode(key);

  @override
  String get query => 'SELECT "comments".*'
      'FROM "comments"';

  @override
  String get tableAlias => 'comments';

  @override
  CommentView decode(TypedMap map) => CommentView(
      id: map.get('id'),
      body: map.get('body'),
      authorId: map.get('author_id'),
      content: map.getListOpt('content') ?? const [],
      authorName: map.get('author_name'),
      stickerContent: map.get('sticker_content'),
      dateComment: map.get('date_comment'),
      likes: map.getListOpt('likes') ?? const []);
}

class CommentView {
  CommentView({
    required this.id,
    required this.body,
    required this.authorId,
    required this.content,
    required this.authorName,
    required this.stickerContent,
    required this.dateComment,
    required this.likes,
  });

  final int id;
  final String body;
  final int authorId;
  final List<String> content;
  final String authorName;
  final int stickerContent;
  final DateTime dateComment;
  final List<String> likes;
}
