-module(gloo@adapter).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/gloo/adapter.gleam").
-export([postgres_quote/1, postgres_placeholder/1, sqlite_quote/1, sqlite_placeholder/1, execute_query/3, run_transaction/2, close/1]).
-export_type([db_connection/0, execute_result/0, adapter/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    "  Adapter — the sole DB-specific layer (V12).\n"
    "\n"
    "  `execute_query` and `run_transaction` dispatch to the correct backend\n"
    "  based on the `DbConnection` variant.  `repo`, `query`, `sql`, and\n"
    "  `validate` modules never import pog or sqlight directly.\n"
).

-type db_connection() :: {pg_connection,
        pog:connection(),
        gleam@erlang@process:pid_()} |
    {sq_connection, sqlight:connection()}.

-type execute_result() :: {execute_result,
        list(gleam@dynamic:dynamic_()),
        integer()}.

-type adapter() :: {adapter,
        binary(),
        db_connection(),
        fun((binary()) -> binary()),
        fun((integer()) -> binary()),
        integer(),
        gloo@telemetry:telemetry()}.

-file("src/gloo/adapter.gleam", 42).
-spec postgres_quote(binary()) -> binary().
postgres_quote(Identifier) ->
    <<<<"\""/utf8, Identifier/binary>>/binary, "\""/utf8>>.

-file("src/gloo/adapter.gleam", 46).
-spec postgres_placeholder(integer()) -> binary().
postgres_placeholder(N) ->
    <<"$"/utf8, (erlang:integer_to_binary(N))/binary>>.

-file("src/gloo/adapter.gleam", 50).
-spec sqlite_quote(binary()) -> binary().
sqlite_quote(Identifier) ->
    <<<<"\""/utf8, Identifier/binary>>/binary, "\""/utf8>>.

-file("src/gloo/adapter.gleam", 56).
?DOC(
    " SQLite uses `?` — parameters are bound positionally.\n"
    " The sql/query modules always produce `$N`; we convert at execution time.\n"
).
-spec sqlite_placeholder(integer()) -> binary().
sqlite_placeholder(_) ->
    <<"?"/utf8>>.

-file("src/gloo/adapter.gleam", 190).
-spec replace_pg_placeholders(binary(), integer()) -> binary().
replace_pg_placeholders(Sql, N) ->
    Placeholder = <<"$"/utf8, (erlang:integer_to_binary(N))/binary>>,
    case gleam_stdlib:contains_string(Sql, Placeholder) of
        false ->
            Sql;

        true ->
            replace_pg_placeholders(
                gleam@string:replace(Sql, Placeholder, <<"?"/utf8>>),
                N + 1
            )
    end.

-file("src/gloo/adapter.gleam", 186).
?DOC(" Converts `$N` placeholders to `?` for SQLite's positional binding.\n").
-spec sql_to_sqlite(binary()) -> binary().
sql_to_sqlite(Sql) ->
    replace_pg_placeholders(Sql, 1).

-file("src/gloo/adapter.gleam", 170).
-spec encode_sq_value(gloo@value:gloo_value()) -> {ok, sqlight:value()} |
    {error, nil}.
encode_sq_value(V) ->
    case V of
        {g_string, S} ->
            {ok, sqlight:text(S)};

        {g_int, N} ->
            {ok, sqlight:int(N)};

        {g_float, F} ->
            {ok, sqlight:float(F)};

        {g_bool, B} ->
            {ok, sqlight:bool(B)};

        {g_bit_array, Ba} ->
            {ok, sqlight_ffi:coerce_blob(Ba)};

        {g_timestamp, _} ->
            {error, nil};

        g_null ->
            {ok, sqlight_ffi:null()};

        {g_array, _} ->
            {error, nil};

        {g_string_array, _} ->
            {error, nil};

        {g_int_array, _} ->
            {error, nil}
    end.

-file("src/gloo/adapter.gleam", 154).
-spec sq_execute(sqlight:connection(), binary(), list(gloo@value:gloo_value())) -> {ok,
        execute_result()} |
    {error, gloo@error:gloo_error()}.
sq_execute(Conn, Sql, Params) ->
    Sq_params = gleam@list:filter_map(Params, fun encode_sq_value/1),
    case erlang:length(Sq_params) =:= erlang:length(Params) of
        false ->
            {error, {db_error, <<"unsupported value type for SQLite"/utf8>>}};

        true ->
            case sqlight:'query'(
                Sql,
                Conn,
                Sq_params,
                {decoder, fun gleam@dynamic@decode:decode_dynamic/1}
            ) of
                {ok, Rows} ->
                    {ok, {execute_result, Rows, erlang:length(Rows)}};

                {error, E} ->
                    {error, gloo@error:from_sqlight(E)}
            end
    end.

-file("src/gloo/adapter.gleam", 137).
-spec encode_pg_value(gloo@value:gloo_value()) -> pog:value().
encode_pg_value(V) ->
    case V of
        {g_string, S} ->
            pog_ffi:coerce(S);

        {g_int, N} ->
            pog_ffi:coerce(N);

        {g_float, F} ->
            pog_ffi:coerce(F);

        {g_bool, B} ->
            pog_ffi:coerce(B);

        {g_bit_array, Ba} ->
            pog_ffi:coerce(Ba);

        {g_timestamp, Ts} ->
            pog:timestamp(Ts);

        g_null ->
            pog:nullable(fun(X) -> X end, none);

        {g_array, Items} ->
            pog:array(fun encode_pg_value/1, Items);

        {g_string_array, Items@1} ->
            pog:array(fun pog_ffi:coerce/1, Items@1);

        {g_int_array, Items@2} ->
            pog:array(fun pog_ffi:coerce/1, Items@2)
    end.

-file("src/gloo/adapter.gleam", 120).
-spec pg_execute(pog:connection(), binary(), list(gloo@value:gloo_value())) -> {ok,
        execute_result()} |
    {error, gloo@error:gloo_error()}.
pg_execute(Conn, Sql, Params) ->
    Pg_params = gleam@list:map(Params, fun encode_pg_value/1),
    Result = begin
        _pipe = pog:'query'(Sql),
        _pipe@1 = gleam@list:fold(Pg_params, _pipe, fun pog:parameter/2),
        _pipe@2 = pog:returning(
            _pipe@1,
            {decoder, fun gleam@dynamic@decode:decode_dynamic/1}
        ),
        pog:execute(_pipe@2, Conn)
    end,
    case Result of
        {ok, R} ->
            {ok, {execute_result, erlang:element(3, R), erlang:element(2, R)}};

        {error, E} ->
            {error, gloo@error:from_pog(E)}
    end.

-file("src/gloo/adapter.gleam", 62).
-spec execute_query(adapter(), binary(), list(gloo@value:gloo_value())) -> {ok,
        execute_result()} |
    {error, gloo@error:gloo_error()}.
execute_query(Adapter, Sql, Params) ->
    case erlang:element(3, Adapter) of
        {pg_connection, Conn, _} ->
            pg_execute(Conn, Sql, Params);

        {sq_connection, Conn@1} ->
            sq_execute(Conn@1, sql_to_sqlite(Sql), Params)
    end.

-file("src/gloo/adapter.gleam", 75).
?DOC(
    " V5/V6: run a top-level transaction (savepoint_depth == 0).\n"
    " Ok → commit; Error → rollback.\n"
).
-spec run_transaction(
    adapter(),
    fun((adapter()) -> {ok, NNV} | {error, binary()})
) -> {ok, NNV} | {error, gloo@error:gloo_error()}.
run_transaction(Adapter, Callback) ->
    case erlang:element(3, Adapter) of
        {pg_connection, Conn, Pid} ->
            _pipe = pog:transaction(
                Conn,
                fun(Tx_conn) ->
                    Tx_adapter = {adapter,
                        erlang:element(2, Adapter),
                        {pg_connection, Tx_conn, Pid},
                        erlang:element(4, Adapter),
                        erlang:element(5, Adapter),
                        1,
                        erlang:element(7, Adapter)},
                    Callback(Tx_adapter)
                end
            ),
            gleam@result:map_error(_pipe, fun(E) -> case E of
                        {transaction_query_error, Qe} ->
                            gloo@error:from_pog(Qe);

                        {transaction_rolled_back, Msg} ->
                            {db_error, Msg}
                    end end);

        {sq_connection, Conn@1} ->
            case sqlight:exec(<<"BEGIN"/utf8>>, Conn@1) of
                {error, E@1} ->
                    {error, {db_error, erlang:element(3, E@1)}};

                {ok, _} ->
                    Tx_adapter@1 = {adapter,
                        erlang:element(2, Adapter),
                        erlang:element(3, Adapter),
                        erlang:element(4, Adapter),
                        erlang:element(5, Adapter),
                        1,
                        erlang:element(7, Adapter)},
                    case Callback(Tx_adapter@1) of
                        {ok, V} ->
                            case sqlight:exec(<<"COMMIT"/utf8>>, Conn@1) of
                                {ok, _} ->
                                    {ok, V};

                                {error, E@2} ->
                                    {error, {db_error, erlang:element(3, E@2)}}
                            end;

                        {error, Msg@1} ->
                            _ = sqlight:exec(<<"ROLLBACK"/utf8>>, Conn@1),
                            {error, {db_error, Msg@1}}
                    end
            end
    end.

-file("src/gloo/adapter.gleam", 201).
?DOC(
    " Close the underlying connection.  Stops the pog pool process for Postgres,\n"
    " releasing all held connections.  Idempotent: calling twice is safe.\n"
).
-spec close(adapter()) -> {ok, nil} | {error, binary()}.
close(Adapter) ->
    case erlang:element(3, Adapter) of
        {pg_connection, _, Pid} ->
            _ = erlang:exit(Pid, erlang:binary_to_atom(<<"normal"/utf8>>)),
            {ok, nil};

        {sq_connection, Conn} ->
            _pipe = sqlight:close(Conn),
            gleam@result:map_error(_pipe, fun(E) -> erlang:element(3, E) end)
    end.
