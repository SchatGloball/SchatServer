import 'package:stormberry/stormberry.dart';

part 'comment.schema.dart';

@Model()
abstract class Comment {
  @PrimaryKey()
  @AutoIncrement()
  int get id;
  String get body;
  int get authorId;
  List<String> get content;
  String get authorName;
  int get stickerContent;
  DateTime get dateComment;
  List<String> get likes;
}