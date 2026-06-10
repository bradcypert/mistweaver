-module(mistweaver@router).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/mistweaver/router.gleam").
-export([new/0, get/3, post/3, put/3, patch/3, delete/3, head/3, options/3, scope/4, dispatch/2, to_handler/1]).
-export_type([path_segment/0, route/1, router/1]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-opaque path_segment() :: {static, binary()} | {param, binary()} | wildcard.

-opaque route(BBG) :: {route,
        gleam@http:method(),
        list(path_segment()),
        list(fun((gleam@http@request:request(BBG), fun((gleam@http@request:request(BBG)) -> gleam@http@response:response(mist:response_data()))) -> gleam@http@response:response(mist:response_data()))),
        fun((gleam@http@request:request(BBG), list({binary(), binary()})) -> gleam@http@response:response(mist:response_data()))}.

-opaque router(BBH) :: {router,
        list(route(BBH)),
        list(path_segment()),
        list(fun((gleam@http@request:request(BBH), fun((gleam@http@request:request(BBH)) -> gleam@http@response:response(mist:response_data()))) -> gleam@http@response:response(mist:response_data())))}.

-file("src/mistweaver/router.gleam", 54).
-spec new() -> router(any()).
new() ->
    {router, [], [], []}.

-file("src/mistweaver/router.gleam", 182).
-spec parse_path(binary()) -> list(path_segment()).
parse_path(Path) ->
    _pipe = Path,
    _pipe@1 = gleam@string:split(_pipe, <<"/"/utf8>>),
    _pipe@2 = gleam@list:filter(_pipe@1, fun(S) -> S /= <<""/utf8>> end),
    gleam@list:map(
        _pipe@2,
        fun(Segment) ->
            case gleam_stdlib:string_starts_with(Segment, <<":"/utf8>>) of
                true ->
                    {param, gleam@string:drop_start(Segment, 1)};

                false ->
                    case Segment of
                        <<"*"/utf8>> ->
                            wildcard;

                        S@1 ->
                            {static, S@1}
                    end
            end
        end
    ).

-file("src/mistweaver/router.gleam", 166).
-spec add_route(
    router(BDJ),
    gleam@http:method(),
    binary(),
    fun((gleam@http@request:request(BDJ), list({binary(), binary()})) -> gleam@http@response:response(mist:response_data()))
) -> router(BDJ).
add_route(Router, Method, Path, Handler) ->
    Route = {route,
        Method,
        lists:append(erlang:element(3, Router), parse_path(Path)),
        erlang:element(4, Router),
        Handler},
    {router,
        lists:append(erlang:element(2, Router), [Route]),
        erlang:element(3, Router),
        erlang:element(4, Router)}.

-file("src/mistweaver/router.gleam", 58).
-spec get(
    router(BBT),
    binary(),
    fun((gleam@http@request:request(BBT), list({binary(), binary()})) -> gleam@http@response:response(mist:response_data()))
) -> router(BBT).
get(Router, Path, Handler) ->
    add_route(Router, get, Path, Handler).

-file("src/mistweaver/router.gleam", 66).
-spec post(
    router(BBX),
    binary(),
    fun((gleam@http@request:request(BBX), list({binary(), binary()})) -> gleam@http@response:response(mist:response_data()))
) -> router(BBX).
post(Router, Path, Handler) ->
    add_route(Router, post, Path, Handler).

-file("src/mistweaver/router.gleam", 74).
-spec put(
    router(BCB),
    binary(),
    fun((gleam@http@request:request(BCB), list({binary(), binary()})) -> gleam@http@response:response(mist:response_data()))
) -> router(BCB).
put(Router, Path, Handler) ->
    add_route(Router, put, Path, Handler).

-file("src/mistweaver/router.gleam", 82).
-spec patch(
    router(BCF),
    binary(),
    fun((gleam@http@request:request(BCF), list({binary(), binary()})) -> gleam@http@response:response(mist:response_data()))
) -> router(BCF).
patch(Router, Path, Handler) ->
    add_route(Router, patch, Path, Handler).

-file("src/mistweaver/router.gleam", 90).
-spec delete(
    router(BCJ),
    binary(),
    fun((gleam@http@request:request(BCJ), list({binary(), binary()})) -> gleam@http@response:response(mist:response_data()))
) -> router(BCJ).
delete(Router, Path, Handler) ->
    add_route(Router, delete, Path, Handler).

-file("src/mistweaver/router.gleam", 98).
-spec head(
    router(BCN),
    binary(),
    fun((gleam@http@request:request(BCN), list({binary(), binary()})) -> gleam@http@response:response(mist:response_data()))
) -> router(BCN).
head(Router, Path, Handler) ->
    add_route(Router, head, Path, Handler).

-file("src/mistweaver/router.gleam", 106).
-spec options(
    router(BCR),
    binary(),
    fun((gleam@http@request:request(BCR), list({binary(), binary()})) -> gleam@http@response:response(mist:response_data()))
) -> router(BCR).
options(Router, Path, Handler) ->
    add_route(Router, options, Path, Handler).

-file("src/mistweaver/router.gleam", 123).
?DOC(
    " Group routes under a shared path prefix and middleware stack. Scopes nest:\n"
    " middleware from an outer scope runs before the inner scope's middleware.\n"
    "\n"
    "   router.new()\n"
    "   |> router.scope(\"/api\", [auth_middleware], fn(r) {\n"
    "     r\n"
    "     |> router.get(\"/users\", users.index)\n"
    "     |> router.get(\"/users/:id\", users.show)\n"
    "   })\n"
).
-spec scope(
    router(BCV),
    binary(),
    list(fun((gleam@http@request:request(BCV), fun((gleam@http@request:request(BCV)) -> gleam@http@response:response(mist:response_data()))) -> gleam@http@response:response(mist:response_data()))),
    fun((router(BCV)) -> router(BCV))
) -> router(BCV).
scope(Router, Prefix, Middlewares, Build) ->
    Prefix_segments = parse_path(Prefix),
    Scoped = {router,
        [],
        lists:append(erlang:element(3, Router), Prefix_segments),
        lists:append(erlang:element(4, Router), Middlewares)},
    Built = Build(Scoped),
    {router,
        lists:append(erlang:element(2, Router), erlang:element(2, Built)),
        erlang:element(3, Router),
        erlang:element(4, Router)}.

-file("src/mistweaver/router.gleam", 255).
-spec not_found() -> gleam@http@response:response(mist:response_data()).
not_found() ->
    _pipe = gleam@http@response:new(404),
    gleam@http@response:set_body(_pipe, {bytes, gleam@bytes_tree:new()}).

-file("src/mistweaver/router.gleam", 243).
-spec apply_middlewares(
    list(fun((gleam@http@request:request(BEC), fun((gleam@http@request:request(BEC)) -> gleam@http@response:response(mist:response_data()))) -> gleam@http@response:response(mist:response_data()))),
    gleam@http@request:request(BEC),
    fun((gleam@http@request:request(BEC)) -> gleam@http@response:response(mist:response_data()))
) -> gleam@http@response:response(mist:response_data()).
apply_middlewares(Middlewares, Req, Final) ->
    case Middlewares of
        [] ->
            Final(Req);

        [Middleware | Rest] ->
            Middleware(
                Req,
                fun(Req2) -> apply_middlewares(Rest, Req2, Final) end
            )
    end.

-file("src/mistweaver/router.gleam", 223).
-spec match_segments(
    list(path_segment()),
    list(binary()),
    list({binary(), binary()})
) -> {ok, list({binary(), binary()})} | {error, nil}.
match_segments(Route, Request, Acc) ->
    case {Route, Request} of
        {[], []} ->
            {ok, lists:reverse(Acc)};

        {[wildcard | _], _} ->
            {ok, lists:reverse(Acc)};

        {[], _} ->
            {error, nil};

        {_, []} ->
            {error, nil};

        {[{static, Expected} | Route_rest], [Actual | Req_rest]} ->
            case Expected =:= Actual of
                true ->
                    match_segments(Route_rest, Req_rest, Acc);

                false ->
                    {error, nil}
            end;

        {[{param, Name} | Route_rest@1], [Value | Req_rest@1]} ->
            match_segments(Route_rest@1, Req_rest@1, [{Name, Value} | Acc])
    end.

-file("src/mistweaver/router.gleam", 204).
-spec match_route(list(route(BDR)), gleam@http:method(), list(binary())) -> {ok,
        {route(BDR), list({binary(), binary()})}} |
    {error, nil}.
match_route(Routes, Method, Path_segments) ->
    case Routes of
        [] ->
            {error, nil};

        [Route | Rest] ->
            case erlang:element(2, Route) =:= Method of
                false ->
                    match_route(Rest, Method, Path_segments);

                true ->
                    case match_segments(
                        erlang:element(3, Route),
                        Path_segments,
                        []
                    ) of
                        {ok, Params} ->
                            {ok, {Route, Params}};

                        {error, nil} ->
                            match_route(Rest, Method, Path_segments)
                    end
            end
    end.

-file("src/mistweaver/router.gleam", 198).
-spec parse_request_path(gleam@http@request:request(any())) -> list(binary()).
parse_request_path(Req) ->
    _pipe = erlang:element(8, Req),
    _pipe@1 = gleam@string:split(_pipe, <<"/"/utf8>>),
    gleam@list:filter(_pipe@1, fun(S) -> S /= <<""/utf8>> end).

-file("src/mistweaver/router.gleam", 144).
?DOC(
    " Dispatch an incoming request through the router. Returns 404 if no route\n"
    " matches. A `Router(Connection)` is a valid Mist handler via partial apply:\n"
    "\n"
    "   mist.new(router.dispatch(my_router, _))\n"
).
-spec dispatch(router(BDC), gleam@http@request:request(BDC)) -> gleam@http@response:response(mist:response_data()).
dispatch(Router, Req) ->
    Path_segments = parse_request_path(Req),
    case match_route(
        erlang:element(2, Router),
        erlang:element(2, Req),
        Path_segments
    ) of
        {ok, {Route, Params}} ->
            apply_middlewares(
                erlang:element(4, Route),
                Req,
                fun(Req2) -> (erlang:element(5, Route))(Req2, Params) end
            );

        {error, nil} ->
            not_found()
    end.

-file("src/mistweaver/router.gleam", 160).
?DOC(
    " Convenience alias for starting a Mist server directly from a router.\n"
    " Equivalent to `mist.new(router.dispatch(r, _))`.\n"
).
-spec to_handler(router(mist@internal@http:connection())) -> fun((gleam@http@request:request(mist@internal@http:connection())) -> gleam@http@response:response(mist:response_data())).
to_handler(R) ->
    fun(_capture) -> dispatch(R, _capture) end.
