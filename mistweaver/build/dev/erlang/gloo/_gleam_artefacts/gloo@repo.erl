-module(gloo@repo).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/gloo/repo.gleam").
-export([from_adapter/1, adapter_name/1, with_telemetry/2, all/4, one_from_rows/1, one/4, maybe_one_from_rows/1, maybe_one/4, execute/3, transaction/2, query_all/2, query_one/2, query_maybe_one/2, query_execute/2, sql_all/2, sql_one/2, sql_maybe_one/2, sql_execute/2, close/1]).
-export_type([repo/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    "  Execute queries against a database connection pool.\n"
    "\n"
    "  Functions accept either a `Query(t)` (from the query builder), a `Sql(t)`\n"
    "  (from the sql module), or a plain SQL string + params list.\n"
    "\n"
    "  Transaction semantics: `Ok` commits, `Error` rolls back.  Nested\n"
    "  `repo.transaction` calls automatically become savepoints.\n"
).

-opaque repo() :: {repo, gloo@adapter:adapter()}.

-file("src/gloo/repo.gleam", 24).
-spec from_adapter(gloo@adapter:adapter()) -> repo().
from_adapter(Adapter) ->
    {repo, Adapter}.

-file("src/gloo/repo.gleam", 28).
-spec adapter_name(repo()) -> binary().
adapter_name(Repo) ->
    {repo, Adapter} = Repo,
    erlang:element(2, Adapter).

-file("src/gloo/repo.gleam", 33).
-spec with_telemetry(repo(), gloo@telemetry:telemetry()) -> repo().
with_telemetry(Repo, T) ->
    {repo, Adapter} = Repo,
    {repo,
        {adapter,
            erlang:element(2, Adapter),
            erlang:element(3, Adapter),
            erlang:element(4, Adapter),
            erlang:element(5, Adapter),
            erlang:element(6, Adapter),
            T}}.

-file("src/gloo/repo.gleam", 38).
-spec all(
    repo(),
    binary(),
    list(gloo@value:gloo_value()),
    gleam@dynamic@decode:decoder(ODZ)
) -> {ok, list(ODZ)} | {error, gloo@error:gloo_error()}.
all(Repo, Sql, Params, Decoder) ->
    {repo, Adapter} = Repo,
    gloo@telemetry:emit(
        erlang:element(7, Adapter),
        {query_start, Sql, erlang:length(Params)}
    ),
    case gloo@adapter:execute_query(Adapter, Sql, Params) of
        {ok, {execute_result, Rows, Count}} ->
            gloo@telemetry:emit(
                erlang:element(7, Adapter),
                {query_end, Sql, 0, Count}
            ),
            gleam@list:try_map(
                Rows,
                fun(Row) -> _pipe = gleam@dynamic@decode:run(Row, Decoder),
                    gleam@result:map_error(_pipe, fun(Errs) -> case Errs of
                                [{decode_error, Expected, Found, _} | _] ->
                                    {db_error,
                                        <<<<<<"decode error: expected "/utf8,
                                                    Expected/binary>>/binary,
                                                ", got "/utf8>>/binary,
                                            Found/binary>>};

                                [] ->
                                    {db_error, <<"decode error"/utf8>>}
                            end end) end
            );

        {error, E} ->
            gloo@telemetry:emit(
                erlang:element(7, Adapter),
                {query_error, Sql, gloo@error:to_string(E)}
            ),
            {error, E}
    end.

-file("src/gloo/repo.gleam", 164).
-spec one_from_rows(list(OEZ)) -> {ok, OEZ} | {error, gloo@error:gloo_error()}.
one_from_rows(Rows) ->
    case Rows of
        [Row] ->
            {ok, Row};

        [] ->
            {error, no_result_error};

        _ ->
            {error, {too_many_results_error, erlang:length(Rows)}}
    end.

-file("src/gloo/repo.gleam", 76).
-spec one(
    repo(),
    binary(),
    list(gloo@value:gloo_value()),
    gleam@dynamic@decode:decoder(OEF)
) -> {ok, OEF} | {error, gloo@error:gloo_error()}.
one(Repo, Sql, Params, Decoder) ->
    gleam@result:'try'(
        all(Repo, Sql, Params, Decoder),
        fun(Rows) -> one_from_rows(Rows) end
    ).

-file("src/gloo/repo.gleam", 172).
-spec maybe_one_from_rows(list(OFD)) -> {ok, gleam@option:option(OFD)} |
    {error, gloo@error:gloo_error()}.
maybe_one_from_rows(Rows) ->
    case Rows of
        [] ->
            {ok, none};

        [Row] ->
            {ok, {some, Row}};

        _ ->
            {error, {too_many_results_error, erlang:length(Rows)}}
    end.

-file("src/gloo/repo.gleam", 86).
-spec maybe_one(
    repo(),
    binary(),
    list(gloo@value:gloo_value()),
    gleam@dynamic@decode:decoder(OEK)
) -> {ok, gleam@option:option(OEK)} | {error, gloo@error:gloo_error()}.
maybe_one(Repo, Sql, Params, Decoder) ->
    gleam@result:'try'(
        all(Repo, Sql, Params, Decoder),
        fun(Rows) -> maybe_one_from_rows(Rows) end
    ).

-file("src/gloo/repo.gleam", 96).
-spec execute(repo(), binary(), list(gloo@value:gloo_value())) -> {ok,
        integer()} |
    {error, gloo@error:gloo_error()}.
execute(Repo, Sql, Params) ->
    {repo, Adapter} = Repo,
    gloo@telemetry:emit(
        erlang:element(7, Adapter),
        {query_start, Sql, erlang:length(Params)}
    ),
    case gloo@adapter:execute_query(Adapter, Sql, Params) of
        {ok, {execute_result, _, Count}} ->
            gloo@telemetry:emit(
                erlang:element(7, Adapter),
                {query_end, Sql, 0, Count}
            ),
            {ok, Count};

        {error, E} ->
            gloo@telemetry:emit(
                erlang:element(7, Adapter),
                {query_error, Sql, gloo@error:to_string(E)}
            ),
            {error, E}
    end.

-file("src/gloo/repo.gleam", 155).
-spec run_sql(repo(), binary()) -> {ok, nil} | {error, gloo@error:gloo_error()}.
run_sql(Repo, Sql) ->
    _pipe = execute(Repo, Sql, []),
    gleam@result:map(_pipe, fun(_) -> nil end).

-file("src/gloo/repo.gleam", 126).
?DOC(
    " V5: Ok → commit, Error → rollback.\n"
    " V6: nested calls become savepoints (savepoint_depth > 0).\n"
).
-spec transaction(
    repo(),
    fun((repo()) -> {ok, OES} | {error, gloo@error:gloo_error()})
) -> {ok, OES} | {error, gloo@error:gloo_error()}.
transaction(Repo, Callback) ->
    {repo, Adapter} = Repo,
    case erlang:element(6, Adapter) of
        0 ->
            gloo@adapter:run_transaction(
                Adapter,
                fun(Tx_adapter) -> _pipe = Callback({repo, Tx_adapter}),
                    gleam@result:map_error(_pipe, fun gloo@error:to_string/1) end
            );

        Depth ->
            Sp = <<"sp_"/utf8, (erlang:integer_to_binary(Depth))/binary>>,
            gleam@result:'try'(
                run_sql(Repo, <<"SAVEPOINT "/utf8, Sp/binary>>),
                fun(_) ->
                    case Callback(
                        {repo,
                            {adapter,
                                erlang:element(2, Adapter),
                                erlang:element(3, Adapter),
                                erlang:element(4, Adapter),
                                erlang:element(5, Adapter),
                                Depth + 1,
                                erlang:element(7, Adapter)}}
                    ) of
                        {ok, V} ->
                            gleam@result:'try'(
                                run_sql(
                                    Repo,
                                    <<"RELEASE SAVEPOINT "/utf8, Sp/binary>>
                                ),
                                fun(_) -> {ok, V} end
                            );

                        {error, E} ->
                            gleam@result:'try'(
                                run_sql(
                                    Repo,
                                    <<"ROLLBACK TO SAVEPOINT "/utf8, Sp/binary>>
                                ),
                                fun(_) -> {error, E} end
                            )
                    end
                end
            )
    end.

-file("src/gloo/repo.gleam", 182).
-spec query_all(repo(), gloo@query:'query'(OFI)) -> {ok, list(OFI)} |
    {error, gloo@error:gloo_error()}.
query_all(Repo, Q) ->
    {Sql, Params} = gloo@query:to_sql(Q),
    all(Repo, Sql, Params, gloo@query:decoder(Q)).

-file("src/gloo/repo.gleam", 190).
-spec query_one(repo(), gloo@query:'query'(OFN)) -> {ok, OFN} |
    {error, gloo@error:gloo_error()}.
query_one(Repo, Q) ->
    {Sql, Params} = gloo@query:to_sql(Q),
    one(Repo, Sql, Params, gloo@query:decoder(Q)).

-file("src/gloo/repo.gleam", 198).
-spec query_maybe_one(repo(), gloo@query:'query'(OFR)) -> {ok,
        gleam@option:option(OFR)} |
    {error, gloo@error:gloo_error()}.
query_maybe_one(Repo, Q) ->
    {Sql, Params} = gloo@query:to_sql(Q),
    maybe_one(Repo, Sql, Params, gloo@query:decoder(Q)).

-file("src/gloo/repo.gleam", 206).
-spec query_execute(repo(), gloo@query:'query'(any())) -> {ok, integer()} |
    {error, gloo@error:gloo_error()}.
query_execute(Repo, Q) ->
    {Sql, Params} = gloo@query:to_sql(Q),
    execute(Repo, Sql, Params).

-file("src/gloo/repo.gleam", 216).
-spec sql_all(repo(), gloo@sql:sql(OGA)) -> {ok, list(OGA)} |
    {error, gloo@error:gloo_error()}.
sql_all(Repo, S) ->
    {Statement, Parameters, Decoder} = gloo@sql:to_parts(S),
    all(Repo, Statement, Parameters, Decoder).

-file("src/gloo/repo.gleam", 221).
-spec sql_one(repo(), gloo@sql:sql(OGF)) -> {ok, OGF} |
    {error, gloo@error:gloo_error()}.
sql_one(Repo, S) ->
    {Statement, Parameters, Decoder} = gloo@sql:to_parts(S),
    one(Repo, Statement, Parameters, Decoder).

-file("src/gloo/repo.gleam", 226).
-spec sql_maybe_one(repo(), gloo@sql:sql(OGJ)) -> {ok, gleam@option:option(OGJ)} |
    {error, gloo@error:gloo_error()}.
sql_maybe_one(Repo, S) ->
    {Statement, Parameters, Decoder} = gloo@sql:to_parts(S),
    maybe_one(Repo, Statement, Parameters, Decoder).

-file("src/gloo/repo.gleam", 234).
-spec sql_execute(repo(), gloo@sql:sql(any())) -> {ok, integer()} |
    {error, gloo@error:gloo_error()}.
sql_execute(Repo, S) ->
    {Statement, Parameters, _} = gloo@sql:to_parts(S),
    execute(Repo, Statement, Parameters).

-file("src/gloo/repo.gleam", 242).
?DOC(
    " Close the underlying DB connection.  For Postgres this stops the pool\n"
    " process and releases all held connections.  For SQLite this closes the file.\n"
    " Idempotent: calling twice is safe.\n"
).
-spec close(repo()) -> {ok, nil} | {error, binary()}.
close(Repo) ->
    {repo, Adapter} = Repo,
    gloo@adapter:close(Adapter).
