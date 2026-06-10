-module(mistweaver@session).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/mistweaver/session.gleam").
-export([get/2, put/3, delete/1, empty/0, set/3, fetch/2, delete_key/2]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-file("src/mistweaver/session.gleam", 80).
-spec decode_session(binary()) -> gleam@dict:dict(binary(), binary()).
decode_session(Encoded) ->
    case Encoded of
        <<""/utf8>> ->
            maps:new();

        _ ->
            _pipe = Encoded,
            _pipe@1 = gleam@string:split(_pipe, <<"&"/utf8>>),
            _pipe@2 = gleam@list:filter_map(
                _pipe@1,
                fun(Pair) -> case gleam@string:split_once(Pair, <<"="/utf8>>) of
                        {ok, Kv} ->
                            {ok, Kv};

                        {error, _} ->
                            {error, nil}
                    end end
            ),
            maps:from_list(_pipe@2)
    end.

-file("src/mistweaver/session.gleam", 21).
?DOC(
    " Read and verify the session from the incoming request cookie.\n"
    " Returns an empty session if the cookie is absent or tampered with.\n"
).
-spec get(gleam@http@request:request(any()), binary()) -> gleam@dict:dict(binary(), binary()).
get(Req, Secret) ->
    case mistweaver@request:get_cookie(Req, <<"_mw_session"/utf8>>) of
        none ->
            maps:new();

        {some, Value} ->
            case gleam@crypto:verify_signed_message(Value, <<Secret/binary>>) of
                {ok, Payload} ->
                    case gleam@bit_array:to_string(Payload) of
                        {ok, S} ->
                            decode_session(S);

                        {error, _} ->
                            maps:new()
                    end;

                {error, _} ->
                    maps:new()
            end
    end.

-file("src/mistweaver/session.gleam", 73).
-spec encode_session(gleam@dict:dict(binary(), binary())) -> binary().
encode_session(Session) ->
    _pipe = Session,
    _pipe@1 = maps:to_list(_pipe),
    _pipe@2 = gleam@list:map(
        _pipe@1,
        fun(Pair) ->
            <<<<(erlang:element(1, Pair))/binary, "="/utf8>>/binary,
                (erlang:element(2, Pair))/binary>>
        end
    ),
    gleam@string:join(_pipe@2, <<"&"/utf8>>).

-file("src/mistweaver/session.gleam", 38).
?DOC(
    " Sign the session and attach it as an HttpOnly cookie on the response.\n"
    " Uses header prepending so multiple Set-Cookie headers stack correctly.\n"
).
-spec put(
    gleam@http@response:response(mist:response_data()),
    gleam@dict:dict(binary(), binary()),
    binary()
) -> gleam@http@response:response(mist:response_data()).
put(Resp, Session, Secret) ->
    Payload = encode_session(Session),
    Signed = gleam@crypto:sign_message(
        <<Payload/binary>>,
        <<Secret/binary>>,
        sha256
    ),
    Cookie = <<<<<<"_mw_session"/utf8, "="/utf8>>/binary, Signed/binary>>/binary,
        "; Path=/; HttpOnly; SameSite=Lax"/utf8>>,
    {response,
        erlang:element(2, Resp),
        [{<<"set-cookie"/utf8>>, Cookie} | erlang:element(3, Resp)],
        erlang:element(4, Resp)}.

-file("src/mistweaver/session.gleam", 52).
?DOC(" Clear the session cookie.\n").
-spec delete(gleam@http@response:response(mist:response_data())) -> gleam@http@response:response(mist:response_data()).
delete(Resp) ->
    Cookie = <<"_mw_session"/utf8,
        "=; Path=/; HttpOnly; Max-Age=0; SameSite=Lax"/utf8>>,
    {response,
        erlang:element(2, Resp),
        [{<<"set-cookie"/utf8>>, Cookie} | erlang:element(3, Resp)],
        erlang:element(4, Resp)}.

-file("src/mistweaver/session.gleam", 57).
-spec empty() -> gleam@dict:dict(binary(), binary()).
empty() ->
    maps:new().

-file("src/mistweaver/session.gleam", 61).
-spec set(gleam@dict:dict(binary(), binary()), binary(), binary()) -> gleam@dict:dict(binary(), binary()).
set(Session, Key, Value) ->
    gleam@dict:insert(Session, Key, Value).

-file("src/mistweaver/session.gleam", 65).
-spec fetch(gleam@dict:dict(binary(), binary()), binary()) -> gleam@option:option(binary()).
fetch(Session, Key) ->
    _pipe = gleam_stdlib:map_get(Session, Key),
    gleam@option:from_result(_pipe).

-file("src/mistweaver/session.gleam", 69).
-spec delete_key(gleam@dict:dict(binary(), binary()), binary()) -> gleam@dict:dict(binary(), binary()).
delete_key(Session, Key) ->
    gleam@dict:delete(Session, Key).
