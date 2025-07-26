import 'package:stormberry/stormberry.dart';

import '../comment/comment.dart';

part 'post.schema.dart';

@Model()
abstract class Post {
  @PrimaryKey()
  @AutoIncrement()
  int get id;
  String get body;
  int get authorId;
  List<String> get tag;
  List<String> get content;
  String get authorName;
  int get stickerContent;
  DateTime get dateMessage;
  String get topik;
  List<String> get likes;
  List<Comment> get comment;
}
