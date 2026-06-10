-module(gloo@telemetry).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/gloo/telemetry.gleam").
-export([disabled/0, with_handler/1, emit/2]).
-export_type([event/0, telemetry/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    "  Event hooks for observability.  Attach a handler with `telemetry.with_handler`\n"
    "  and pass the resulting `Telemetry` value to `repo.with_telemetry`.\n"
    "\n"
    "  Events: `QueryStart`, `QueryEnd`, `QueryError`, `TransactionStart`,\n"
    "  `TransactionCommit`, `TransactionRollback`.\n"
).

-type event() :: {query_start, binary(), integer()} |
    {query_end, binary(), integer(), integer()} |
    {query_error, binary(), binary()} |
    transaction_start |
    transaction_commit |
    transaction_rollback.

-type telemetry() :: {telemetry, gleam@option:option(fun((event()) -> nil))}.

-file("src/gloo/telemetry.gleam", 25).
-spec disabled() -> telemetry().
disabled() ->
    {telemetry, none}.

-file("src/gloo/telemetry.gleam", 29).
-spec with_handler(fun((event()) -> nil)) -> telemetry().
with_handler(Handler) ->
    {telemetry, {some, Handler}}.

-file("src/gloo/telemetry.gleam", 33).
-spec emit(telemetry(), event()) -> nil.
emit(Telemetry, Event) ->
    case erlang:element(2, Telemetry) of
        none ->
            nil;

        {some, H} ->
            H(Event)
    end.
