-module(gloo@runner).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/gloo/runner.gleam").
-export([run/4, applied_versions/1]).
-export_type([direction/0, runner_error/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    "  Low-level migration runner.  `runner.run` applies or rolls back a list of\n"
    "  migrations, skipping versions already recorded in `schema_migrations`.\n"
    "  Each migration runs in its own transaction.  Normally you call\n"
    "  `migrate.main_with_migrations` instead of using this directly.\n"
).

-type direction() :: up | down.

-type runner_error() :: {db_error, binary()} |
    {migration_failed, integer(), binary(), binary()}.

-file("src/gloo/runner.gleam", 115).
-spec run_one(gloo@repo:repo(), gloo@migration:migration(), direction()) -> {ok,
        nil} |
    {error, runner_error()}.
run_one(R, M, Direction) ->
    Sql = case Direction of
        up ->
            {some, erlang:element(4, M)};

        down ->
            erlang:element(5, M)
    end,
    case Sql of
        none ->
            {ok, nil};

        {some, Statement} ->
            _pipe@4 = gloo@repo:transaction(
                R,
                fun(Tx) ->
                    Stmts = begin
                        _pipe = gleam@string:split(Statement, <<";"/utf8>>),
                        _pipe@1 = gleam@list:map(_pipe, fun gleam@string:trim/1),
                        gleam@list:filter(
                            _pipe@1,
                            fun(S) -> S /= <<""/utf8>> end
                        )
                    end,
                    gleam@result:'try'(
                        gleam@list:try_fold(
                            Stmts,
                            nil,
                            fun(_, Stmt) ->
                                _pipe@2 = gloo@repo:execute(Tx, Stmt, []),
                                gleam@result:map(_pipe@2, fun(_) -> nil end)
                            end
                        ),
                        fun(_) -> _pipe@3 = case Direction of
                                up ->
                                    gloo@repo:execute(
                                        Tx,
                                        <<"INSERT INTO schema_migrations (version, name) VALUES ($1, $2) ON CONFLICT (version) DO NOTHING"/utf8>>,
                                        [{g_int, erlang:element(2, M)},
                                            {g_string, erlang:element(3, M)}]
                                    );

                                down ->
                                    gloo@repo:execute(
                                        Tx,
                                        <<"DELETE FROM schema_migrations WHERE version = $1"/utf8>>,
                                        [{g_int, erlang:element(2, M)}]
                                    )
                            end,
                            gleam@result:map(_pipe@3, fun(_) -> nil end) end
                    )
                end
            ),
            gleam@result:map_error(
                _pipe@4,
                fun(E) ->
                    {migration_failed,
                        erlang:element(2, M),
                        erlang:element(3, M),
                        gloo@error:to_string(E)}
                end
            )
    end.

-file("src/gloo/runner.gleam", 100).
-spec fetch_applied_versions(gloo@repo:repo()) -> {ok, list(integer())} |
    {error, runner_error()}.
fetch_applied_versions(R) ->
    Decoder = begin
        gleam@dynamic@decode:field(
            0,
            {decoder, fun gleam@dynamic@decode:decode_int/1},
            fun(V) -> gleam@dynamic@decode:success(V) end
        )
    end,
    _pipe = gloo@repo:all(
        R,
        <<"SELECT version FROM schema_migrations ORDER BY version ASC"/utf8>>,
        [],
        Decoder
    ),
    gleam@result:map_error(
        _pipe,
        fun(E) -> {db_error, gloo@error:to_string(E)} end
    ).

-file("src/gloo/runner.gleam", 90).
-spec ensure_schema_migrations(gloo@repo:repo()) -> {ok, nil} |
    {error, runner_error()}.
ensure_schema_migrations(R) ->
    Ddl = case gloo@repo:adapter_name(R) of
        <<"postgres"/utf8>> ->
            <<"
CREATE TABLE IF NOT EXISTS schema_migrations (
  version    INTEGER PRIMARY KEY,
  name       TEXT NOT NULL,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
)
"/utf8>>;

        _ ->
            <<"
CREATE TABLE IF NOT EXISTS schema_migrations (
  version    INTEGER PRIMARY KEY,
  name       TEXT NOT NULL,
  applied_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
)
"/utf8>>
    end,
    _pipe = gloo@repo:execute(R, Ddl, []),
    _pipe@1 = gleam@result:map(_pipe, fun(_) -> nil end),
    gleam@result:map_error(
        _pipe@1,
        fun(E) -> {db_error, gloo@error:to_string(E)} end
    ).

-file("src/gloo/runner.gleam", 53).
?DOC(
    " Run pending migrations in the given direction.\n"
    " V8: each migration runs in its own transaction.\n"
    " V9: schema_migrations tracks applied versions; already-applied are skipped.\n"
).
-spec run(
    gloo@repo:repo(),
    list(gloo@migration:migration()),
    direction(),
    gleam@option:option(integer())
) -> {ok, integer()} | {error, runner_error()}.
run(R, Migrations, Direction, Step) ->
    gleam@result:'try'(
        ensure_schema_migrations(R),
        fun(_) ->
            gleam@result:'try'(
                fetch_applied_versions(R),
                fun(Applied) ->
                    To_run = case Direction of
                        up ->
                            _pipe = gleam@list:filter(
                                Migrations,
                                fun(M) ->
                                    not gleam@list:contains(
                                        Applied,
                                        erlang:element(2, M)
                                    )
                                end
                            ),
                            gleam@list:sort(
                                _pipe,
                                fun(A, B) ->
                                    gleam@int:compare(
                                        erlang:element(2, A),
                                        erlang:element(2, B)
                                    )
                                end
                            );

                        down ->
                            _pipe@1 = gleam@list:filter(
                                Migrations,
                                fun(M@1) ->
                                    gleam@list:contains(
                                        Applied,
                                        erlang:element(2, M@1)
                                    )
                                end
                            ),
                            gleam@list:sort(
                                _pipe@1,
                                fun(A@1, B@1) ->
                                    gleam@int:compare(
                                        erlang:element(2, B@1),
                                        erlang:element(2, A@1)
                                    )
                                end
                            )
                    end,
                    Capped = case Step of
                        none ->
                            To_run;

                        {some, N} ->
                            gleam@list:take(To_run, N)
                    end,
                    gleam@list:try_fold(
                        Capped,
                        0,
                        fun(Count, M@2) ->
                            gleam@result:'try'(
                                run_one(R, M@2, Direction),
                                fun(_) -> {ok, Count + 1} end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/gloo/runner.gleam", 83).
?DOC(" V9: return list of applied migration versions in ascending order.\n").
-spec applied_versions(gloo@repo:repo()) -> {ok, list(integer())} |
    {error, runner_error()}.
applied_versions(R) ->
    gleam@result:'try'(
        ensure_schema_migrations(R),
        fun(_) -> fetch_applied_versions(R) end
    ).
