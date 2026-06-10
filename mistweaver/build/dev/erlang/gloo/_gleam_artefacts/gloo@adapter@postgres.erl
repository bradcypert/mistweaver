-module(gloo@adapter@postgres).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/gloo/adapter/postgres.gleam").
-export([default_config/0, host/2, database/2, user/2, password/2, pool_size/2, start/1]).
-export_type([config/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    "  Postgres adapter.  Wraps the `pog` connection pool.\n"
    "\n"
    "  ```gleam\n"
    "  postgres.default_config()\n"
    "  |> postgres.database(\"myapp_dev\")\n"
    "  |> postgres.user(\"postgres\")\n"
    "  |> postgres.start()\n"
    "  // -> Result(Repo, actor.StartError)\n"
    "  ```\n"
).

-type config() :: {config,
        binary(),
        binary(),
        binary(),
        gleam@option:option(binary()),
        integer()}.

-file("src/gloo/adapter/postgres.gleam", 29).
-spec default_config() -> config().
default_config() ->
    {config,
        <<"127.0.0.1"/utf8>>,
        <<"postgres"/utf8>>,
        <<"postgres"/utf8>>,
        none,
        10}.

-file("src/gloo/adapter/postgres.gleam", 39).
-spec host(config(), binary()) -> config().
host(Config, Host) ->
    {config,
        Host,
        erlang:element(3, Config),
        erlang:element(4, Config),
        erlang:element(5, Config),
        erlang:element(6, Config)}.

-file("src/gloo/adapter/postgres.gleam", 43).
-spec database(config(), binary()) -> config().
database(Config, Database) ->
    {config,
        erlang:element(2, Config),
        Database,
        erlang:element(4, Config),
        erlang:element(5, Config),
        erlang:element(6, Config)}.

-file("src/gloo/adapter/postgres.gleam", 47).
-spec user(config(), binary()) -> config().
user(Config, User) ->
    {config,
        erlang:element(2, Config),
        erlang:element(3, Config),
        User,
        erlang:element(5, Config),
        erlang:element(6, Config)}.

-file("src/gloo/adapter/postgres.gleam", 51).
-spec password(config(), gleam@option:option(binary())) -> config().
password(Config, Password) ->
    {config,
        erlang:element(2, Config),
        erlang:element(3, Config),
        erlang:element(4, Config),
        Password,
        erlang:element(6, Config)}.

-file("src/gloo/adapter/postgres.gleam", 55).
-spec pool_size(config(), integer()) -> config().
pool_size(Config, Pool_size) ->
    {config,
        erlang:element(2, Config),
        erlang:element(3, Config),
        erlang:element(4, Config),
        erlang:element(5, Config),
        Pool_size}.

-file("src/gloo/adapter/postgres.gleam", 59).
-spec start(config()) -> {ok, gloo@repo:repo()} |
    {error, gleam@otp@actor:start_error()}.
start(Config) ->
    Pool_name = gleam_erlang_ffi:new_name(<<"gloo_pg"/utf8>>),
    Pog_config = begin
        _pipe = pog:default_config(Pool_name),
        _pipe@1 = pog:host(_pipe, erlang:element(2, Config)),
        _pipe@2 = pog:database(_pipe@1, erlang:element(3, Config)),
        _pipe@3 = pog:user(_pipe@2, erlang:element(4, Config)),
        _pipe@4 = pog:password(_pipe@3, erlang:element(5, Config)),
        pog:pool_size(_pipe@4, erlang:element(6, Config))
    end,
    case pog:start(Pog_config) of
        {ok, {started, Pid, Conn}} ->
            Pg_adapter = {adapter,
                <<"postgres"/utf8>>,
                {pg_connection, Conn, Pid},
                fun gloo@adapter:postgres_quote/1,
                fun gloo@adapter:postgres_placeholder/1,
                0,
                gloo@telemetry:disabled()},
            {ok, gloo@repo:from_adapter(Pg_adapter)};

        {error, E} ->
            {error, E}
    end.
