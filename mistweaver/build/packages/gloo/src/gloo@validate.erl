-module(gloo@validate).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/gloo/validate.gleam").
-export([struct/1, field/3, required/2, max_length/1, length/1, format/1, gte/1, lte/1]).
-export_type([error/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    "  Input validation combinators.  `validate.struct` collects ALL field errors\n"
    "  before returning — it never short-circuits.\n"
    "\n"
    "  ```gleam\n"
    "  validate.struct([\n"
    "    validate.field(\"email\", email, [validate.format(\"^[^@]+@[^@]+$\")]),\n"
    "    validate.field(\"name\",  name,  [validate.max_length(100)]),\n"
    "  ])\n"
    "  // -> Result(List(value), List(validate.Error))\n"
    "  ```\n"
).

-type error() :: {field_error, binary(), binary()}.

-file("src/gloo/validate.gleam", 26).
?DOC(
    " Returns Ok(values) when every field passes, Error(all_errors) otherwise.\n"
    " Processes every field even after a failure — never short-circuits.\n"
).
-spec struct(list({ok, KWK} | {error, list(error())})) -> {ok, list(KWK)} |
    {error, list(error())}.
struct(Fields) ->
    Errors = gleam@list:flat_map(Fields, fun(R) -> case R of
                {ok, _} ->
                    [];

                {error, Errs} ->
                    Errs
            end end),
    case Errors of
        [] ->
            {ok, gleam@list:filter_map(Fields, fun(R@1) -> case R@1 of
                            {ok, V} ->
                                {ok, V};

                            {error, _} ->
                                {error, nil}
                        end end)};

        _ ->
            {error, Errors}
    end.

-file("src/gloo/validate.gleam", 52).
?DOC(
    " Validate a single field against a list of rules.\n"
    " Runs every rule regardless of prior failures.\n"
).
-spec field(binary(), KWT, list(fun((KWT) -> {ok, nil} | {error, binary()}))) -> {ok,
        KWT} |
    {error, list(error())}.
field(Name, Value, Rules) ->
    Errs = gleam@list:filter_map(Rules, fun(Rule) -> case Rule(Value) of
                {ok, _} ->
                    {error, nil};

                {error, Msg} ->
                    {ok, {field_error, Name, Msg}}
            end end),
    case Errs of
        [] ->
            {ok, Value};

        _ ->
            {error, Errs}
    end.

-file("src/gloo/validate.gleam", 72).
-spec required(binary(), gleam@option:option(KXA)) -> {ok, KXA} |
    {error, list(error())}.
required(Field_name, Value) ->
    case Value of
        {some, V} ->
            {ok, V};

        none ->
            {error, [{field_error, Field_name, <<"is required"/utf8>>}]}
    end.

-file("src/gloo/validate.gleam", 82).
-spec max_length(integer()) -> fun((binary()) -> {ok, nil} | {error, binary()}).
max_length(N) ->
    fun(S) -> case string:length(S) =< N of
            true ->
                {ok, nil};

            false ->
                {error,
                    <<<<"must be at most "/utf8,
                            (erlang:integer_to_binary(N))/binary>>/binary,
                        " characters long"/utf8>>}
        end end.

-file("src/gloo/validate.gleam", 92).
-spec length(integer()) -> fun((binary()) -> {ok, nil} | {error, binary()}).
length(N) ->
    fun(S) -> case string:length(S) =:= N of
            true ->
                {ok, nil};

            false ->
                {error,
                    <<<<"must be exactly "/utf8,
                            (erlang:integer_to_binary(N))/binary>>/binary,
                        " characters long"/utf8>>}
        end end.

-file("src/gloo/validate.gleam", 102).
-spec format(binary()) -> fun((binary()) -> {ok, nil} | {error, binary()}).
format(Pattern) ->
    fun(S) -> case gleam@regexp:from_string(Pattern) of
            {error, _} ->
                {error, <<"invalid format pattern"/utf8>>};

            {ok, Re} ->
                case gleam@regexp:check(Re, S) of
                    true ->
                        {ok, nil};

                    false ->
                        {error, <<"has invalid format"/utf8>>}
                end
        end end.

-file("src/gloo/validate.gleam", 117).
-spec gte(integer()) -> fun((integer()) -> {ok, nil} | {error, binary()}).
gte(Minimum) ->
    fun(V) -> case V >= Minimum of
            true ->
                {ok, nil};

            false ->
                {error,
                    <<"must be >= "/utf8,
                        (erlang:integer_to_binary(Minimum))/binary>>}
        end end.

-file("src/gloo/validate.gleam", 126).
-spec lte(integer()) -> fun((integer()) -> {ok, nil} | {error, binary()}).
lte(Maximum) ->
    fun(V) -> case V =< Maximum of
            true ->
                {ok, nil};

            false ->
                {error,
                    <<"must be <= "/utf8,
                        (erlang:integer_to_binary(Maximum))/binary>>}
        end end.
