import 'package:schat_api/data/reaction_message/reaction_message.dart';
import 'package:stormberry/stormberry.dart';

part 'message.schema.dart';

@Model()
abstract class Message {
  @PrimaryKey()
  @AutoIncrement()
  int get id;
  String get body;
  int get authorId;
  List<String> get content;
  String get authorName;
  int get stickerContent;
  DateTime get dateMessage;
  bool get delivered;
  String get originalAuthor;
  DateTime get originalDate;
  bool get forwarded;
  List<ReactionMessage> get reaction;
}
