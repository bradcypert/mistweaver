-module(gloo@schema).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/gloo/schema.gleam").
-export_type([table/1]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    "  A `Table(t)` value pairs a Postgres table name with a row decoder.\n"
    "  Pass it to `query.from` to start a query, or to `migration.create_table`\n"
    "  to define the schema.\n"
).

-type table(JZT) :: {table,
        binary(),
        binary(),
        gleam@dynamic@decode:decoder(JZT)}.


