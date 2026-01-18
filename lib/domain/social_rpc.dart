import 'dart:convert';
import 'dart:typed_data';
import 'package:grpc/grpc.dart';
import 'package:schat_api/data/comment/comment.dart';
import 'package:schat_api/data/db.dart';
import 'package:schat_api/data/post/post.dart';
import 'package:schat_api/data/user/user.dart';
import 'package:schat_api/data/channel_group/channel_group.dart';
import 'package:schat_api/generated/social.pbgrpc.dart';
import 'package:schat_api/utils.dart';
import 'package:stormberry/stormberry.dart';
import 'package:uuid/uuid.dart';

import '../env.dart';

class SocialRpc extends SocialRpcServiceBase {
  var uuid = Uuid();

  @override
  Future<ResponseDto> createChanel(ServiceCall call, ChannelDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.invalidArgument('Remove user');
    }

    if (request.name.isEmpty) {
      throw GrpcError.invalidArgument('Chat name not found');
    }
    List<String> members = [];
    if (!members.contains(user.username)) {
      members.add(user.username);
    }

    final List<ShortChannelGroupView> povtorChannel = await db.channelGroups
        .queryShortViews(QueryParams(where: "name='${request.name}'"));
    if (povtorChannel.isNotEmpty) {
      throw GrpcError.invalidArgument('Channel exist');
    }

    if (!request.topik.contains('general')) {
      request.topik.add('general');
    }
    String nameImage = '';
    if (request.image.isNotEmpty) {
      nameImage = uuid.v8();
      await storage.putFile(
          bucket: env.chatsBucket,
          name: nameImage,
          data: request.image as Uint8List);
    }
    int idChat = await db.channelGroups.insertOne(ChannelGroupInsertRequest(
        name: request.name,
        authorId: user.id,
        channelImage: nameImage,
        tag: request.tags,
        members: [user.username],
        topik: request.topik,
        userBlog: false));
    return ResponseDto(message: idChat.toString(), success: true);
  }

  @override
  Future<ResponseDto> createComment(
      ServiceCall call, CommentDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.invalidArgument('Remove user');
    }

    List<String> content = [];
    for (int i = 0; i < request.data.length; i++) {
      final String name = '${uuid.v8()}.separated.${request.content[i]}';
      await storage.putFile(
          bucket: env.chatsBucket,
          name: name,
          data: request.data[i] as Uint8List);
      content.add(name);
    }

    PostView? post = await db.posts.queryPost(request.postId);
    int idComment = await db.comments.insertOne(CommentInsertRequest(
        body: request.body,
        authorId: user.id,
        content: content,
        authorName: user.username,
        stickerContent: request.stickerContent,
        dateComment: DateTime.now(),
        likes: [],
        postId: post!.id));
    return ResponseDto(success: true, message: idComment.toString());
  }

  @override
  Future<ResponseDto> createPost(ServiceCall call, PostDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.invalidArgument('Remove user');
    }
    int channelGroupId = request.channelId;
    if (request.channelId == -1) {
      List<ShortChannelGroupView> listGroup = await db.channelGroups
          .queryShortViews(
              QueryParams(where: "author_id='${user.id}' AND user_blog=true"));
      if (listGroup.isEmpty) {
        channelGroupId = await db.channelGroups.insertOne(
            ChannelGroupInsertRequest(
                name: '${user.username}UserBlog',
                authorId: user.id,
                userBlog: true,
                channelImage: '',
                tag: [user.username],
                members: [],
                topik: ['general']));
      } else {
        channelGroupId = listGroup.first.id;
      }
    }
    List<String> content = [];

    for (int i = 0; i < request.data.length; i++) {
      final String name = '${uuid.v8()}.separated.${request.content[i]}';
      await storage.putFile(
          bucket: env.chatsBucket,
          name: name,
          data: request.data[i] as Uint8List);
      content.add(name);
    }
    int postId = await db.posts.insertOne(PostInsertRequest(
        body: request.body,
        authorId: user.id,
        tag: request.tags,
        content: content,
        authorName: user.username,
        stickerContent: request.stickerContent,
        dateMessage: DateTime.now(),
        topik: request.topik,
        likes: [],
        channelGroupId: channelGroupId));
    return ResponseDto(message: postId.toString(), success: true);
  }

  @override
  Future<ResponseDto> deleteChanel(ServiceCall call, ChannelDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.invalidArgument('Remove user');
    }
    FullChannelGroupView? channel =
        await db.channelGroups.queryFullView(request.id);
    if (channel!.authorId != user.id) {
      throw GrpcError.invalidArgument('Access denied');
    }

    for (PostView p in channel.posts) {
      for (String l in p.content) {
        await storage.removeFile(bucket: env.chatsBucket, name: l);
      }
      for (CommentView comment in p.comment) {
        for (String linck in comment.content) {
          await storage.removeFile(bucket: env.chatsBucket, name: linck);
        }
      }
    }
    if (channel.channelImage.isNotEmpty) {
      await storage.removeFile(
          bucket: env.chatsBucket, name: channel.channelImage);
    }

    await db.channelGroups.deleteOne(channel.id);
    return ResponseDto(success: true);
  }

  @override
  Future<ResponseDto> deleteComment(
      ServiceCall call, CommentDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.invalidArgument('Remove user');
    }
    CommentView? comment = await db.comments.queryComment(request.id);
    if (comment!.authorId != user.id) {
      throw GrpcError.invalidArgument('Access denied');
    }

    await db.comments.deleteOne(comment.id);

    return ResponseDto(success: true);
  }

  @override
  Future<ResponseDto> deletePost(ServiceCall call, PostDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.invalidArgument('Remove user');
    }
    PostView? post = await db.posts.queryPost(request.id);
    if (post!.authorId != user.id) {
      throw GrpcError.invalidArgument('Access denied');
    }

    for (String l in post.content) {
      await storage.removeFile(bucket: env.chatsBucket, name: l);
    }
    for (CommentView comment in post.comment) {
      for (String linck in comment.content) {
        await storage.removeFile(bucket: env.chatsBucket, name: linck);
      }
    }
    await db.posts.deleteOne(post.id);
    return ResponseDto(success: true);
  }

  @override
  Future<ResponseDto> editChanel(ServiceCall call, ChannelDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.invalidArgument('Remove user');
    }
    ShortChannelGroupView? channel =
        await db.channelGroups.queryShortView(request.id);
    if (channel!.authorId != user.id) {
      throw GrpcError.invalidArgument('Access denied');
    }
    String image = channel.channelImage;
    if (request.image.isNotEmpty) {
      image = uuid.v8();
      await storage.putFile(
          bucket: env.chatsBucket,
          name: image,
          data: request.image as Uint8List);
    }
    List<String> newTopik = [];

    for (String oldTopik in channel.topik) {
      if (request.topik.contains(oldTopik)) {
        newTopik.add(oldTopik);
      }
      if (!request.topik.contains(oldTopik)) {
        await db.execute("""UPDATE posts SET topik = 'general'
WHERE channel_group_id = '${request.id}' AND topik = '$oldTopik';""");
      }
    }
    if (!newTopik.contains('general')) {
      newTopik.add('general');
    }
    newTopik.addAll(request.topik);
    Set<String> u = newTopik.toSet();
    newTopik.clear();
    newTopik = u.toList();

    await db.channelGroups.updateOne(ChannelGroupUpdateRequest(
        id: channel.id,
        name: request.name,
        tag: request.tags,
        channelImage: image,
        topik: newTopik));
    return ResponseDto(success: true);
  }

  @override
  Future<ListChannelsDto> fetchAllChannels(
      ServiceCall call, RequestDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.invalidArgument('Remove user');
    }

    List<ShortChannelGroupView> channels = await db.channelGroups
        .queryShortViews(QueryParams(
            orderBy: "members", limit: 500, where: "user_blog=false"));
    List<ChannelDto> channelsList = [];
    List<MemberDto> membersList = [];

    for (ShortChannelGroupView value in channels) {
      membersList.clear();
      for (String valueMember in value.members) {
        membersList
            .add(MemberDto(memberUsername: valueMember, memberImage: ''));
      }
      String channelImage =
          await Utils.getLincToFile(value.channelImage, false);
      channelsList.add(ChannelDto(
          id: value.id,
          name: value.name,
          authorId: value.authorId,
          posts: [],
          channelImage: channelImage,
          members: membersList,
          image: [],
          tags: value.tag,
          topik: value.topik));
    }
    return ListChannelsDto(channels: channelsList);
  }

  @override
  Future<ListChannelsDto> fetchUserChannels(
      ServiceCall call, RequestDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.invalidArgument('Remove user');
    }
    final Result listChannels = await db.execute(
        "SELECT json_build_object('id', channel_groups.id, 'name', channel_groups.name, 'author_id', channel_groups.author_id, 'channel_image', channel_groups.channel_image, 'members', channel_groups.members, 'tags', channel_groups.tag, 'topiks', channel_groups.topik, 'user_blog', channel_groups.user_blog, 'id_post', posts.id, 'body', posts.body, 'author_post_id', posts.author_id, 'content', posts.content, 'sticker_content', posts.sticker_content, 'post_tag', posts.tag, 'author_post_name', posts.author_name, 'date_message', posts.date_message, 'topik', posts.topik, 'likes', posts.likes, 'post_channel_id', posts.channel_group_id) AS json_data FROM channel_groups LEFT JOIN (SELECT DISTINCT ON (channel_group_id) * FROM posts ORDER BY channel_group_id, id DESC) AS posts ON channel_groups.id = posts.channel_group_id WHERE '${user.username}' = ANY(channel_groups.members)");

    List<ChannelDto> channelsList = [];

    if (listChannels.isEmpty) {
      return ListChannelsDto(channels: channelsList);
    }

    for (var element in listChannels) {
      String m = jsonEncode(element.first);
      Map<String, dynamic> elementJson = jsonDecode(m);

      if (elementJson['id_post'].runtimeType == Null) {
        elementJson['id_post'] = -1;
        elementJson['content'] = [];
        elementJson['post_channel_id'] = elementJson['id'];
        elementJson['date_message'] = '2024-01-30 02:59:25.704108';
        elementJson['topik'] = 'general';
        elementJson['author_post_id'] = 0;
        elementJson['author_post_name'] = '';
        elementJson['likes'] = '';
        elementJson['sticker_content'] = 0;
        elementJson['body'] = '';
      }

      List<MemberDto> members = [];
      for (String member in elementJson['members']) {
        members.add(MemberDto(memberUsername: member));
      }

      List<String> contentLink = [];
      for (var content in elementJson['content']) {
        contentLink.add(await Utils.getLincToFile(content, false));
      }
      elementJson['content'] = contentLink;
      if (elementJson['channel_image'] != '') {
        elementJson['channel_image'] =
            await Utils.getLincToFile(elementJson['channel_image'], false);
      }

      List<String> topiks = [];
      List<String> tags = [];

      for (String t in elementJson['topiks']) {
        topiks.add(t);
      }
      for (String t in elementJson['tags']) {
        tags.add(t);
      }

      List<PostDto> posts = [];


      if (elementJson['id_post'] != -1) {
        posts.add(PostDto(
          id: elementJson['id_post'],
          body: elementJson['body'],
          authorId: elementJson['author_post_id'],
          channelId: elementJson['id'],
          content: contentLink,
          stickerContent: elementJson['sticker_content'],
          tags: [],
          topik: elementJson['topik'],
          likes: [], 
          comments: [],
          authorName: elementJson['author_post_name'],
          datePost: elementJson['date_message']
        ));
      }
            posts.sort((a, b)=> b.id.compareTo(a.id));
for(PostDto p in posts)
{
    int indexOfGeneral = topiks.indexWhere((element) => element == p.topik);
  if (indexOfGeneral != -1 && indexOfGeneral > 0) { // проверяем наличие элемента и его положение
    topiks.removeAt(indexOfGeneral);          // удаляем элемент с его старой позиции
    topiks.insert(0, p.topik);             // вставляем элемент на первое место
}
}

      channelsList.add(ChannelDto(
          id: elementJson['id'],
          name: elementJson['name'],
          authorId: elementJson['author_id'],
          channelImage: elementJson['channel_image'],
          members: members,
          tags: tags,
          topik: topiks,
          posts: []));
    }
    return ListChannelsDto(channels: channelsList);
  }

  @override
  Future<ResponseDto> likeComment(ServiceCall call, CommentDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.invalidArgument('Remove user');
    }
    await db.execute("""UPDATE comments SET likes = CASE
    WHEN '${user.username}' = ANY(likes) THEN array_remove(likes, '${user.username}')
    ELSE array_append(likes, '${user.username}')
END
WHERE id = '${request.id}';""");

    return ResponseDto(success: true, message: '');
  }

  @override
  Future<ResponseDto> likePost(ServiceCall call, PostDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.invalidArgument('Remove user');
    }
    await db.execute("""UPDATE posts SET likes = CASE
    WHEN '${user.username}' = ANY(likes) THEN array_remove(likes, '${user.username}')
    ELSE array_append(likes, '${user.username}')
END
WHERE id = '${request.id}';""");
    return ResponseDto(success: true, message: '');
  }

  @override
  Future<ListChannelsDto> searchChannel(
      ServiceCall call, SearchRequestDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.invalidArgument('Remove user');
    }

    final List<FullChannelGroupView> listChannels = await db.channelGroups
        .queryFullViews(QueryParams(
            orderBy: 'name', where: "name LIKE '%${request.searchRequest}%'"));

    List<ChannelDto> channelsList = [];

    for (FullChannelGroupView c in listChannels) {
      List<MemberDto> members = [];
      String channelImage = '';
      if (c.channelImage.isNotEmpty) {
        channelImage = await Utils.getLincToFile(c.channelImage, false);
      }
      for (String m in c.members) {
        members.add(MemberDto(memberImage: m, memberUsername: ''));
      }
      channelsList.add(ChannelDto(
          id: c.id,
          name: c.name,
          authorId: c.authorId,
          posts: [],
          members: members,
          channelImage: channelImage,
          tags: c.tag,
          topik: c.topik));
    }
    return ListChannelsDto(channels: channelsList);
  }

  @override
  Future<ListPostsDto> fetchChannelPosts(
      ServiceCall call, RequestPostsDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.invalidArgument('Remove user');
    }
    List<PostView> posts = await db.posts.queryPosts(QueryParams(
        where:
            "channel_group_id='${request.channel.id}' AND '${request.channel.topik.first}' = topik",
        limit: 100,
        offset: request.offset,
        orderBy: "id DESC"));
    List<PostDto> postsRes = [];
    for (PostView p in posts) {
      List<String> contentLink = [];
      for (String lin in p.content) {
        String l = await Utils.getLincToFile(lin, false);
        contentLink.add(l);
      }
      List<CommentDto> comments = [];
      for (CommentView c in p.comment) {
        List<String> commentContent = [];
        for (String link in c.content) {
          String l = await Utils.getLincToFile(link, false);
          commentContent.add(l);
        }
        comments.add(CommentDto(
            id: c.id,
            body: c.body,
            authorId: c.authorId,
            authorName: c.authorName,
            stickerContent: c.stickerContent,
            likes: c.likes,
            dateComment: c.dateComment.toString(),
            content: commentContent));
      }
      postsRes.add(PostDto(
          id: p.id,
          body: p.body,
          authorId: p.authorId,
          channelId: request.channel.id,
          authorName: p.authorName,
          likes: p.likes,
          data: [],
          content: contentLink,
          stickerContent: p.stickerContent,
          datePost: p.dateMessage.toString(),
          comments: comments,
          tags: p.tag,
          topik: p.topik));
    }
    return ListPostsDto(posts: postsRes);
  }

  @override
  Future<ListPostsDto> fetchUserPosts(
      ServiceCall call, RequestPostsDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.invalidArgument('Remove user');
    }
    List<ShortChannelGroupView> channels = await db.channelGroups
        .queryShortViews(QueryParams(
            where:
                "author_id='${request.channel.authorId}' AND user_blog=true"));
    if (channels.isEmpty) {
      return ListPostsDto(posts: []);
    }

    List<PostView> posts = await db.posts.queryPosts(QueryParams(
        where: "channel_group_id='${channels.first.id}'",
        limit: 100,
        offset: request.offset,
        orderBy: "id DESC"));
    List<PostDto> postsRes = [];
    for (PostView p in posts) {
      List<String> contentLink = [];
      for (String lin in p.content) {
        String l = await Utils.getLincToFile(lin, false);
        contentLink.add(l);
      }
      List<CommentDto> comments = [];
      for (CommentView c in p.comment) {
        List<String> commentContent = [];
        for (String link in c.content) {
          String l = await Utils.getLincToFile(link, false);
          commentContent.add(l);
        }
        comments.add(CommentDto(id: c.id, body: c.body, authorId: c.authorId, postId: p.id, authorName: c.authorName, content: commentContent, stickerContent: c.stickerContent, likes: c.likes, dateComment: c.dateComment.toString()));
      }

      postsRes.add(PostDto(
          id: p.id,
          body: p.body,
          authorId: p.authorId,
          channelId: channels.first.id,
          authorName: p.authorName,
          likes: p.likes,
          data: [],
          content: contentLink,
          stickerContent: p.stickerContent,
          datePost: p.dateMessage.toString(),
          comments: comments,
          tags: p.tag,
          topik: p.topik));
    }

    return ListPostsDto(posts: postsRes);
  }

  @override
  Future<ResponseDto> addUserChannel(
      ServiceCall call, ChannelDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.invalidArgument('Remove user');
    }
    await db.execute("""UPDATE channel_groups SET members = CASE
    WHEN '${user.username}' = ANY(members) THEN array_remove(members, '${user.username}')
    ELSE array_append(members, '${user.username}')
END
WHERE id = '${request.id}';""");
    return ResponseDto(success: true, message: '');
  }

  @override
  Future<PostDto> fetchOnePost(ServiceCall call, PostDto request) async {
    final id = Utils.getIdFromMetadata(call);
    final user = await db.users.queryUser(id);
    if (user == null) {
      throw GrpcError.invalidArgument('Remove user');
    }
    List<String> content = [];

    PostView? post = await db.posts.queryPost(request.id);
    for (String c in post!.content) {
      String l = await Utils.getLincToFile(c, false);
      content.add(l);
    }
    List<CommentDto> comments = [];
    for (CommentView c in post.comment) {
      List<String> links = [];
      for (String link in c.content) {
        String l = await Utils.getLincToFile(link, false);
        links.add(l);
      }

      comments.add(CommentDto(
          id: c.id,
          body: c.body,
          authorId: c.authorId,
          postId: post.id,
          authorName: c.authorName,
          content: links,
          stickerContent: c.stickerContent,
          likes: c.likes,
          dateComment: c.dateComment.toString()));
    }

    return PostDto(
        id: post.id,
        body: post.body,
        authorId: post.authorId,
        channelId: post.authorId,
        authorName: post.authorName,
        likes: post.likes,
        stickerContent: post.stickerContent,
        datePost: post.dateMessage.toString(),
        tags: post.tag,
        topik: post.topik,
        content: content,
        comments: comments);
  }
}
