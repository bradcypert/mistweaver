-module(gloo@query).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/gloo/query.gleam").
-export([from/1, insert/3, update/2, delete/1, where/2, order_by/3, limit/2, offset/2, returning/2, returning_columns/2, to_sql/1, decoder/1]).
-export_type(['query'/1, condition/0, direction/0, op/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    "  Single-table query builder.  Use `query.from(table)` to start, then pipe\n"
    "  through `where`, `order_by`, `limit`, `offset`, `insert`, `update`, or\n"
    "  `delete`.  A `Query(t)` is an inert value — it only executes when passed\n"
    "  to a `repo` function (`repo.query_all`, `repo.query_one`, etc.).\n"
    "\n"
    "  Available predicates: `Eq`, `Neq`, `Gt`, `Gte`, `Lt`, `Lte`, `In`,\n"
    "  `Like`, `IsNull`, `IsNotNull`, `And`, `Or`, `Not`.\n"
).

-opaque 'query'(NSU) :: {'query',
        binary(),
        op(),
        gleam@dynamic@decode:decoder(NSU)}.

-type condition() :: {eq, binary(), gloo@value:gloo_value()} |
    {neq, binary(), gloo@value:gloo_value()} |
    {gt, binary(), gloo@value:gloo_value()} |
    {gte, binary(), gloo@value:gloo_value()} |
    {lt, binary(), gloo@value:gloo_value()} |
    {lte, binary(), gloo@value:gloo_value()} |
    {in, binary(), list(gloo@value:gloo_value())} |
    {like, binary(), binary()} |
    {is_null, binary()} |
    {is_not_null, binary()} |
    {'and', list(condition())} |
    {'or', list(condition())} |
    {'not', condition()}.

-type direction() :: asc | desc.

-type op() :: {select,
        list(condition()),
        list({binary(), direction()}),
        gleam@option:option(integer()),
        gleam@option:option(integer())} |
    {insert,
        list(binary()),
        list(gloo@value:gloo_value()),
        gleam@option:option(list(binary()))} |
    {update, list({binary(), gloo@value:gloo_value()}), list(condition())} |
    {delete, list(condition())}.

-file("src/gloo/query.gleam", 63).
-spec from(gloo@schema:table(NSV)) -> 'query'(NSV).
from(Table) ->
    {'query',
        erlang:element(2, Table),
        {select, [], [], none, none},
        erlang:element(4, Table)}.

-file("src/gloo/query.gleam", 73).
-spec insert(
    'query'(NSY),
    gloo@schema:table(NSY),
    list({binary(), gloo@value:gloo_value()})
) -> 'query'(NSY).
insert(_, Table, Row) ->
    Cols = gleam@list:map(Row, fun(Pair) -> erlang:element(1, Pair) end),
    Vals = gleam@list:map(Row, fun(Pair@1) -> erlang:element(2, Pair@1) end),
    {'query',
        erlang:element(2, Table),
        {insert, Cols, Vals, none},
        erlang:element(4, Table)}.

-file("src/gloo/query.gleam", 87).
-spec update('query'(NTD), list({binary(), gloo@value:gloo_value()})) -> 'query'(NTD).
update(Query, Sets) ->
    {'query',
        erlang:element(2, Query),
        {update, Sets, []},
        erlang:element(4, Query)}.

-file("src/gloo/query.gleam", 94).
-spec delete('query'(NTH)) -> 'query'(NTH).
delete(Query) ->
    {'query', erlang:element(2, Query), {delete, []}, erlang:element(4, Query)}.

-file("src/gloo/query.gleam", 100).
-spec where('query'(NTK), condition()) -> 'query'(NTK).
where(Query, Condition) ->
    case erlang:element(3, Query) of
        {select, Conditions, Orders, Limit, Offset} ->
            {'query',
                erlang:element(2, Query),
                {select,
                    lists:append(Conditions, [Condition]),
                    Orders,
                    Limit,
                    Offset},
                erlang:element(4, Query)};

        {update, Sets, Conditions@1} ->
            {'query',
                erlang:element(2, Query),
                {update, Sets, lists:append(Conditions@1, [Condition])},
                erlang:element(4, Query)};

        {delete, Conditions@2} ->
            {'query',
                erlang:element(2, Query),
                {delete, lists:append(Conditions@2, [Condition])},
                erlang:element(4, Query)};

        {insert, _, _, _} ->
            Query
    end.

-file("src/gloo/query.gleam", 129).
-spec order_by('query'(NTN), binary(), direction()) -> 'query'(NTN).
order_by(Query, Column, Direction) ->
    case erlang:element(3, Query) of
        {select, Conditions, Orders, Limit, Offset} ->
            {'query',
                erlang:element(2, Query),
                {select,
                    Conditions,
                    lists:append(Orders, [{Column, Direction}]),
                    Limit,
                    Offset},
                erlang:element(4, Query)};

        _ ->
            Query
    end.

-file("src/gloo/query.gleam", 149).
-spec limit('query'(NTQ), integer()) -> 'query'(NTQ).
limit(Query, N) ->
    case erlang:element(3, Query) of
        {select, Conditions, Orders, _, Offset} ->
            {'query',
                erlang:element(2, Query),
                {select, Conditions, Orders, {some, N}, Offset},
                erlang:element(4, Query)};

        _ ->
            Query
    end.

-file("src/gloo/query.gleam", 160).
-spec offset('query'(NTT), integer()) -> 'query'(NTT).
offset(Query, N) ->
    case erlang:element(3, Query) of
        {select, Conditions, Orders, Limit, _} ->
            {'query',
                erlang:element(2, Query),
                {select, Conditions, Orders, Limit, {some, N}},
                erlang:element(4, Query)};

        _ ->
            Query
    end.

-file("src/gloo/query.gleam", 171).
-spec returning('query'(any()), gleam@dynamic@decode:decoder(NTY)) -> 'query'(NTY).
returning(Query, Decoder) ->
    {'query', erlang:element(2, Query), erlang:element(3, Query), Decoder}.

-file("src/gloo/query.gleam", 175).
-spec returning_columns('query'(NUB), list(binary())) -> 'query'(NUB).
returning_columns(Query, Cols) ->
    case erlang:element(3, Query) of
        {insert, Columns, Values, _} ->
            {'query',
                erlang:element(2, Query),
                {insert, Columns, Values, {some, Cols}},
                erlang:element(4, Query)};

        _ ->
            Query
    end.

-file("src/gloo/query.gleam", 317).
-spec condition_to_sql(condition(), integer()) -> {binary(),
    list(gloo@value:gloo_value()),
    integer()}.
condition_to_sql(Cond, N) ->
    case Cond of
        {eq, Col, Val} ->
            {<<<<Col/binary, " = $"/utf8>>/binary,
                    (erlang:integer_to_binary(N))/binary>>,
                [Val],
                N + 1};

        {neq, Col@1, Val@1} ->
            {<<<<Col@1/binary, " != $"/utf8>>/binary,
                    (erlang:integer_to_binary(N))/binary>>,
                [Val@1],
                N + 1};

        {gt, Col@2, Val@2} ->
            {<<<<Col@2/binary, " > $"/utf8>>/binary,
                    (erlang:integer_to_binary(N))/binary>>,
                [Val@2],
                N + 1};

        {gte, Col@3, Val@3} ->
            {<<<<Col@3/binary, " >= $"/utf8>>/binary,
                    (erlang:integer_to_binary(N))/binary>>,
                [Val@3],
                N + 1};

        {lt, Col@4, Val@4} ->
            {<<<<Col@4/binary, " < $"/utf8>>/binary,
                    (erlang:integer_to_binary(N))/binary>>,
                [Val@4],
                N + 1};

        {lte, Col@5, Val@5} ->
            {<<<<Col@5/binary, " <= $"/utf8>>/binary,
                    (erlang:integer_to_binary(N))/binary>>,
                [Val@5],
                N + 1};

        {in, Col@6, Vals} ->
            Placeholders = begin
                _pipe = gleam@list:index_map(
                    Vals,
                    fun(_, I) ->
                        <<"$"/utf8, (erlang:integer_to_binary(N + I))/binary>>
                    end
                ),
                gleam@string:join(_pipe, <<", "/utf8>>)
            end,
            {<<<<<<Col@6/binary, " IN ("/utf8>>/binary, Placeholders/binary>>/binary,
                    ")"/utf8>>,
                Vals,
                N + erlang:length(Vals)};

        {like, Col@7, Pattern} ->
            {<<<<Col@7/binary, " LIKE $"/utf8>>/binary,
                    (erlang:integer_to_binary(N))/binary>>,
                [{g_string, Pattern}],
                N + 1};

        {is_null, Col@8} ->
            {<<Col@8/binary, " IS NULL"/utf8>>, [], N};

        {is_not_null, Col@9} ->
            {<<Col@9/binary, " IS NOT NULL"/utf8>>, [], N};

        {'and', Conds} ->
            {Parts, Params, Next} = gleam@list:fold(
                Conds,
                {[], [], N},
                fun(Acc, C) ->
                    {Ps, Vs, Nn} = Acc,
                    {S, Vs2, Nn2} = condition_to_sql(C, Nn),
                    {lists:append(Ps, [S]), lists:append(Vs, Vs2), Nn2}
                end
            ),
            {<<<<"("/utf8, (gleam@string:join(Parts, <<" AND "/utf8>>))/binary>>/binary,
                    ")"/utf8>>,
                Params,
                Next};

        {'or', Conds@1} ->
            {Parts@1, Params@1, Next@1} = gleam@list:fold(
                Conds@1,
                {[], [], N},
                fun(Acc@1, C@1) ->
                    {Ps@1, Vs@1, Nn@1} = Acc@1,
                    {S@1, Vs2@1, Nn2@1} = condition_to_sql(C@1, Nn@1),
                    {lists:append(Ps@1, [S@1]),
                        lists:append(Vs@1, Vs2@1),
                        Nn2@1}
                end
            ),
            {<<<<"("/utf8,
                        (gleam@string:join(Parts@1, <<" OR "/utf8>>))/binary>>/binary,
                    ")"/utf8>>,
                Params@1,
                Next@1};

        {'not', Inner} ->
            {S@2, Vs@2, Nn@2} = condition_to_sql(Inner, N),
            {<<<<"NOT ("/utf8, S@2/binary>>/binary, ")"/utf8>>, Vs@2, Nn@2}
    end.

-file("src/gloo/query.gleam", 298).
-spec conditions_to_sql(list(condition()), integer()) -> {binary(),
    list(gloo@value:gloo_value()),
    integer()}.
conditions_to_sql(Conditions, Start) ->
    case Conditions of
        [] ->
            {<<""/utf8>>, [], Start};

        _ ->
            {Parts@1, Params@1, Next} = gleam@list:fold(
                Conditions,
                {[], [], Start},
                fun(Acc, Cond) ->
                    {Parts, Params, N} = Acc,
                    {Sql, Vals, N2} = condition_to_sql(Cond, N),
                    {lists:append(Parts, [Sql]), lists:append(Params, Vals), N2}
                end
            ),
            Where = <<" WHERE "/utf8,
                (gleam@string:join(Parts@1, <<" AND "/utf8>>))/binary>>,
            {Where, Params@1, Next}
    end.

-file("src/gloo/query.gleam", 290).
-spec build_delete(binary(), list(condition())) -> {binary(),
    list(gloo@value:gloo_value())}.
build_delete(Table, Conditions) ->
    {Where_sql, Params, _} = conditions_to_sql(Conditions, 1),
    {<<<<"DELETE FROM "/utf8, Table/binary>>/binary, Where_sql/binary>>, Params}.

-file("src/gloo/query.gleam", 273).
-spec build_update(
    binary(),
    list({binary(), gloo@value:gloo_value()}),
    list(condition())
) -> {binary(), list(gloo@value:gloo_value())}.
build_update(Table, Sets, Conditions) ->
    {Set_parts, Set_vals} = begin
        _pipe = gleam@list:index_map(
            Sets,
            fun(Pair, I) ->
                {<<<<(erlang:element(1, Pair))/binary, " = $"/utf8>>/binary,
                        (erlang:integer_to_binary(I + 1))/binary>>,
                    erlang:element(2, Pair)}
            end
        ),
        gleam@list:unzip(_pipe)
    end,
    Set_sql = gleam@string:join(Set_parts, <<", "/utf8>>),
    Param_start = erlang:length(Sets) + 1,
    {Where_sql, Where_vals, _} = conditions_to_sql(Conditions, Param_start),
    Sql = <<<<<<<<"UPDATE "/utf8, Table/binary>>/binary, " SET "/utf8>>/binary,
            Set_sql/binary>>/binary,
        Where_sql/binary>>,
    {Sql, lists:append(Set_vals, Where_vals)}.

-file("src/gloo/query.gleam", 232).
-spec build_select(
    binary(),
    list(condition()),
    list({binary(), direction()}),
    gleam@option:option(integer()),
    gleam@option:option(integer())
) -> {binary(), list(gloo@value:gloo_value())}.
build_select(Table, Conditions, Orders, Lim, Off) ->
    {Where_sql, Params, _} = conditions_to_sql(Conditions, 1),
    Order_sql = case Orders of
        [] ->
            <<""/utf8>>;

        _ ->
            <<" ORDER BY "/utf8,
                (gleam@string:join(
                    gleam@list:map(
                        Orders,
                        fun(O) ->
                            <<(erlang:element(1, O))/binary,
                                (case erlang:element(2, O) of
                                    asc ->
                                        <<" ASC"/utf8>>;

                                    desc ->
                                        <<" DESC"/utf8>>
                                end)/binary>>
                        end
                    ),
                    <<", "/utf8>>
                ))/binary>>
    end,
    Limit_sql = case Lim of
        none ->
            <<""/utf8>>;

        {some, N} ->
            <<" LIMIT "/utf8, (erlang:integer_to_binary(N))/binary>>
    end,
    Offset_sql = case Off of
        none ->
            <<""/utf8>>;

        {some, N@1} ->
            <<" OFFSET "/utf8, (erlang:integer_to_binary(N@1))/binary>>
    end,
    Sql = <<<<<<<<<<"SELECT * FROM "/utf8, Table/binary>>/binary,
                    Where_sql/binary>>/binary,
                Order_sql/binary>>/binary,
            Limit_sql/binary>>/binary,
        Offset_sql/binary>>,
    {Sql, Params}.

-file("src/gloo/query.gleam", 206).
-spec build_insert(
    binary(),
    list(binary()),
    list(gloo@value:gloo_value()),
    gleam@option:option(list(binary()))
) -> {binary(), list(gloo@value:gloo_value())}.
build_insert(Table, Columns, Values, Ret) ->
    Cols = gleam@string:join(Columns, <<", "/utf8>>),
    Placeholders = begin
        _pipe = gleam@list:index_map(
            Values,
            fun(_, I) ->
                <<"$"/utf8, (erlang:integer_to_binary(I + 1))/binary>>
            end
        ),
        gleam@string:join(_pipe, <<", "/utf8>>)
    end,
    Ret_sql = case Ret of
        none ->
            <<""/utf8>>;

        {some, Cs} ->
            <<" RETURNING "/utf8,
                (gleam@string:join(Cs, <<", "/utf8>>))/binary>>
    end,
    Sql = <<<<<<<<<<<<<<"INSERT INTO "/utf8, Table/binary>>/binary, " ("/utf8>>/binary,
                        Cols/binary>>/binary,
                    ") VALUES ("/utf8>>/binary,
                Placeholders/binary>>/binary,
            ")"/utf8>>/binary,
        Ret_sql/binary>>,
    {Sql, Values}.

-file("src/gloo/query.gleam", 188).
-spec to_sql('query'(any())) -> {binary(), list(gloo@value:gloo_value())}.
to_sql(Query) ->
    Table = <<<<"\""/utf8, (erlang:element(2, Query))/binary>>/binary,
        "\""/utf8>>,
    case erlang:element(3, Query) of
        {insert, Columns, Values, Returning_cols} ->
            build_insert(Table, Columns, Values, Returning_cols);

        {select, Conditions, Orders, Limit, Offset} ->
            build_select(Table, Conditions, Orders, Limit, Offset);

        {update, Sets, Conditions@1} ->
            build_update(Table, Sets, Conditions@1);

        {delete, Conditions@2} ->
            build_delete(Table, Conditions@2)
    end.

-file("src/gloo/query.gleam", 200).
-spec decoder('query'(NUI)) -> gleam@dynamic@decode:decoder(NUI).
decoder(Query) ->
    erlang:element(4, Query).
