-module(gloo@sql).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/gloo/sql.gleam").
-export([string/1, int/1, bool/1, time/1, uuid/1, nullable/2, 'query'/1, param/2, params/2, returns/2, in_clause/2, unnest/2, to_parts/1]).
-export_type([sql/1]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    "  Typed raw SQL builder.  Use when a query spans multiple tables or needs\n"
    "  features the query builder does not cover.\n"
    "\n"
    "  ```gleam\n"
    "  sql.query(\"SELECT * FROM users WHERE id = $1\")\n"
    "  |> sql.param(sql.int(id))\n"
    "  |> sql.returns(user_decoder)\n"
    "  |> repo.sql_one(r, _)\n"
    "  ```\n"
    "\n"
    "  Value constructors: `string`, `int`, `bool`, `time`, `uuid`, `nullable`.\n"
    "  A `Sql(t)` value is inert until passed to a `repo.sql_*` function.\n"
).

-opaque sql(KIT) :: {sql,
        binary(),
        list(gloo@value:gloo_value()),
        gleam@dynamic@decode:decoder(KIT),
        integer()}.

-file("src/gloo/sql.gleam", 36).
-spec string(binary()) -> gloo@value:gloo_value().
string(V) ->
    {g_string, V}.

-file("src/gloo/sql.gleam", 40).
-spec int(integer()) -> gloo@value:gloo_value().
int(V) ->
    {g_int, V}.

-file("src/gloo/sql.gleam", 44).
-spec bool(boolean()) -> gloo@value:gloo_value().
bool(V) ->
    {g_bool, V}.

-file("src/gloo/sql.gleam", 48).
-spec time(birl:time()) -> gloo@value:gloo_value().
time(V) ->
    Micros = birl:to_unix_micro(V),
    Seconds = Micros div 1000000,
    Nanoseconds = (Micros rem 1000000) * 1000,
    {g_timestamp,
        gleam@time@timestamp:from_unix_seconds_and_nanoseconds(
            Seconds,
            Nanoseconds
        )}.

-file("src/gloo/sql.gleam", 55).
-spec uuid(binary()) -> gloo@value:gloo_value().
uuid(V) ->
    {g_string, V}.

-file("src/gloo/sql.gleam", 59).
-spec nullable(fun((KIU) -> gloo@value:gloo_value()), gleam@option:option(KIU)) -> gloo@value:gloo_value().
nullable(Encoder, V) ->
    gloo@value:nullable(Encoder, V).

-file("src/gloo/sql.gleam", 65).
-spec 'query'(binary()) -> sql(nil).
'query'(Statement) ->
    {sql, Statement, [], gleam@dynamic@decode:success(nil), 0}.

-file("src/gloo/sql.gleam", 74).
-spec param(sql(KIX), gloo@value:gloo_value()) -> sql(KIX).
param(Sql, V) ->
    {sql,
        erlang:element(2, Sql),
        lists:append(erlang:element(3, Sql), [V]),
        erlang:element(4, Sql),
        erlang:element(5, Sql) + 1}.

-file("src/gloo/sql.gleam", 82).
-spec params(sql(KJA), list(gloo@value:gloo_value())) -> sql(KJA).
params(Sql, Values) ->
    gleam@list:fold(Values, Sql, fun param/2).

-file("src/gloo/sql.gleam", 86).
-spec returns(sql(any()), gleam@dynamic@decode:decoder(KJG)) -> sql(KJG).
returns(Sql, Decoder) ->
    {sql,
        erlang:element(2, Sql),
        erlang:element(3, Sql),
        Decoder,
        erlang:element(5, Sql)}.

-file("src/gloo/sql.gleam", 97).
?DOC(
    " Generates `($n, $n+1, ...)` for use in an IN clause.\n"
    " Returns the placeholder fragment and the updated Sql with params added.\n"
).
-spec in_clause(sql(KJJ), list(gloo@value:gloo_value())) -> {sql(KJJ), binary()}.
in_clause(Sql, Values) ->
    Start = erlang:element(5, Sql) + 1,
    Placeholders = begin
        _pipe = gleam@list:index_map(
            Values,
            fun(_, I) ->
                <<"$"/utf8, (erlang:integer_to_binary(Start + I))/binary>>
            end
        ),
        gleam@string:join(_pipe, <<", "/utf8>>)
    end,
    Clause = <<<<"("/utf8, Placeholders/binary>>/binary, ")"/utf8>>,
    {params(Sql, Values), Clause}.

-file("src/gloo/sql.gleam", 110).
?DOC(" Encodes a list as a Postgres array for use with UNNEST (Postgres-only).\n").
-spec unnest(fun((KJN) -> gloo@value:gloo_value()), list(KJN)) -> gloo@value:gloo_value().
unnest(Encoder, Values) ->
    {g_array, gleam@list:map(Values, Encoder)}.

-file("src/gloo/sql.gleam", 116).
-spec to_parts(sql(KJP)) -> {binary(),
    list(gloo@value:gloo_value()),
    gleam@dynamic@decode:decoder(KJP)}.
to_parts(Sql) ->
    {erlang:element(2, Sql), erlang:element(3, Sql), erlang:element(4, Sql)}.
