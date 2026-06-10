-module(gloo@migration).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/gloo/migration.gleam").
-export([column/2, not_null/1, primary_key/1, unique/1, default/2, new/3, with_down/2, execute_sql/4, create_table/4, drop_table/3, rename_table/4, add_column/4, drop_column/4, rename_column/5, change_column/5, create_index/5, drop_index/3, add_constraint/5, drop_constraint/4]).
-export_type([migration/0, column/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    "  DDL migration DSL.  Each migration has a `version` (integer timestamp),\n"
    "  a `name`, an `up` SQL string, and an optional `down` SQL string.\n"
    "\n"
    "  Build columns using the DB-specific modules (`gloo/pg`, `gloo/sqlite`)\n"
    "  then pass them to `create_table`, `add_column`, etc.\n"
    "  `gloo/migration` itself carries no column-type knowledge.\n"
).

-type migration() :: {migration,
        integer(),
        binary(),
        binary(),
        gleam@option:option(binary())}.

-type column() :: {column,
        binary(),
        binary(),
        boolean(),
        gleam@option:option(binary()),
        boolean(),
        boolean()}.

-file("src/gloo/migration.gleam", 31).
?DOC(
    " Low-level constructor that takes a raw SQL type string.\n"
    " Prefer `gloo/pg.column` or `gloo/sqlite.column` for type-safe construction.\n"
).
-spec column(binary(), binary()) -> column().
column(Name, Type_sql) ->
    {column, Name, Type_sql, true, none, false, false}.

-file("src/gloo/migration.gleam", 35).
-spec not_null(column()) -> column().
not_null(Col) ->
    {column,
        erlang:element(2, Col),
        erlang:element(3, Col),
        false,
        erlang:element(5, Col),
        erlang:element(6, Col),
        erlang:element(7, Col)}.

-file("src/gloo/migration.gleam", 39).
-spec primary_key(column()) -> column().
primary_key(Col) ->
    {column,
        erlang:element(2, Col),
        erlang:element(3, Col),
        false,
        erlang:element(5, Col),
        true,
        erlang:element(7, Col)}.

-file("src/gloo/migration.gleam", 43).
-spec unique(column()) -> column().
unique(Col) ->
    {column,
        erlang:element(2, Col),
        erlang:element(3, Col),
        erlang:element(4, Col),
        erlang:element(5, Col),
        erlang:element(6, Col),
        true}.

-file("src/gloo/migration.gleam", 47).
-spec default(column(), binary()) -> column().
default(Col, Expr) ->
    {column,
        erlang:element(2, Col),
        erlang:element(3, Col),
        erlang:element(4, Col),
        {some, Expr},
        erlang:element(6, Col),
        erlang:element(7, Col)}.

-file("src/gloo/migration.gleam", 53).
-spec new(integer(), binary(), binary()) -> migration().
new(V, N, U) ->
    {migration, V, N, U, none}.

-file("src/gloo/migration.gleam", 57).
-spec with_down(migration(), binary()) -> migration().
with_down(M, Down) ->
    {migration,
        erlang:element(2, M),
        erlang:element(3, M),
        erlang:element(4, M),
        {some, Down}}.

-file("src/gloo/migration.gleam", 61).
-spec execute_sql(integer(), binary(), binary(), binary()) -> migration().
execute_sql(V, N, Up, Down) ->
    {migration, V, N, Up, {some, Down}}.

-file("src/gloo/migration.gleam", 257).
-spec column_def(column()) -> binary().
column_def(Col) ->
    Null_sql = case erlang:element(4, Col) of
        true ->
            <<""/utf8>>;

        false ->
            <<" NOT NULL"/utf8>>
    end,
    Default_sql = case erlang:element(5, Col) of
        none ->
            <<""/utf8>>;

        {some, Expr} ->
            <<" DEFAULT "/utf8, Expr/binary>>
    end,
    Pk_sql = case erlang:element(6, Col) of
        true ->
            <<" PRIMARY KEY"/utf8>>;

        false ->
            <<""/utf8>>
    end,
    Unique_sql = case erlang:element(7, Col) of
        true ->
            <<" UNIQUE"/utf8>>;

        false ->
            <<""/utf8>>
    end,
    <<<<<<<<<<<<(erlang:element(2, Col))/binary, " "/utf8>>/binary,
                        (erlang:element(3, Col))/binary>>/binary,
                    Pk_sql/binary>>/binary,
                Unique_sql/binary>>/binary,
            Null_sql/binary>>/binary,
        Default_sql/binary>>.

-file("src/gloo/migration.gleam", 72).
-spec create_table(integer(), binary(), binary(), list(column())) -> migration().
create_table(V, N, Table, Cols) ->
    Col_defs = begin
        _pipe = gleam@list:map(Cols, fun column_def/1),
        gleam@string:join(_pipe, <<",\n  "/utf8>>)
    end,
    Up = <<<<<<<<"CREATE TABLE "/utf8, Table/binary>>/binary, " (\n  "/utf8>>/binary,
            Col_defs/binary>>/binary,
        "\n)"/utf8>>,
    {migration,
        V,
        N,
        Up,
        {some, <<"DROP TABLE IF EXISTS "/utf8, Table/binary>>}}.

-file("src/gloo/migration.gleam", 83).
-spec drop_table(integer(), binary(), binary()) -> migration().
drop_table(V, N, Table) ->
    {migration, V, N, <<"DROP TABLE IF EXISTS "/utf8, Table/binary>>, none}.

-file("src/gloo/migration.gleam", 96).
-spec rename_table(integer(), binary(), binary(), binary()) -> migration().
rename_table(V, N, From, To) ->
    {migration,
        V,
        N,
        <<<<<<"ALTER TABLE "/utf8, From/binary>>/binary, " RENAME TO "/utf8>>/binary,
            To/binary>>,
        {some,
            <<<<<<"ALTER TABLE "/utf8, To/binary>>/binary, " RENAME TO "/utf8>>/binary,
                From/binary>>}}.

-file("src/gloo/migration.gleam", 110).
-spec add_column(integer(), binary(), binary(), column()) -> migration().
add_column(V, N, Table, Col) ->
    {migration,
        V,
        N,
        <<<<<<"ALTER TABLE "/utf8, Table/binary>>/binary, " ADD COLUMN "/utf8>>/binary,
            (column_def(Col))/binary>>,
        {some,
            <<<<<<"ALTER TABLE "/utf8, Table/binary>>/binary,
                    " DROP COLUMN "/utf8>>/binary,
                (erlang:element(2, Col))/binary>>}}.

-file("src/gloo/migration.gleam", 129).
-spec drop_column(integer(), binary(), binary(), binary()) -> migration().
drop_column(V, N, Table, Col) ->
    {migration,
        V,
        N,
        <<<<<<"ALTER TABLE "/utf8, Table/binary>>/binary, " DROP COLUMN "/utf8>>/binary,
            Col/binary>>,
        none}.

-file("src/gloo/migration.gleam", 143).
-spec rename_column(integer(), binary(), binary(), binary(), binary()) -> migration().
rename_column(V, N, Table, From, To) ->
    {migration,
        V,
        N,
        <<<<<<<<<<"ALTER TABLE "/utf8, Table/binary>>/binary,
                        " RENAME COLUMN "/utf8>>/binary,
                    From/binary>>/binary,
                " TO "/utf8>>/binary,
            To/binary>>,
        {some,
            <<<<<<<<<<"ALTER TABLE "/utf8, Table/binary>>/binary,
                            " RENAME COLUMN "/utf8>>/binary,
                        To/binary>>/binary,
                    " TO "/utf8>>/binary,
                From/binary>>}}.

-file("src/gloo/migration.gleam", 170).
-spec change_column(integer(), binary(), binary(), binary(), binary()) -> migration().
change_column(V, N, Table, Col, New_type) ->
    {migration,
        V,
        N,
        <<<<<<<<<<"ALTER TABLE "/utf8, Table/binary>>/binary,
                        " ALTER COLUMN "/utf8>>/binary,
                    Col/binary>>/binary,
                " TYPE "/utf8>>/binary,
            New_type/binary>>,
        none}.

-file("src/gloo/migration.gleam", 185).
-spec create_index(integer(), binary(), binary(), binary(), list(binary())) -> migration().
create_index(V, N, Index, Table, Cols) ->
    {migration,
        V,
        N,
        <<<<<<<<<<<<"CREATE INDEX "/utf8, Index/binary>>/binary, " ON "/utf8>>/binary,
                        Table/binary>>/binary,
                    " ("/utf8>>/binary,
                (gleam@string:join(Cols, <<", "/utf8>>))/binary>>/binary,
            ")"/utf8>>,
        {some, <<"DROP INDEX IF EXISTS "/utf8, Index/binary>>}}.

-file("src/gloo/migration.gleam", 206).
-spec drop_index(integer(), binary(), binary()) -> migration().
drop_index(V, N, Index) ->
    {migration, V, N, <<"DROP INDEX IF EXISTS "/utf8, Index/binary>>, none}.

-file("src/gloo/migration.gleam", 219).
-spec add_constraint(integer(), binary(), binary(), binary(), binary()) -> migration().
add_constraint(V, N, Table, Constraint, Definition) ->
    {migration,
        V,
        N,
        <<<<<<<<<<"ALTER TABLE "/utf8, Table/binary>>/binary,
                        " ADD CONSTRAINT "/utf8>>/binary,
                    Constraint/binary>>/binary,
                " "/utf8>>/binary,
            Definition/binary>>,
        {some,
            <<<<<<"ALTER TABLE "/utf8, Table/binary>>/binary,
                    " DROP CONSTRAINT "/utf8>>/binary,
                Constraint/binary>>}}.

-file("src/gloo/migration.gleam", 241).
-spec drop_constraint(integer(), binary(), binary(), binary()) -> migration().
drop_constraint(V, N, Table, Constraint) ->
    {migration,
        V,
        N,
        <<<<<<"ALTER TABLE "/utf8, Table/binary>>/binary,
                " DROP CONSTRAINT "/utf8>>/binary,
            Constraint/binary>>,
        none}.
