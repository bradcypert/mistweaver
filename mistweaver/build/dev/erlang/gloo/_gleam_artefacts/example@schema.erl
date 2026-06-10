-module(example@schema).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/example/schema.gleam").
-export([users/0, posts/0, follows/0]).
-export_type([user/0, post/0, follow/0]).

-type user() :: {user, integer(), binary(), binary()}.

-type post() :: {post, integer(), integer(), binary()}.

-type follow() :: {follow, integer(), integer()}.

-file("src/example/schema.gleam", 10).
-spec users() -> gloo@schema:table(user()).
users() ->
    Decoder = begin
        gleam@dynamic@decode:field(
            0,
            {decoder, fun gleam@dynamic@decode:decode_int/1},
            fun(Id) ->
                gleam@dynamic@decode:field(
                    1,
                    {decoder, fun gleam@dynamic@decode:decode_string/1},
                    fun(Email) ->
                        gleam@dynamic@decode:field(
                            2,
                            {decoder, fun gleam@dynamic@decode:decode_string/1},
                            fun(Name) ->
                                gleam@dynamic@decode:success(
                                    {user, Id, Email, Name}
                                )
                            end
                        )
                    end
                )
            end
        )
    end,
    {table, <<"users"/utf8>>, <<"id"/utf8>>, Decoder}.

-file("src/example/schema.gleam", 26).
-spec posts() -> gloo@schema:table(post()).
posts() ->
    Decoder = begin
        gleam@dynamic@decode:field(
            0,
            {decoder, fun gleam@dynamic@decode:decode_int/1},
            fun(Id) ->
                gleam@dynamic@decode:field(
                    1,
                    {decoder, fun gleam@dynamic@decode:decode_int/1},
                    fun(User_id) ->
                        gleam@dynamic@decode:field(
                            2,
                            {decoder, fun gleam@dynamic@decode:decode_string/1},
                            fun(Body) ->
                                gleam@dynamic@decode:success(
                                    {post, Id, User_id, Body}
                                )
                            end
                        )
                    end
                )
            end
        )
    end,
    {table, <<"posts"/utf8>>, <<"id"/utf8>>, Decoder}.

-file("src/example/schema.gleam", 42).
-spec follows() -> gloo@schema:table(follow()).
follows() ->
    Decoder = begin
        gleam@dynamic@decode:field(
            0,
            {decoder, fun gleam@dynamic@decode:decode_int/1},
            fun(Follower_id) ->
                gleam@dynamic@decode:field(
                    1,
                    {decoder, fun gleam@dynamic@decode:decode_int/1},
                    fun(Followee_id) ->
                        gleam@dynamic@decode:success(
                            {follow, Follower_id, Followee_id}
                        )
                    end
                )
            end
        )
    end,
    {table, <<"follows"/utf8>>, <<"follower_id"/utf8>>, Decoder}.
