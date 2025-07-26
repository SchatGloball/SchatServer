// ignore_for_file: annotate_overrides

part of 'reaction_message.dart';

extension ReactionMessageRepositories on Session {
  ReactionMessageRepository get reactionMessages => ReactionMessageRepository._(this);
}

abstract class ReactionMessageRepository
    implements
        ModelRepository,
        KeyedModelRepositoryInsert<ReactionMessageInsertRequest>,
        ModelRepositoryUpdate<ReactionMessageUpdateRequest>,
        ModelRepositoryDelete<int> {
  factory ReactionMessageRepository._(Session db) = _ReactionMessageRepository;

  Future<ReactionMessageView?> queryReactionMessage(int id);
  Future<List<ReactionMessageView>> queryReactionMessages([QueryParams? params]);
}

class _ReactionMessageRepository extends BaseRepository
    with
        KeyedRepositoryInsertMixin<ReactionMessageInsertRequest>,
        RepositoryUpdateMixin<ReactionMessageUpdateRequest>,
        RepositoryDeleteMixin<int>
    implements ReactionMessageRepository {
  _ReactionMessageRepository(super.db) : super(tableName: 'reaction_messages', keyName: 'id');

  @override
  Future<ReactionMessageView?> queryReactionMessage(int id) {
    return queryOne(id, ReactionMessageViewQueryable());
  }

  @override
  Future<List<ReactionMessageView>> queryReactionMessages([QueryParams? params]) {
    return queryMany(ReactionMessageViewQueryable(), params);
  }

  @override
  Future<List<int>> insert(List<ReactionMessageInsertRequest> requests) async {
    if (requests.isEmpty) return [];
    var values = QueryValues();
    var rows = await db.execute(
      Sql.named(
          'INSERT INTO "reaction_messages" ( "body", "author_id", "author_name", "sticker_content", "date_reaction", "message_id" )\n'
          'VALUES ${requests.map((r) => '( ${values.add(r.body)}:text, ${values.add(r.authorId)}:int8, ${values.add(r.authorName)}:text, ${values.add(r.stickerContent)}:int8, ${values.add(r.dateReaction)}:timestamp, ${values.add(r.messageId)}:int8 )').join(', ')}\n'
          'RETURNING "id"'),
      parameters: values.values,
    );
    var result = rows.map<int>((r) => TextEncoder.i.decode(r.toColumnMap()['id'])).toList();

    return result;
  }

  @override
  Future<void> update(List<ReactionMessageUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    var values = QueryValues();
    await db.execute(
      Sql.named('UPDATE "reaction_messages"\n'
          'SET "body" = COALESCE(UPDATED."body", "reaction_messages"."body"), "author_id" = COALESCE(UPDATED."author_id", "reaction_messages"."author_id"), "author_name" = COALESCE(UPDATED."author_name", "reaction_messages"."author_name"), "sticker_content" = COALESCE(UPDATED."sticker_content", "reaction_messages"."sticker_content"), "date_reaction" = COALESCE(UPDATED."date_reaction", "reaction_messages"."date_reaction"), "message_id" = COALESCE(UPDATED."message_id", "reaction_messages"."message_id")\n'
          'FROM ( VALUES ${requests.map((r) => '( ${values.add(r.id)}:int8::int8, ${values.add(r.body)}:text::text, ${values.add(r.authorId)}:int8::int8, ${values.add(r.authorName)}:text::text, ${values.add(r.stickerContent)}:int8::int8, ${values.add(r.dateReaction)}:timestamp::timestamp, ${values.add(r.messageId)}:int8::int8 )').join(', ')} )\n'
          'AS UPDATED("id", "body", "author_id", "author_name", "sticker_content", "date_reaction", "message_id")\n'
          'WHERE "reaction_messages"."id" = UPDATED."id"'),
      parameters: values.values,
    );
  }
}

class ReactionMessageInsertRequest {
  ReactionMessageInsertRequest({
    required this.body,
    required this.authorId,
    required this.authorName,
    required this.stickerContent,
    required this.dateReaction,
    this.messageId,
  });

  final String body;
  final int authorId;
  final String authorName;
  final int stickerContent;
  final DateTime dateReaction;
  final int? messageId;
}

class ReactionMessageUpdateRequest {
  ReactionMessageUpdateRequest({
    required this.id,
    this.body,
    this.authorId,
    this.authorName,
    this.stickerContent,
    this.dateReaction,
    this.messageId,
  });

  final int id;
  final String? body;
  final int? authorId;
  final String? authorName;
  final int? stickerContent;
  final DateTime? dateReaction;
  final int? messageId;
}

class ReactionMessageViewQueryable extends KeyedViewQueryable<ReactionMessageView, int> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(int key) => TextEncoder.i.encode(key);

  @override
  String get query => 'SELECT "reaction_messages".*'
      'FROM "reaction_messages"';

  @override
  String get tableAlias => 'reaction_messages';

  @override
  ReactionMessageView decode(TypedMap map) => ReactionMessageView(
      id: map.get('id'),
      body: map.get('body'),
      authorId: map.get('author_id'),
      authorName: map.get('author_name'),
      stickerContent: map.get('sticker_content'),
      dateReaction: map.get('date_reaction'));
}

class ReactionMessageView {
  ReactionMessageView({
    required this.id,
    required this.body,
    required this.authorId,
    required this.authorName,
    required this.stickerContent,
    required this.dateReaction,
  });

  final int id;
  final String body;
  final int authorId;
  final String authorName;
  final int stickerContent;
  final DateTime dateReaction;
}
