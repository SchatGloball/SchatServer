ALTER TABLE "comments"
  ADD PRIMARY KEY ( "id" );

ALTER TABLE "messages"
  ADD PRIMARY KEY ( "id" );

ALTER TABLE "reaction_messages"
  ADD PRIMARY KEY ( "id" );

ALTER TABLE "channel_groups"
  ADD PRIMARY KEY ( "id" );

ALTER TABLE "chats"
  ADD PRIMARY KEY ( "id" );

ALTER TABLE "posts"
  ADD PRIMARY KEY ( "id" );

ALTER TABLE "users"
  ADD PRIMARY KEY ( "id" );

ALTER TABLE "comments"
  ADD FOREIGN KEY ( "post_id" ) REFERENCES "posts" ( "id" ) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "messages"
  ADD FOREIGN KEY ( "chat_id" ) REFERENCES "chats" ( "id" ) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "reaction_messages"
  ADD FOREIGN KEY ( "message_id" ) REFERENCES "messages" ( "id" ) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "posts"
  ADD FOREIGN KEY ( "channel_group_id" ) REFERENCES "channel_groups" ( "id" ) ON DELETE SET NULL ON UPDATE CASCADE;

CREATE UNIQUE INDEX "__email" ON "users" USING BTREE ( "email" ) ;

CREATE UNIQUE INDEX "__username" ON "users" USING BTREE ( "username" ) ;