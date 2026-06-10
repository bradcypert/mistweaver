-module(gloo@value).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/gloo/value.gleam").
-export([nullable/2]).
-export_type([gloo_value/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    "  Adapter-agnostic parameter value type.\n"
    "\n"
    "  Use these constructors in `sql` and `query` modules — they are encoded\n"
    "  to DB-specific wire types by the adapter at execution time.\n"
).

-type gloo_value() :: {g_string, binary()} |
    {g_int, integer()} |
    {g_float, float()} |
    {g_bool, boolean()} |
    {g_bit_array, bitstring()} |
    {g_timestamp, gleam@time@timestamp:timestamp()} |
    g_null |
    {g_array, list(gloo_value())} |
    {g_string_array, list(binary())} |
    {g_int_array, list(integer())}.

-file("src/gloo/value.gleam", 28).
-spec nullable(fun((NNJ) -> gloo_value()), gleam@option:option(NNJ)) -> gloo_value().
nullable(Encoder, V) ->
    case V of
        none ->
            g_null;

        {some, A} ->
            Encoder(A)
    end.
