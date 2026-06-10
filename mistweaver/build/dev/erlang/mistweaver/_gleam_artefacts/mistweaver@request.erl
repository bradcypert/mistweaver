-module(mistweaver@request).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/mistweaver/request.gleam").
-export([path_param/2, query_param/2, query_params/1, get_header/2, path_segments/1, uri/1, path/1, require_path_param/2, require_query_param/2, get_cookie/2, form_params/1, form_param/2]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-file("src/mistweaver/request.gleam", 10).
?DOC(" Look up a path parameter by name from the params list captured during routing.\n").
-spec path_param(list({binary(), binary()}), binary()) -> gleam@option:option(binary()).
path_param(Params, Key) ->
    _pipe = Params,
    _pipe@1 = gleam@list:find(
        _pipe,
        fun(Pair) -> erlang:element(1, Pair) =:= Key end
    ),
    _pipe@2 = gleam@result:map(
        _pipe@1,
        fun(Pair@1) -> erlang:element(2, Pair@1) end
    ),
    gleam@option:from_result(_pipe@2).

-file("src/mistweaver/request.gleam", 18).
?DOC(" Look up a query string parameter by name.\n").
-spec query_param(gleam@http@request:request(any()), binary()) -> gleam@option:option(binary()).
query_param(Req, Key) ->
    _pipe = Req,
    _pipe@1 = gleam@http@request:get_query(_pipe),
    _pipe@2 = gleam@result:unwrap(_pipe@1, []),
    _pipe@3 = gleam@list:find(
        _pipe@2,
        fun(Pair) -> erlang:element(1, Pair) =:= Key end
    ),
    _pipe@4 = gleam@result:map(
        _pipe@3,
        fun(Pair@1) -> erlang:element(2, Pair@1) end
    ),
    gleam@option:from_result(_pipe@4).

-file("src/mistweaver/request.gleam", 28).
?DOC(" Get all query string parameters as a list of key/value pairs.\n").
-spec query_params(gleam@http@request:request(any())) -> list({binary(),
    binary()}).
query_params(Req) ->
    _pipe = Req,
    _pipe@1 = gleam@http@request:get_query(_pipe),
    gleam@result:unwrap(_pipe@1, []).

-file("src/mistweaver/request.gleam", 35).
?DOC(" Get a request header value by name (case-insensitive per HTTP spec).\n").
-spec get_header(gleam@http@request:request(any()), binary()) -> gleam@option:option(binary()).
get_header(Req, Key) ->
    _pipe = gleam@http@request:get_header(Req, Key),
    gleam@option:from_result(_pipe).

-file("src/mistweaver/request.gleam", 41).
?DOC(" Return the request path as a list of non-empty segments.\n").
-spec path_segments(gleam@http@request:request(any())) -> list(binary()).
path_segments(Req) ->
    _pipe = erlang:element(8, Req),
    _pipe@1 = gleam@string:split(_pipe, <<"/"/utf8>>),
    gleam@list:filter(_pipe@1, fun(S) -> S /= <<""/utf8>> end).

-file("src/mistweaver/request.gleam", 48).
?DOC(" Return the full request URI as a string.\n").
-spec uri(gleam@http@request:request(any())) -> binary().
uri(Req) ->
    gleam@uri:to_string(gleam@http@request:to_uri(Req)).

-file("src/mistweaver/request.gleam", 53).
?DOC(" Return the raw path string.\n").
-spec path(gleam@http@request:request(any())) -> binary().
path(Req) ->
    erlang:element(8, Req).

-file("src/mistweaver/request.gleam", 59).
?DOC(
    " Require a path param; returns Error if missing. Useful in handlers where\n"
    " routing has already guaranteed the param exists.\n"
).
-spec require_path_param(list({binary(), binary()}), binary()) -> {ok, binary()} |
    {error, binary()}.
require_path_param(Params, Key) ->
    _pipe = path_param(Params, Key),
    gleam@option:to_result(
        _pipe,
        <<"missing required path param: "/utf8, Key/binary>>
    ).

-file("src/mistweaver/request.gleam", 68).
?DOC(" Require a non-empty query param; returns Error if absent or empty.\n").
-spec require_query_param(gleam@http@request:request(any()), binary()) -> {ok,
        binary()} |
    {error, binary()}.
require_query_param(Req, Key) ->
    _pipe = query_param(Req, Key),
    _pipe@1 = gleam@option:map(_pipe, fun(V) -> case gleam@string:is_empty(V) of
                true ->
                    {error,
                        <<<<"query param '"/utf8, Key/binary>>/binary,
                            "' is empty"/utf8>>};

                false ->
                    {ok, V}
            end end),
    gleam@option:unwrap(
        _pipe@1,
        {error, <<"missing required query param: "/utf8, Key/binary>>}
    ).

-file("src/mistweaver/request.gleam", 133).
-spec parse_cookies(binary()) -> list({binary(), binary()}).
parse_cookies(Header) ->
    _pipe = Header,
    _pipe@1 = gleam@string:split(_pipe, <<";"/utf8>>),
    gleam@list:filter_map(
        _pipe@1,
        fun(Pair) ->
            case gleam@string:split_once(gleam@string:trim(Pair), <<"="/utf8>>) of
                {ok, {K, V}} ->
                    {ok, {gleam@string:trim(K), gleam@string:trim(V)}};

                {error, _} ->
                    {error, nil}
            end
        end
    ).

-file("src/mistweaver/request.gleam", 83).
?DOC(" Return the value of a cookie by name. Parses the Cookie header lazily.\n").
-spec get_cookie(gleam@http@request:request(any()), binary()) -> gleam@option:option(binary()).
get_cookie(Req, Name) ->
    _pipe = Req,
    _pipe@1 = gleam@http@request:get_header(_pipe, <<"cookie"/utf8>>),
    _pipe@2 = gleam@result:map(_pipe@1, fun parse_cookies/1),
    _pipe@3 = gleam@result:unwrap(_pipe@2, []),
    _pipe@4 = gleam@list:find(
        _pipe@3,
        fun(Pair) -> erlang:element(1, Pair) =:= Name end
    ),
    _pipe@5 = gleam@result:map(
        _pipe@4,
        fun(Pair@1) -> erlang:element(2, Pair@1) end
    ),
    gleam@option:from_result(_pipe@5).

-file("src/mistweaver/request.gleam", 114).
-spec parse_form_body(binary()) -> list({binary(), binary()}).
parse_form_body(Body) ->
    case Body of
        <<""/utf8>> ->
            [];

        _ ->
            _pipe = Body,
            _pipe@1 = gleam@string:split(_pipe, <<"&"/utf8>>),
            gleam@list:filter_map(
                _pipe@1,
                fun(Pair) -> case gleam@string:split_once(Pair, <<"="/utf8>>) of
                        {ok, {K, V}} ->
                            Dk = begin
                                _pipe@2 = gleam_stdlib:percent_decode(K),
                                gleam@result:unwrap(_pipe@2, K)
                            end,
                            Dv = begin
                                _pipe@3 = gleam_stdlib:percent_decode(V),
                                gleam@result:unwrap(_pipe@3, V)
                            end,
                            {ok, {Dk, Dv}};

                        {error, _} ->
                            {error, nil}
                    end end
            )
    end.

-file("src/mistweaver/request.gleam", 96).
?DOC(
    " Parse URL-encoded form data from a request with a pre-read body.\n"
    " Use after `middleware.body_limit` which converts `Request(Connection)`\n"
    " to `Request(BitArray)`.\n"
).
-spec form_params(gleam@http@request:request(bitstring())) -> list({binary(),
    binary()}).
form_params(Req) ->
    case gleam@bit_array:to_string(erlang:element(4, Req)) of
        {ok, Body} ->
            parse_form_body(Body);

        {error, _} ->
            []
    end.

-file("src/mistweaver/request.gleam", 104).
?DOC(" Look up a single form field by name from a pre-parsed form params list.\n").
-spec form_param(list({binary(), binary()}), binary()) -> gleam@option:option(binary()).
form_param(Params, Key) ->
    _pipe = Params,
    _pipe@1 = gleam@list:find(
        _pipe,
        fun(Pair) -> erlang:element(1, Pair) =:= Key end
    ),
    _pipe@2 = gleam@result:map(
        _pipe@1,
        fun(Pair@1) -> erlang:element(2, Pair@1) end
    ),
    gleam@option:from_result(_pipe@2).
