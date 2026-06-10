-module(example@migrations).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/example/migrations.gleam").
-export([all/0]).

-file("src/example/migrations.gleam", 41).
-spec create_follows() -> gloo@migration:migration().
create_follows() ->
    gloo@migration:create_table(
        20260430000003,
        <<"create_follows"/utf8>>,
        <<"follows"/utf8>>,
        [begin
                _pipe = gloo@pg:column(<<"follower_id"/utf8>>, big_int),
                gloo@pg:not_null(_pipe)
            end,
            begin
                _pipe@1 = gloo@pg:column(<<"followee_id"/utf8>>, big_int),
                gloo@pg:not_null(_pipe@1)
            end,
            begin
                _pipe@2 = gloo@pg:column(<<"inserted_at"/utf8>>, timestamp_tz),
                _pipe@3 = gloo@pg:not_null(_pipe@2),
                gloo@pg:default(_pipe@3, <<"NOW()"/utf8>>)
            end]
    ).

-file("src/example/migrations.gleam", 24).
-spec create_posts() -> gloo@migration:migration().
create_posts() ->
    _pipe@5 = gloo@migration:create_table(
        20260430000002,
        <<"create_posts"/utf8>>,
        <<"posts"/utf8>>,
        [begin
                _pipe = gloo@pg:column(<<"id"/utf8>>, big_serial),
                gloo@pg:primary_key(_pipe)
            end,
            begin
                _pipe@1 = gloo@pg:column(<<"user_id"/utf8>>, big_int),
                gloo@pg:not_null(_pipe@1)
            end,
            begin
                _pipe@2 = gloo@pg:column(<<"body"/utf8>>, text),
                gloo@pg:not_null(_pipe@2)
            end,
            begin
                _pipe@3 = gloo@pg:column(<<"inserted_at"/utf8>>, timestamp_tz),
                _pipe@4 = gloo@pg:not_null(_pipe@3),
                gloo@pg:default(_pipe@4, <<"NOW()"/utf8>>)
            end]
    ),
    gloo@migration:with_down(_pipe@5, <<"DROP TABLE IF EXISTS posts"/utf8>>).

-file("src/example/migrations.gleam", 8).
-spec create_users() -> gloo@migration:migration().
create_users() ->
    gloo@migration:create_table(
        20260430000001,
        <<"create_users"/utf8>>,
        <<"users"/utf8>>,
        [begin
                _pipe = gloo@pg:column(<<"id"/utf8>>, big_serial),
                gloo@pg:primary_key(_pipe)
            end,
            begin
                _pipe@1 = gloo@pg:column(<<"email"/utf8>>, text),
                _pipe@2 = gloo@pg:not_null(_pipe@1),
                gloo@pg:unique(_pipe@2)
            end,
            begin
                _pipe@3 = gloo@pg:column(<<"name"/utf8>>, text),
                gloo@pg:not_null(_pipe@3)
            end,
            begin
                _pipe@4 = gloo@pg:column(<<"inserted_at"/utf8>>, timestamp_tz),
                _pipe@5 = gloo@pg:not_null(_pipe@4),
                gloo@pg:default(_pipe@5, <<"NOW()"/utf8>>)
            end]
    ).

-file("src/example/migrations.gleam", 4).
-spec all() -> list(gloo@migration:migration()).
all() ->
    [create_users(), create_posts(), create_follows()].
