CREATE TABLE IF NOT EXISTS "comments" (
  "id" serial NOT NULL,
  "body" text NOT NULL,
  "author_id" int8 NOT NULL,
  "content" _text NOT NULL,
  "author_name" text NOT NULL,
  "sticker_content" int8 NOT NULL,
  "date_comment" timestamp NOT NULL,
  "likes" _text NOT NULL,
  "post_id" int8 NULL
);

CREATE TABLE IF NOT EXISTS "messages" (
  "id" serial NOT NULL,
  "body" text NOT NULL,
  "forwarded" boolean NOT NULL,
  "author_id" int8 NOT NULL,
  "content" _text NOT NULL,
  "author_name" text NOT NULL,
  "sticker_content" int8 NOT NULL,
  "date_message" timestamp NOT NULL,
  "delivered" boolean NOT NULL,
  "original_author" text NOT NULL,
  "original_date" timestamp NOT NULL,
  "chat_id" int8 NULL
);

CREATE TABLE IF NOT EXISTS "reaction_messages" (
  "id" serial NOT NULL,
  "body" text NOT NULL,
  "author_id" int8 NOT NULL,
  "author_name" text NOT NULL,
  "sticker_content" int8 NOT NULL,
  "date_reaction" timestamp NOT NULL,
  "message_id" int8 NULL
);

CREATE TABLE IF NOT EXISTS "channel_groups" (
  "id" serial NOT NULL,
  "name" text NOT NULL,
  "author_id" int8 NOT NULL,
  "user_blog" boolean NOT NULL,
  "channel_image" text NOT NULL,
  "tag" _text NOT NULL,
  "members" _text NOT NULL,
  "topik" _text NOT NULL
);

CREATE TABLE IF NOT EXISTS "chats" (
  "id" serial NOT NULL,
  "name" text NOT NULL,
  "author_id" text NOT NULL,
  "chat_image" text NOT NULL,
  "members" _text NOT NULL
);

CREATE TABLE IF NOT EXISTS "posts" (
  "id" serial NOT NULL,
  "body" text NOT NULL,
  "author_id" int8 NOT NULL,
  "tag" _text NOT NULL,
  "content" _text NOT NULL,
  "author_name" text NOT NULL,
  "sticker_content" int8 NOT NULL,
  "date_message" timestamp NOT NULL,
  "topik" text NOT NULL,
  "likes" _text NOT NULL,
  "channel_group_id" int8 NULL
);

CREATE TABLE IF NOT EXISTS "users" (
  "id" serial NOT NULL,
  "username" text NOT NULL,
  "email" text NOT NULL,
  "password" text NOT NULL,
  "image_avatar" text NOT NULL,
  "is_bot" boolean NOT NULL,
  "name_creator" text NOT NULL
);