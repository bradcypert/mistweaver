-module(gloo@adapter@sqlite).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/gloo/adapter/sqlite.gleam").
-export([memory/0, file/1, start/1]).
-export_type([config/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    "  SQLite adapter.  Wraps `sqlight`.\n"
    "\n"
    "  ```gleam\n"
    "  use r <- result.try(sqlite.start(sqlite.memory()))\n"
    "  use r <- result.try(sqlite.start(sqlite.file(\"mydb.sqlite3\")))\n"
    "  // ... use r ...\n"
    "  repo.close(r)\n"
    "  ```\n"
).

-type config() :: {config, binary()}.

-file("src/gloo/adapter/sqlite.gleam", 19).
-spec memory() -> config().
memory() ->
    {config, <<":memory:"/utf8>>}.

-file("src/gloo/adapter/sqlite.gleam", 23).
-spec file(binary()) -> config().
file(Path) ->
    {config, Path}.

-file("src/gloo/adapter/sqlite.gleam", 29).
?DOC(
    " Open a SQLite connection and return a Repo.\n"
    " Call `repo.close(r)` when done.\n"
).
-spec start(config()) -> {ok, gloo@repo:repo()} | {error, binary()}.
start(Config) ->
    case sqlight:open(erlang:element(2, Config)) of
        {ok, Conn} ->
            Sq_adapter = {adapter,
                <<"sqlite"/utf8>>,
                {sq_connection, Conn},
                fun gloo@adapter:sqlite_quote/1,
                fun gloo@adapter:sqlite_placeholder/1,
                0,
                gloo@telemetry:disabled()},
            {ok, gloo@repo:from_adapter(Sq_adapter)};

        {error, E} ->
            {error, erlang:element(3, E)}
    end.
