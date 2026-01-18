// ignore_for_file: annotate_overrides

part of 'message.dart';

extension MessageRepositories on Session {
  MessageRepository get messages => MessageRepository._(this);
}

abstract class MessageRepository
    implements
        ModelRepository,
        KeyedModelRepositoryInsert<MessageInsertRequest>,
        ModelRepositoryUpdate<MessageUpdateRequest>,
        ModelRepositoryDelete<int> {
  factory MessageRepository._(Session db) = _MessageRepository;

  Future<MessageView?> queryMessage(int id);
  Future<List<MessageView>> queryMessages([QueryParams? params]);
}

class _MessageRepository extends BaseRepository
    with
        KeyedRepositoryInsertMixin<MessageInsertRequest>,
        RepositoryUpdateMixin<MessageUpdateRequest>,
        RepositoryDeleteMixin<int>
    implements MessageRepository {
  _MessageRepository(super.db) : super(tableName: 'messages', keyName: 'id');

  @override
  Future<MessageView?> queryMessage(int id) {
    return queryOne(id, MessageViewQueryable());
  }

  @override
  Future<List<MessageView>> queryMessages([QueryParams? params]) {
    return queryMany(MessageViewQueryable(), params);
  }

  @override
  Future<List<int>> insert(List<MessageInsertRequest> requests) async {
    if (requests.isEmpty) return [];
    var values = QueryValues();
    var rows = await db.execute(
      Sql.named(
          'INSERT INTO "messages" ( "body", "original_date", "forwarded", "author_id", "content", "button", "author_name", "sticker_content", "date_message", "delivered", "original_author", "chat_id" )\n'
          'VALUES ${requests.map((r) => '( ${values.add(r.body)}:text, ${values.add(r.originalDate)}:timestamp, ${values.add(r.forwarded)}:boolean, ${values.add(r.authorId)}:int8, ${values.add(r.content)}:_text, ${values.add(r.button)}:_text, ${values.add(r.authorName)}:text, ${values.add(r.stickerContent)}:int8, ${values.add(r.dateMessage)}:timestamp, ${values.add(r.delivered)}:boolean, ${values.add(r.originalAuthor)}:text, ${values.add(r.chatId)}:int8 )').join(', ')}\n'
          'RETURNING "id"'),
      parameters: values.values,
    );
    var result = rows.map<int>((r) => TextEncoder.i.decode(r.toColumnMap()['id'])).toList();

    return result;
  }

  @override
  Future<void> update(List<MessageUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    var values = QueryValues();
    await db.execute(
      Sql.named('UPDATE "messages"\n'
          'SET "body" = COALESCE(UPDATED."body", "messages"."body"), "original_date" = COALESCE(UPDATED."original_date", "messages"."original_date"), "forwarded" = COALESCE(UPDATED."forwarded", "messages"."forwarded"), "author_id" = COALESCE(UPDATED."author_id", "messages"."author_id"), "content" = COALESCE(UPDATED."content", "messages"."content"), "button" = COALESCE(UPDATED."button", "messages"."button"), "author_name" = COALESCE(UPDATED."author_name", "messages"."author_name"), "sticker_content" = COALESCE(UPDATED."sticker_content", "messages"."sticker_content"), "date_message" = COALESCE(UPDATED."date_message", "messages"."date_message"), "delivered" = COALESCE(UPDATED."delivered", "messages"."delivered"), "original_author" = COALESCE(UPDATED."original_author", "messages"."original_author"), "chat_id" = COALESCE(UPDATED."chat_id", "messages"."chat_id")\n'
          'FROM ( VALUES ${requests.map((r) => '( ${values.add(r.id)}:int8::int8, ${values.add(r.body)}:text::text, ${values.add(r.originalDate)}:timestamp::timestamp, ${values.add(r.forwarded)}:boolean::boolean, ${values.add(r.authorId)}:int8::int8, ${values.add(r.content)}:_text::_text, ${values.add(r.button)}:_text::_text, ${values.add(r.authorName)}:text::text, ${values.add(r.stickerContent)}:int8::int8, ${values.add(r.dateMessage)}:timestamp::timestamp, ${values.add(r.delivered)}:boolean::boolean, ${values.add(r.originalAuthor)}:text::text, ${values.add(r.chatId)}:int8::int8 )').join(', ')} )\n'
          'AS UPDATED("id", "body", "original_date", "forwarded", "author_id", "content", "button", "author_name", "sticker_content", "date_message", "delivered", "original_author", "chat_id")\n'
          'WHERE "messages"."id" = UPDATED."id"'),
      parameters: values.values,
    );
  }
}

class MessageInsertRequest {
  MessageInsertRequest({
    required this.body,
    required this.originalDate,
    required this.forwarded,
    required this.authorId,
    required this.content,
    required this.button,
    required this.authorName,
    required this.stickerContent,
    required this.dateMessage,
    required this.delivered,
    required this.originalAuthor,
    this.chatId,
  });

  final String body;
  final DateTime originalDate;
  final bool forwarded;
  final int authorId;
  final List<String> content;
  final List<String> button;
  final String authorName;
  final int stickerContent;
  final DateTime dateMessage;
  final bool delivered;
  final String originalAuthor;
  final int? chatId;
}

class MessageUpdateRequest {
  MessageUpdateRequest({
    required this.id,
    this.body,
    this.originalDate,
    this.forwarded,
    this.authorId,
    this.content,
    this.button,
    this.authorName,
    this.stickerContent,
    this.dateMessage,
    this.delivered,
    this.originalAuthor,
    this.chatId,
  });

  final int id;
  final String? body;
  final DateTime? originalDate;
  final bool? forwarded;
  final int? authorId;
  final List<String>? content;
  final List<String>? button;
  final String? authorName;
  final int? stickerContent;
  final DateTime? dateMessage;
  final bool? delivered;
  final String? originalAuthor;
  final int? chatId;
}

class MessageViewQueryable extends KeyedViewQueryable<MessageView, int> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(int key) => TextEncoder.i.encode(key);

  @override
  String get query => 'SELECT "messages".*, "reaction"."data" as "reaction"'
      'FROM "messages"'
      'LEFT JOIN ('
      '  SELECT "reaction_messages"."message_id",'
      '    to_jsonb(array_agg("reaction_messages".*)) as data'
      '  FROM (${ReactionMessageViewQueryable().query}) "reaction_messages"'
      '  GROUP BY "reaction_messages"."message_id"'
      ') "reaction"'
      'ON "messages"."id" = "reaction"."message_id"';

  @override
  String get tableAlias => 'messages';

  @override
  MessageView decode(TypedMap map) => MessageView(
      id: map.get('id'),
      body: map.get('body'),
      originalDate: map.get('original_date'),
      forwarded: map.get('forwarded'),
      reaction: map.getListOpt('reaction', ReactionMessageViewQueryable().decoder) ?? const [],
      authorId: map.get('author_id'),
      content: map.getListOpt('content') ?? const [],
      button: map.getListOpt('button') ?? const [],
      authorName: map.get('author_name'),
      stickerContent: map.get('sticker_content'),
      dateMessage: map.get('date_message'),
      delivered: map.get('delivered'),
      originalAuthor: map.get('original_author'));
}

class MessageView {
  MessageView({
    required this.id,
    required this.body,
    required this.originalDate,
    required this.forwarded,
    required this.reaction,
    required this.authorId,
    required this.content,
    required this.button,
    required this.authorName,
    required this.stickerContent,
    required this.dateMessage,
    required this.delivered,
    required this.originalAuthor,
  });

  final int id;
  final String body;
  final DateTime originalDate;
  final bool forwarded;
  final List<ReactionMessageView> reaction;
  final int authorId;
  final List<String> content;
  final List<String> button;
  final String authorName;
  final int stickerContent;
  final DateTime dateMessage;
  final bool delivered;
  final String originalAuthor;
}
