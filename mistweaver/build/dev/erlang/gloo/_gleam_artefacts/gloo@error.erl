-module(gloo@error).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/gloo/error.gleam").
-export([from_pog/1, from_sqlight/1, to_string/1, map_constraint/4, map_constraints/3]).
-export_type([gloo_error/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    "  All errors returned by gloom repo functions are wrapped in `GlooError`.\n"
    "\n"
    "  Use `map_constraint` or `map_constraints` to convert `ConstraintError`\n"
    "  into application-specific error types without losing the constraint name.\n"
).

-type gloo_error() :: no_result_error |
    {too_many_results_error, integer()} |
    {constraint_error, binary()} |
    {db_error, binary()} |
    rollback_error.

-file("src/gloo/error.gleam", 116).
-spec decode_errors_to_string(list(gleam@dynamic@decode:decode_error())) -> binary().
decode_errors_to_string(Errors) ->
    case Errors of
        [] ->
            <<"unknown"/utf8>>;

        [E | _] ->
            <<<<(erlang:element(2, E))/binary, " expected, got "/utf8>>/binary,
                (erlang:element(3, E))/binary>>
    end.

-file("src/gloo/error.gleam", 19).
-spec from_pog(pog:query_error()) -> gloo_error().
from_pog(E) ->
    case E of
        {constraint_violated, _, Name, _} ->
            {constraint_error, Name};

        {postgresql_error, _, _, Msg} ->
            {db_error, Msg};

        {unexpected_result_type, Errors} ->
            {db_error,
                <<"decode error: "/utf8,
                    (decode_errors_to_string(Errors))/binary>>};

        {unexpected_argument_count, E@1, G} ->
            {db_error,
                <<<<<<"wrong argument count: expected "/utf8,
                            (erlang:integer_to_binary(E@1))/binary>>/binary,
                        " got "/utf8>>/binary,
                    (erlang:integer_to_binary(G))/binary>>};

        {unexpected_argument_type, E@2, G@1} ->
            {db_error,
                <<<<<<"wrong argument type: expected "/utf8, E@2/binary>>/binary,
                        " got "/utf8>>/binary,
                    G@1/binary>>};

        query_timeout ->
            {db_error, <<"query timeout"/utf8>>};

        connection_unavailable ->
            {db_error, <<"connection unavailable"/utf8>>}
    end.

-file("src/gloo/error.gleam", 39).
-spec from_sqlight(sqlight:error()) -> gloo_error().
from_sqlight(E) ->
    case E of
        {sqlight_error, constraint_unique, Msg, _} ->
            {constraint_error, Msg};

        {sqlight_error, constraint_primarykey, Msg@1, _} ->
            {constraint_error, Msg@1};

        {sqlight_error, constraint_check, Msg@2, _} ->
            {constraint_error, Msg@2};

        {sqlight_error, constraint_foreignkey, Msg@3, _} ->
            {constraint_error, Msg@3};

        {sqlight_error, _, Msg@4, _} ->
            {db_error, Msg@4}
    end.

-file("src/gloo/error.gleam", 53).
-spec to_string(gloo_error()) -> binary().
to_string(E) ->
    case E of
        no_result_error ->
            <<"no result"/utf8>>;

        {too_many_results_error, N} ->
            <<"too many results: "/utf8, (erlang:integer_to_binary(N))/binary>>;

        {constraint_error, Name} ->
            <<"constraint error: "/utf8, Name/binary>>;

        {db_error, Msg} ->
            <<"db error: "/utf8, Msg/binary>>;

        rollback_error ->
            <<"transaction rolled back"/utf8>>
    end.

-file("src/gloo/error.gleam", 69).
?DOC(
    " Map a specific constraint violation to a typed error.\n"
    " All other errors are re-wrapped via `fallback`.\n"
    "\n"
    " Example:\n"
    "   repo.query_one(repo, q)\n"
    "   |> error.map_constraint(\"users_email_idx\", EmailAlreadyTaken, DbFailed)\n"
).
-spec map_constraint(
    {ok, NKG} | {error, gloo_error()},
    binary(),
    NKJ,
    fun((gloo_error()) -> NKJ)
) -> {ok, NKG} | {error, NKJ}.
map_constraint(Result, Constraint_name, On_match, Fallback) ->
    gleam@result:map_error(Result, fun(E) -> case E of
                {constraint_error, Name} when Name =:= Constraint_name ->
                    On_match;

                _ ->
                    Fallback(E)
            end end).

-file("src/gloo/error.gleam", 102).
-spec find_mapping(list({binary(), NKT}), binary()) -> {ok, NKT} | {error, nil}.
find_mapping(Mappings, Name) ->
    case Mappings of
        [] ->
            {error, nil};

        [{K, V} | Rest] ->
            case K =:= Name of
                true ->
                    {ok, V};

                false ->
                    find_mapping(Rest, Name)
            end
    end.

-file("src/gloo/error.gleam", 85).
?DOC(
    " Match multiple constraint names to typed errors.\n"
    " Falls back for any unrecognised constraint or non-constraint error.\n"
).
-spec map_constraints(
    {ok, NKM} | {error, gloo_error()},
    list({binary(), NKP}),
    fun((gloo_error()) -> NKP)
) -> {ok, NKM} | {error, NKP}.
map_constraints(Result, Mappings, Fallback) ->
    gleam@result:map_error(Result, fun(E) -> case E of
                {constraint_error, Name} ->
                    case find_mapping(Mappings, Name) of
                        {ok, Mapped} ->
                            Mapped;

                        {error, nil} ->
                            Fallback(E)
                    end;

                _ ->
                    Fallback(E)
            end end).
