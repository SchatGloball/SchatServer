import 'package:stormberry/stormberry.dart';

import '../post/post.dart';

part 'channel_group.schema.dart';

@Model(views: [#Short, #Full])
abstract class ChannelGroup {
  @PrimaryKey()
  @AutoIncrement()
  int get id;
  String get name;
  int get authorId;
  bool get userBlog;
  String get channelImage;
  List<String> get tag;
  List<String> get members;
  List<String> get topik;
  
  @HiddenIn(#Short)
  List<Post> get posts;
}
