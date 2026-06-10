-module(gloo@pg).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/gloo/pg.gleam").
-export([type_sql/1, column/2, not_null/1, primary_key/1, unique/1, default/2]).
-export_type([pg_column_type/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    "  Postgres column types for use with `gloo/migration`.\n"
    "\n"
    "  Build columns with `pg.column(name, type)` then pass them to the\n"
    "  migration DSL.  The modifier functions (`not_null`, `primary_key`,\n"
    "  `unique`, `default`) are re-exported here so callers only need to\n"
    "  import `gloo/pg`.\n"
).

-type pg_column_type() :: text |
    {var_char, integer()} |
    integer |
    big_int |
    small_int |
    boolean |
    timestamp |
    timestamp_tz |
    date |
    time |
    uuid |
    {numeric, integer(), integer()} |
    json_b |
    byte_a |
    serial |
    big_serial |
    real |
    double_precision.

-file("src/gloo/pg.gleam", 33).
?DOC(" Render a Postgres column type to its DDL SQL string.\n").
-spec type_sql(pg_column_type()) -> binary().
type_sql(T) ->
    case T of
        text ->
            <<"TEXT"/utf8>>;

        {var_char, N} ->
            <<<<"VARCHAR("/utf8, (erlang:integer_to_binary(N))/binary>>/binary,
                ")"/utf8>>;

        integer ->
            <<"INTEGER"/utf8>>;

        big_int ->
            <<"BIGINT"/utf8>>;

        small_int ->
            <<"SMALLINT"/utf8>>;

        boolean ->
            <<"BOOLEAN"/utf8>>;

        timestamp ->
            <<"TIMESTAMP"/utf8>>;

        timestamp_tz ->
            <<"TIMESTAMPTZ"/utf8>>;

        date ->
            <<"DATE"/utf8>>;

        time ->
            <<"TIME"/utf8>>;

        uuid ->
            <<"UUID"/utf8>>;

        {numeric, P, S} ->
            <<<<<<<<"NUMERIC("/utf8, (erlang:integer_to_binary(P))/binary>>/binary,
                        ", "/utf8>>/binary,
                    (erlang:integer_to_binary(S))/binary>>/binary,
                ")"/utf8>>;

        json_b ->
            <<"JSONB"/utf8>>;

        byte_a ->
            <<"BYTEA"/utf8>>;

        serial ->
            <<"SERIAL"/utf8>>;

        big_serial ->
            <<"BIGSERIAL"/utf8>>;

        real ->
            <<"REAL"/utf8>>;

        double_precision ->
            <<"DOUBLE PRECISION"/utf8>>
    end.

-file("src/gloo/pg.gleam", 59).
?DOC(
    " Create a Postgres-typed column.  Compile error if you pass a\n"
    " `gloo/sqlite.SqColumnType` — they are different types.\n"
).
-spec column(binary(), pg_column_type()) -> gloo@migration:column().
column(Name, T) ->
    gloo@migration:column(Name, type_sql(T)).

-file("src/gloo/pg.gleam", 63).
-spec not_null(gloo@migration:column()) -> gloo@migration:column().
not_null(Col) ->
    gloo@migration:not_null(Col).

-file("src/gloo/pg.gleam", 67).
-spec primary_key(gloo@migration:column()) -> gloo@migration:column().
primary_key(Col) ->
    gloo@migration:primary_key(Col).

-file("src/gloo/pg.gleam", 71).
-spec unique(gloo@migration:column()) -> gloo@migration:column().
unique(Col) ->
    gloo@migration:unique(Col).

-file("src/gloo/pg.gleam", 75).
-spec default(gloo@migration:column(), binary()) -> gloo@migration:column().
default(Col, Expr) ->
    gloo@migration:default(Col, Expr).
