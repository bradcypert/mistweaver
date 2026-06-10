-module(gloo@sqlite).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/gloo/sqlite.gleam").
-export([type_sql/1, column/2, not_null/1, primary_key/1, unique/1, default/2]).
-export_type([sq_column_type/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    "  SQLite column types for use with `gloo/migration`.\n"
    "\n"
    "  Build columns with `sqlite.column(name, type)` then pass them to the\n"
    "  migration DSL.  Autoincrement is achieved by applying `primary_key` to\n"
    "  an `Integer` column — SQLite's rowid mechanism handles the rest.\n"
    "\n"
    "  Passing a `SqColumnType` to `gloo/pg.column` (or vice versa) is a\n"
    "  compile error because the types are distinct.\n"
).

-type sq_column_type() :: integer | text | real | blob.

-file("src/gloo/sqlite.gleam", 20).
?DOC(" Render a SQLite column type to its DDL SQL string.\n").
-spec type_sql(sq_column_type()) -> binary().
type_sql(T) ->
    case T of
        integer ->
            <<"INTEGER"/utf8>>;

        text ->
            <<"TEXT"/utf8>>;

        real ->
            <<"REAL"/utf8>>;

        blob ->
            <<"BLOB"/utf8>>
    end.

-file("src/gloo/sqlite.gleam", 31).
?DOC(
    " Create a SQLite-typed column.  Compile error if you pass a\n"
    " `gloo/pg.PgColumnType` — they are different types.\n"
).
-spec column(binary(), sq_column_type()) -> gloo@migration:column().
column(Name, T) ->
    gloo@migration:column(Name, type_sql(T)).

-file("src/gloo/sqlite.gleam", 35).
-spec not_null(gloo@migration:column()) -> gloo@migration:column().
not_null(Col) ->
    gloo@migration:not_null(Col).

-file("src/gloo/sqlite.gleam", 39).
-spec primary_key(gloo@migration:column()) -> gloo@migration:column().
primary_key(Col) ->
    gloo@migration:primary_key(Col).

-file("src/gloo/sqlite.gleam", 43).
-spec unique(gloo@migration:column()) -> gloo@migration:column().
unique(Col) ->
    gloo@migration:unique(Col).

-file("src/gloo/sqlite.gleam", 47).
-spec default(gloo@migration:column(), binary()) -> gloo@migration:column().
default(Col, Expr) ->
    gloo@migration:default(Col, Expr).
