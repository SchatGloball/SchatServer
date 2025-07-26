import 'package:stormberry/stormberry.dart';

part 'reaction_message.schema.dart';

@Model()
abstract class ReactionMessage {
  @PrimaryKey()
  @AutoIncrement()
  int get id;
  String get body;
  int get authorId;
  String get authorName;
  int get stickerContent;
  DateTime get dateReaction;
}
