-module(example@queries).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/example/queries.gleam").
-export([find_user_by_email/2, find_posts_for_user/2, create_user/3, create_post/3, follow_user/3, feed_for_user/3, delete_user_posts/2, delete_user_and_posts/2]).
-export_type([feed_post/0]).

-type feed_post() :: {feed_post, integer(), binary(), binary()}.

-file("src/example/queries.gleam", 11).
-spec find_user_by_email(gloo@repo:repo(), binary()) -> {ok,
        example@schema:user()} |
    {error, gloo@error:gloo_error()}.
find_user_by_email(R, Email) ->
    _pipe = gloo@query:from(example@schema:users()),
    _pipe@1 = gloo@query:where(
        _pipe,
        {eq, <<"email"/utf8>>, gloo@sql:string(Email)}
    ),
    gloo@repo:query_one(R, _pipe@1).

-file("src/example/queries.gleam", 20).
-spec find_posts_for_user(gloo@repo:repo(), integer()) -> {ok,
        list(example@schema:post())} |
    {error, gloo@error:gloo_error()}.
find_posts_for_user(R, User_id) ->
    _pipe = gloo@query:from(example@schema:posts()),
    _pipe@1 = gloo@query:where(
        _pipe,
        {eq, <<"user_id"/utf8>>, gloo@sql:int(User_id)}
    ),
    _pipe@2 = gloo@query:order_by(_pipe@1, <<"inserted_at"/utf8>>, desc),
    gloo@repo:query_all(R, _pipe@2).

-file("src/example/queries.gleam", 30).
-spec create_user(gloo@repo:repo(), binary(), binary()) -> {ok,
        example@schema:user()} |
    {error, gloo@error:gloo_error()}.
create_user(R, Email, Name) ->
    _pipe = gloo@query:insert(
        gloo@query:from(example@schema:users()),
        example@schema:users(),
        [{<<"email"/utf8>>, gloo@sql:string(Email)},
            {<<"name"/utf8>>, gloo@sql:string(Name)}]
    ),
    _pipe@1 = gloo@query:returning_columns(
        _pipe,
        [<<"id"/utf8>>, <<"email"/utf8>>, <<"name"/utf8>>]
    ),
    _pipe@2 = gloo@query:returning(
        _pipe@1,
        erlang:element(4, example@schema:users())
    ),
    gloo@repo:query_one(R, _pipe@2).

-file("src/example/queries.gleam", 44).
-spec create_post(gloo@repo:repo(), integer(), binary()) -> {ok,
        example@schema:post()} |
    {error, gloo@error:gloo_error()}.
create_post(R, User_id, Body) ->
    _pipe = gloo@query:insert(
        gloo@query:from(example@schema:posts()),
        example@schema:posts(),
        [{<<"user_id"/utf8>>, gloo@sql:int(User_id)},
            {<<"body"/utf8>>, gloo@sql:string(Body)}]
    ),
    _pipe@1 = gloo@query:returning_columns(
        _pipe,
        [<<"id"/utf8>>, <<"user_id"/utf8>>, <<"body"/utf8>>]
    ),
    _pipe@2 = gloo@query:returning(
        _pipe@1,
        erlang:element(4, example@schema:posts())
    ),
    gloo@repo:query_one(R, _pipe@2).

-file("src/example/queries.gleam", 58).
-spec follow_user(gloo@repo:repo(), integer(), integer()) -> {ok, integer()} |
    {error, gloo@error:gloo_error()}.
follow_user(R, Follower_id, Followee_id) ->
    _pipe = gloo@query:insert(
        gloo@query:from(example@schema:follows()),
        example@schema:follows(),
        [{<<"follower_id"/utf8>>, gloo@sql:int(Follower_id)},
            {<<"followee_id"/utf8>>, gloo@sql:int(Followee_id)}]
    ),
    gloo@repo:query_execute(R, _pipe).

-file("src/example/queries.gleam", 76).
-spec feed_for_user(gloo@repo:repo(), integer(), integer()) -> {ok,
        list(feed_post())} |
    {error, gloo@error:gloo_error()}.
feed_for_user(R, User_id, Limit) ->
    Decoder = begin
        gleam@dynamic@decode:field(
            0,
            {decoder, fun gleam@dynamic@decode:decode_int/1},
            fun(Post_id) ->
                gleam@dynamic@decode:field(
                    1,
                    {decoder, fun gleam@dynamic@decode:decode_string/1},
                    fun(Author_name) ->
                        gleam@dynamic@decode:field(
                            2,
                            {decoder, fun gleam@dynamic@decode:decode_string/1},
                            fun(Body) ->
                                gleam@dynamic@decode:success(
                                    {feed_post, Post_id, Author_name, Body}
                                )
                            end
                        )
                    end
                )
            end
        )
    end,
    _pipe = gloo@sql:'query'(
        <<"SELECT p.id, u.name, p.body
     FROM posts p
     JOIN users u ON u.id = p.user_id
     WHERE p.user_id IN (
       SELECT followee_id FROM follows WHERE follower_id = $1
     )
     ORDER BY p.inserted_at DESC
     LIMIT $2"/utf8>>
    ),
    _pipe@1 = gloo@sql:param(_pipe, gloo@sql:int(User_id)),
    _pipe@2 = gloo@sql:param(_pipe@1, gloo@sql:int(Limit)),
    _pipe@3 = gloo@sql:returns(_pipe@2, Decoder),
    gloo@repo:sql_all(R, _pipe@3).

-file("src/example/queries.gleam", 103).
-spec delete_user_posts(gloo@repo:repo(), integer()) -> {ok, integer()} |
    {error, gloo@error:gloo_error()}.
delete_user_posts(R, User_id) ->
    _pipe = gloo@sql:'query'(<<"DELETE FROM posts WHERE user_id = $1"/utf8>>),
    _pipe@1 = gloo@sql:param(_pipe, gloo@sql:int(User_id)),
    gloo@repo:sql_execute(R, _pipe@1).

-file("src/example/queries.gleam", 114).
-spec delete_user_and_posts(gloo@repo:repo(), integer()) -> {ok, nil} |
    {error, gloo@error:gloo_error()}.
delete_user_and_posts(R, User_id) ->
    gloo@repo:transaction(
        R,
        fun(Tx) ->
            gleam@result:'try'(
                delete_user_posts(Tx, User_id),
                fun(_) ->
                    gleam@result:'try'(
                        begin
                            _pipe = gloo@query:from(example@schema:follows()),
                            _pipe@1 = gloo@query:delete(_pipe),
                            _pipe@2 = gloo@query:where(
                                _pipe@1,
                                {'or',
                                    [{eq,
                                            <<"follower_id"/utf8>>,
                                            gloo@sql:int(User_id)},
                                        {eq,
                                            <<"followee_id"/utf8>>,
                                            gloo@sql:int(User_id)}]}
                            ),
                            gloo@repo:query_execute(Tx, _pipe@2)
                        end,
                        fun(_) ->
                            gleam@result:'try'(
                                gloo@repo:execute(
                                    Tx,
                                    <<"DELETE FROM users WHERE id = $1"/utf8>>,
                                    [gloo@sql:int(User_id)]
                                ),
                                fun(_) -> {ok, nil} end
                            )
                        end
                    )
                end
            )
        end
    ).
