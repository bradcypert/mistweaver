-module(mistweaver@flash).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/mistweaver/flash.gleam").
-export([put/4, consume/2]).
-export_type([flash/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-type flash() :: {flash, binary(), binary()}.

-file("src/mistweaver/flash.gleam", 19).
?DOC(
    " Store a flash message on the response. Stacks correctly alongside a session\n"
    " cookie because it prepends the Set-Cookie header rather than replacing it.\n"
).
-spec put(
    gleam@http@response:response(mist:response_data()),
    binary(),
    binary(),
    binary()
) -> gleam@http@response:response(mist:response_data()).
put(Resp, Secret, Kind, Message) ->
    Payload = <<<<Kind/binary, "|"/utf8>>/binary, Message/binary>>,
    Signed = gleam@crypto:sign_message(
        <<Payload/binary>>,
        <<Secret/binary>>,
        sha256
    ),
    Cookie = <<<<<<"_mw_flash"/utf8, "="/utf8>>/binary, Signed/binary>>/binary,
        "; Path=/; HttpOnly; SameSite=Lax"/utf8>>,
    {response,
        erlang:element(2, Resp),
        [{<<"set-cookie"/utf8>>, Cookie} | erlang:element(3, Resp)],
        erlang:element(4, Resp)}.

-file("src/mistweaver/flash.gleam", 37).
?DOC(
    " Read the flash from the request and return a function that clears it.\n"
    " Pattern:\n"
    "   let #(flash_opt, clear) = flash.consume(req, secret)\n"
    "   mw_response.html(200, render(flash_opt)) |> clear\n"
).
-spec consume(gleam@http@request:request(any()), binary()) -> {gleam@option:option(flash()),
    fun((gleam@http@response:response(mist:response_data())) -> gleam@http@response:response(mist:response_data()))}.
consume(Req, Secret) ->
    Flash_opt = case mistweaver@request:get_cookie(Req, <<"_mw_flash"/utf8>>) of
        none ->
            none;

        {some, Signed} ->
            case gleam@crypto:verify_signed_message(Signed, <<Secret/binary>>) of
                {error, _} ->
                    none;

                {ok, Payload} ->
                    case gleam@bit_array:to_string(Payload) of
                        {error, _} ->
                            none;

                        {ok, S} ->
                            case gleam@string:split_once(S, <<"|"/utf8>>) of
                                {ok, {Kind, Message}} ->
                                    {some, {flash, Kind, Message}};

                                {error, _} ->
                                    none
                            end
                    end
            end
    end,
    Clear = fun(Resp) ->
        Cookie = <<"_mw_flash"/utf8,
            "=; Path=/; HttpOnly; Max-Age=0; SameSite=Lax"/utf8>>,
        {response,
            erlang:element(2, Resp),
            [{<<"set-cookie"/utf8>>, Cookie} | erlang:element(3, Resp)],
            erlang:element(4, Resp)}
    end,
    {Flash_opt, Clear}.
