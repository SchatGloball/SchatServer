// ignore_for_file: annotate_overrides

part of 'log.dart';

extension LogRepositories on Session {
  LogRepository get logs => LogRepository._(this);
}

abstract class LogRepository
    implements
        ModelRepository,
        KeyedModelRepositoryInsert<LogInsertRequest>,
        ModelRepositoryUpdate<LogUpdateRequest>,
        ModelRepositoryDelete<int> {
  factory LogRepository._(Session db) = _LogRepository;

  Future<LogView?> queryLog(int id);
  Future<List<LogView>> queryLogs([QueryParams? params]);
}

class _LogRepository extends BaseRepository
    with
        KeyedRepositoryInsertMixin<LogInsertRequest>,
        RepositoryUpdateMixin<LogUpdateRequest>,
        RepositoryDeleteMixin<int>
    implements LogRepository {
  _LogRepository(super.db) : super(tableName: 'logs', keyName: 'id');

  @override
  Future<LogView?> queryLog(int id) {
    return queryOne(id, LogViewQueryable());
  }

  @override
  Future<List<LogView>> queryLogs([QueryParams? params]) {
    return queryMany(LogViewQueryable(), params);
  }

  @override
  Future<List<int>> insert(List<LogInsertRequest> requests) async {
    if (requests.isEmpty) return [];
    var values = QueryValues();
    var rows = await db.execute(
      Sql.named('INSERT INTO "logs" ( "body", "user_id", "error", "date" )\n'
          'VALUES ${requests.map((r) => '( ${values.add(r.body)}:text, ${values.add(r.userId)}:int8, ${values.add(r.error)}:boolean, ${values.add(r.date)}:timestamp )').join(', ')}\n'
          'RETURNING "id"'),
      parameters: values.values,
    );
    var result = rows.map<int>((r) => TextEncoder.i.decode(r.toColumnMap()['id'])).toList();

    return result;
  }

  @override
  Future<void> update(List<LogUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    var values = QueryValues();
    await db.execute(
      Sql.named('UPDATE "logs"\n'
          'SET "body" = COALESCE(UPDATED."body", "logs"."body"), "user_id" = COALESCE(UPDATED."user_id", "logs"."user_id"), "error" = COALESCE(UPDATED."error", "logs"."error"), "date" = COALESCE(UPDATED."date", "logs"."date")\n'
          'FROM ( VALUES ${requests.map((r) => '( ${values.add(r.id)}:int8::int8, ${values.add(r.body)}:text::text, ${values.add(r.userId)}:int8::int8, ${values.add(r.error)}:boolean::boolean, ${values.add(r.date)}:timestamp::timestamp )').join(', ')} )\n'
          'AS UPDATED("id", "body", "user_id", "error", "date")\n'
          'WHERE "logs"."id" = UPDATED."id"'),
      parameters: values.values,
    );
  }
}

class LogInsertRequest {
  LogInsertRequest({
    required this.body,
    required this.userId,
    required this.error,
    required this.date,
  });

  final String body;
  final int userId;
  final bool error;
  final DateTime date;
}

class LogUpdateRequest {
  LogUpdateRequest({
    required this.id,
    this.body,
    this.userId,
    this.error,
    this.date,
  });

  final int id;
  final String? body;
  final int? userId;
  final bool? error;
  final DateTime? date;
}

class LogViewQueryable extends KeyedViewQueryable<LogView, int> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(int key) => TextEncoder.i.encode(key);

  @override
  String get query => 'SELECT "logs".*'
      'FROM "logs"';

  @override
  String get tableAlias => 'logs';

  @override
  LogView decode(TypedMap map) => LogView(
      id: map.get('id'),
      body: map.get('body'),
      userId: map.get('user_id'),
      error: map.get('error'),
      date: map.get('date'));
}

class LogView {
  LogView({
    required this.id,
    required this.body,
    required this.userId,
    required this.error,
    required this.date,
  });

  final int id;
  final String body;
  final int userId;
  final bool error;
  final DateTime date;
}
