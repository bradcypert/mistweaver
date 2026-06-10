-module(gloo@migrations@create_users).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/gloo/migrations/create_users.gleam").
-export([migration/0]).

-file("src/gloo/migrations/create_users.gleam", 4).
-spec migration() -> gloo@migration:migration().
migration() ->
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
