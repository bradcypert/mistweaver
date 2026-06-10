-module(mistweaver).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/mistweaver.gleam").
-export([new_config/0, port/2, bind/2, with_ipv6/1, start/2, start_with_handler/2, wait_forever/0]).
-export_type([mist_weaver_error/0, config/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-type mist_weaver_error() :: {start_error, gleam@otp@actor:start_error()}.

-opaque config() :: {config, integer(), binary(), boolean()}.

-file("src/mistweaver.gleam", 22).
?DOC(" Create a default server configuration on port 4000.\n").
-spec new_config() -> config().
new_config() ->
    {config, 4000, <<"localhost"/utf8>>, false}.

-file("src/mistweaver.gleam", 27).
?DOC(" Set the port the server listens on.\n").
-spec port(config(), integer()) -> config().
port(Config, Port) ->
    {config, Port, erlang:element(3, Config), erlang:element(4, Config)}.

-file("src/mistweaver.gleam", 32).
?DOC(" Set the interface to bind to (e.g. \"0.0.0.0\" for all interfaces).\n").
-spec bind(config(), binary()) -> config().
bind(Config, Interface) ->
    {config, erlang:element(2, Config), Interface, erlang:element(4, Config)}.

-file("src/mistweaver.gleam", 37).
?DOC(" Enable IPv6 support.\n").
-spec with_ipv6(config()) -> config().
with_ipv6(Config) ->
    {config, erlang:element(2, Config), erlang:element(3, Config), true}.

-file("src/mistweaver.gleam", 65).
-spec start_mist(
    config(),
    fun((gleam@http@request:request(mist@internal@http:connection())) -> gleam@http@response:response(mist:response_data()))
) -> {ok, gleam@otp@actor:started(gleam@otp@static_supervisor:supervisor())} |
    {error, mist_weaver_error()}.
start_mist(Config, Handler) ->
    _pipe = mist:new(Handler),
    _pipe@1 = mist:port(_pipe, erlang:element(2, Config)),
    _pipe@2 = mist:bind(_pipe@1, erlang:element(3, Config)),
    _pipe@3 = (fun(Builder) -> case erlang:element(4, Config) of
            true ->
                mist:with_ipv6(Builder);

            false ->
                Builder
        end end)(_pipe@2),
    _pipe@4 = mist:start(_pipe@3),
    (fun(Result) -> case Result of
            {ok, Started} ->
                {ok, Started};

            {error, Err} ->
                {error, {start_error, Err}}
        end end)(_pipe@4).

-file("src/mistweaver.gleam", 43).
?DOC(
    " Start the server with a compiled Router. The router's `dispatch` function\n"
    " becomes the Mist handler. Blocks until the process receives a shutdown signal.\n"
).
-spec start(config(), mistweaver@router:router(mist@internal@http:connection())) -> {ok,
        gleam@otp@actor:started(gleam@otp@static_supervisor:supervisor())} |
    {error, mist_weaver_error()}.
start(Config, R) ->
    start_mist(
        Config,
        fun(_capture) -> mistweaver@router:dispatch(R, _capture) end
    ).

-file("src/mistweaver.gleam", 52).
?DOC(
    " Start the server with a raw handler function instead of a Router. Useful\n"
    " for apps that compose middleware manually before handing off to a router.\n"
).
-spec start_with_handler(
    config(),
    fun((gleam@http@request:request(mist@internal@http:connection())) -> gleam@http@response:response(mist:response_data()))
) -> {ok, gleam@otp@actor:started(gleam@otp@static_supervisor:supervisor())} |
    {error, mist_weaver_error()}.
start_with_handler(Config, Handler) ->
    start_mist(Config, Handler).

-file("src/mistweaver.gleam", 61).
?DOC(
    " Block the calling process indefinitely, keeping the server alive.\n"
    " Call after `start/2` to keep a standalone Erlang node running.\n"
).
-spec wait_forever() -> nil.
wait_forever() ->
    gleam_erlang_ffi:sleep_forever().
