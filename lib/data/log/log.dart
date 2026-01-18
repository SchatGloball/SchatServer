import 'package:stormberry/stormberry.dart';

part 'log.schema.dart';

@Model()
abstract class Log {
  @PrimaryKey()
  @AutoIncrement()
  int get id;
  String get body;
  int get userId;
  bool get error;
  DateTime get date;
}