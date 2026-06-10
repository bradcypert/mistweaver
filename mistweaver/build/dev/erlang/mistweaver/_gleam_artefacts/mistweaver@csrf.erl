-module(mistweaver@csrf).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/mistweaver/csrf.gleam").
-export([token_for/1, hidden_input/1, validate/2]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-file("src/mistweaver/csrf.gleam", 16).
?DOC(
    " Return the current CSRF token for this session, generating one if absent.\n"
    " Returns the token and the (possibly updated) session — call `session.put`\n"
    " on your response if the session changed.\n"
).
-spec token_for(gleam@dict:dict(binary(), binary())) -> {binary(),
    gleam@dict:dict(binary(), binary())}.
token_for(Sess) ->
    case mistweaver@session:fetch(Sess, <<"_csrf"/utf8>>) of
        {some, T} ->
            {T, Sess};

        none ->
            T@1 = begin
                _pipe = crypto:strong_rand_bytes(16),
                _pipe@1 = gleam_stdlib:base16_encode(_pipe),
                string:lowercase(_pipe@1)
            end,
            {T@1, mistweaver@session:set(Sess, <<"_csrf"/utf8>>, T@1)}
    end.

-file("src/mistweaver/csrf.gleam", 31).
?DOC(
    " A `<input type=\"hidden\" name=\"_csrf_token\" value=\"...\">` element for use\n"
    " inside HTML forms.\n"
).
-spec hidden_input(binary()) -> lustre@vdom@vnode:element(any()).
hidden_input(Token) ->
    lustre@element@html:input(
        [lustre@attribute:type_(<<"hidden"/utf8>>),
            lustre@attribute:name(<<"_csrf_token"/utf8>>),
            lustre@attribute:value(Token)]
    ).

-file("src/mistweaver/csrf.gleam", 60).
-spec option_from_result({ok, CME} | {error, any()}) -> gleam@option:option(CME).
option_from_result(R) ->
    case R of
        {ok, V} ->
            {some, V};

        {error, _} ->
            none
    end.

-file("src/mistweaver/csrf.gleam", 53).
-spec find_param(list({binary(), binary()}), binary()) -> gleam@option:option(binary()).
find_param(Params, Key) ->
    _pipe = Params,
    _pipe@1 = gleam@list:find(_pipe, fun(P) -> erlang:element(1, P) =:= Key end),
    _pipe@2 = option_from_result(_pipe@1),
    gleam@option:map(_pipe@2, fun(P@1) -> erlang:element(2, P@1) end).

-file("src/mistweaver/csrf.gleam", 40).
?DOC(" Validate the CSRF token submitted in a form against the session.\n").
-spec validate(list({binary(), binary()}), gleam@dict:dict(binary(), binary())) -> boolean().
validate(Form_params, Sess) ->
    Submitted = find_param(Form_params, <<"_csrf_token"/utf8>>),
    Expected = mistweaver@session:fetch(Sess, <<"_csrf"/utf8>>),
    case {Submitted, Expected} of
        {{some, T1}, {some, T2}} ->
            gleam@crypto:secure_compare(<<T1/binary>>, <<T2/binary>>);

        {_, _} ->
            false
    end.
