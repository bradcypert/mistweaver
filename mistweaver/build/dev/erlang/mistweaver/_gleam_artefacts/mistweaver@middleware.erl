-module(mistweaver@middleware).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/mistweaver/middleware.gleam").
-export([log/2, request_id/2, cors_allow_all/0, cors/3, static_files/2, body_limit/2]).
-export_type([cors_options/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-type cors_options() :: {cors_options,
        list(binary()),
        list(binary()),
        list(binary()),
        gleam@option:option(integer())}.

-file("src/mistweaver/middleware.gleam", 198).
-spec method_string(gleam@http:method()) -> binary().
method_string(Method) ->
    case Method of
        get ->
            <<"GET"/utf8>>;

        post ->
            <<"POST"/utf8>>;

        put ->
            <<"PUT"/utf8>>;

        patch ->
            <<"PATCH"/utf8>>;

        delete ->
            <<"DELETE"/utf8>>;

        head ->
            <<"HEAD"/utf8>>;

        options ->
            <<"OPTIONS"/utf8>>;

        trace ->
            <<"TRACE"/utf8>>;

        connect ->
            <<"CONNECT"/utf8>>;

        {other, S} ->
            string:uppercase(S)
    end.

-file("src/mistweaver/middleware.gleam", 22).
?DOC(
    " Log each request with method, path, status, and elapsed time.\n"
    " Intended for the outermost layer of the middleware stack.\n"
).
-spec log(
    gleam@http@request:request(BCK),
    fun((gleam@http@request:request(BCK)) -> gleam@http@response:response(mist:response_data()))
) -> gleam@http@response:response(mist:response_data()).
log(Req, Next) ->
    Start = birl:monotonic_now(),
    Resp = Next(Req),
    Elapsed_ms = (birl:monotonic_now() - Start) div 1000,
    logging:log(
        info,
        <<<<<<<<<<<<<<(method_string(erlang:element(2, Req)))/binary, " "/utf8>>/binary,
                                (erlang:element(8, Req))/binary>>/binary,
                            " → "/utf8>>/binary,
                        (erlang:integer_to_binary(erlang:element(2, Resp)))/binary>>/binary,
                    " ("/utf8>>/binary,
                (erlang:integer_to_binary(Elapsed_ms))/binary>>/binary,
            "ms)"/utf8>>
    ),
    Resp.

-file("src/mistweaver/middleware.gleam", 213).
-spec generate_id() -> binary().
generate_id() ->
    _pipe = crypto:strong_rand_bytes(16),
    _pipe@1 = gleam_stdlib:base16_encode(_pipe),
    string:lowercase(_pipe@1).

-file("src/mistweaver/middleware.gleam", 46).
?DOC(
    " Generate (or propagate) an `x-request-id` header on both the request\n"
    " passed downstream and the response returned upstream. Downstream handlers\n"
    " can read the ID via `request.get_header(req, \"x-request-id\")`.\n"
).
-spec request_id(
    gleam@http@request:request(BCP),
    fun((gleam@http@request:request(BCP)) -> gleam@http@response:response(mist:response_data()))
) -> gleam@http@response:response(mist:response_data()).
request_id(Req, Next) ->
    Id = case gleam@http@request:get_header(Req, <<"x-request-id"/utf8>>) of
        {ok, Existing} ->
            Existing;

        {error, _} ->
            generate_id()
    end,
    Req2 = gleam@http@request:set_header(Req, <<"x-request-id"/utf8>>, Id),
    _pipe = Next(Req2),
    gleam@http@response:set_header(_pipe, <<"x-request-id"/utf8>>, Id).

-file("src/mistweaver/middleware.gleam", 70).
?DOC(
    " Permissive CORS defaults — allow everything. Use as a starting point and\n"
    " tighten for production.\n"
).
-spec cors_allow_all() -> cors_options().
cors_allow_all() ->
    {cors_options,
        [<<"*"/utf8>>],
        [<<"GET"/utf8>>,
            <<"POST"/utf8>>,
            <<"PUT"/utf8>>,
            <<"PATCH"/utf8>>,
            <<"DELETE"/utf8>>,
            <<"OPTIONS"/utf8>>],
        [<<"content-type"/utf8>>,
            <<"authorization"/utf8>>,
            <<"x-request-id"/utf8>>],
        {some, 86400}}.

-file("src/mistweaver/middleware.gleam", 241).
-spec option_from_result({ok, BDD} | {error, any()}) -> gleam@option:option(BDD).
option_from_result(R) ->
    case R of
        {ok, V} ->
            {some, V};

        {error, _} ->
            none
    end.

-file("src/mistweaver/middleware.gleam", 81).
?DOC(
    " Add CORS headers to every response. Automatically handles `OPTIONS`\n"
    " preflight requests by returning 204 without calling `next`.\n"
).
-spec cors(
    cors_options(),
    gleam@http@request:request(BCU),
    fun((gleam@http@request:request(BCU)) -> gleam@http@response:response(mist:response_data()))
) -> gleam@http@response:response(mist:response_data()).
cors(Options, Req, Next) ->
    Origin = begin
        _pipe = gleam@http@request:get_header(Req, <<"origin"/utf8>>),
        option_from_result(_pipe)
    end,
    Allow_origin = case erlang:element(2, Options) of
        [<<"*"/utf8>>] ->
            <<"*"/utf8>>;

        Origins ->
            case Origin of
                {some, O} ->
                    case gleam@list:contains(Origins, O) of
                        true ->
                            O;

                        false ->
                            <<""/utf8>>
                    end;

                none ->
                    <<""/utf8>>
            end
    end,
    Add_cors = fun(Resp) -> _pipe@1 = Resp,
        _pipe@2 = gleam@http@response:set_header(
            _pipe@1,
            <<"access-control-allow-origin"/utf8>>,
            Allow_origin
        ),
        _pipe@3 = gleam@http@response:set_header(
            _pipe@2,
            <<"access-control-allow-methods"/utf8>>,
            gleam@string:join(erlang:element(3, Options), <<", "/utf8>>)
        ),
        _pipe@4 = gleam@http@response:set_header(
            _pipe@3,
            <<"access-control-allow-headers"/utf8>>,
            gleam@string:join(erlang:element(4, Options), <<", "/utf8>>)
        ),
        (fun(R) -> case erlang:element(5, Options) of
                {some, Age} ->
                    gleam@http@response:set_header(
                        R,
                        <<"access-control-max-age"/utf8>>,
                        erlang:integer_to_binary(Age)
                    );

                none ->
                    R
            end end)(_pipe@4) end,
    case erlang:element(2, Req) of
        options ->
            _pipe@5 = gleam@http@response:new(204),
            _pipe@6 = gleam@http@response:set_body(
                _pipe@5,
                {bytes, gleam@bytes_tree:new()}
            ),
            Add_cors(_pipe@6);

        _ ->
            _pipe@7 = Next(Req),
            Add_cors(_pipe@7)
    end.

-file("src/mistweaver/middleware.gleam", 219).
-spec guess_content_type(binary()) -> binary().
guess_content_type(Path) ->
    case begin
        _pipe = gleam@string:split(Path, <<"."/utf8>>),
        gleam@list:last(_pipe)
    end of
        {ok, <<"html"/utf8>>} ->
            <<"text/html; charset=utf-8"/utf8>>;

        {ok, <<"htm"/utf8>>} ->
            <<"text/html; charset=utf-8"/utf8>>;

        {ok, <<"css"/utf8>>} ->
            <<"text/css"/utf8>>;

        {ok, <<"js"/utf8>>} ->
            <<"application/javascript"/utf8>>;

        {ok, <<"mjs"/utf8>>} ->
            <<"application/javascript"/utf8>>;

        {ok, <<"json"/utf8>>} ->
            <<"application/json"/utf8>>;

        {ok, <<"png"/utf8>>} ->
            <<"image/png"/utf8>>;

        {ok, <<"jpg"/utf8>>} ->
            <<"image/jpeg"/utf8>>;

        {ok, <<"jpeg"/utf8>>} ->
            <<"image/jpeg"/utf8>>;

        {ok, <<"gif"/utf8>>} ->
            <<"image/gif"/utf8>>;

        {ok, <<"svg"/utf8>>} ->
            <<"image/svg+xml"/utf8>>;

        {ok, <<"ico"/utf8>>} ->
            <<"image/x-icon"/utf8>>;

        {ok, <<"woff"/utf8>>} ->
            <<"font/woff"/utf8>>;

        {ok, <<"woff2"/utf8>>} ->
            <<"font/woff2"/utf8>>;

        {ok, <<"ttf"/utf8>>} ->
            <<"font/ttf"/utf8>>;

        {ok, <<"txt"/utf8>>} ->
            <<"text/plain; charset=utf-8"/utf8>>;

        {ok, <<"xml"/utf8>>} ->
            <<"application/xml"/utf8>>;

        {ok, <<"pdf"/utf8>>} ->
            <<"application/pdf"/utf8>>;

        {ok, <<"webp"/utf8>>} ->
            <<"image/webp"/utf8>>;

        _ ->
            <<"application/octet-stream"/utf8>>
    end.

-file("src/mistweaver/middleware.gleam", 145).
?DOC(
    " Serve static files from `dir` for any request whose path starts with\n"
    " `prefix`. Strips the prefix before looking up the file on disk.\n"
    " Falls through to `next` when no matching file is found.\n"
    "\n"
    "   middleware.static_files(under: \"/static\", from: \"priv/static\")\n"
).
-spec static_files(binary(), binary()) -> fun((gleam@http@request:request(mist@internal@http:connection()), fun((gleam@http@request:request(mist@internal@http:connection())) -> gleam@http@response:response(mist:response_data()))) -> gleam@http@response:response(mist:response_data())).
static_files(Prefix, Dir) ->
    fun(Req, Next) ->
        case gleam_stdlib:string_starts_with(erlang:element(8, Req), Prefix) of
            false ->
                Next(Req);

            true ->
                Rel = gleam@string:drop_start(
                    erlang:element(8, Req),
                    string:length(Prefix)
                ),
                File_path = case gleam_stdlib:string_starts_with(
                    Rel,
                    <<"/"/utf8>>
                ) of
                    true ->
                        <<Dir/binary, Rel/binary>>;

                    false ->
                        <<<<Dir/binary, "/"/utf8>>/binary, Rel/binary>>
                end,
                case mist:send_file(File_path, 0, none) of
                    {ok, Body} ->
                        _pipe = gleam@http@response:new(200),
                        _pipe@1 = gleam@http@response:set_header(
                            _pipe,
                            <<"content-type"/utf8>>,
                            guess_content_type(File_path)
                        ),
                        gleam@http@response:set_body(_pipe@1, Body);

                    {error, _} ->
                        Next(Req)
                end
        end
    end.

-file("src/mistweaver/middleware.gleam", 177).
?DOC(
    " Enforce a maximum request body size. Reads the body eagerly up to\n"
    " `max_bytes`; if the body is too large, returns 413 immediately.\n"
    " Downstream handlers receive `Request(BitArray)` with the pre-read body.\n"
    "\n"
    " Because this changes the request body type from `Connection` to\n"
    " `BitArray`, it must be the innermost Connection-specific middleware.\n"
    " The handler it wraps must accept `Request(BitArray)`.\n"
).
-spec body_limit(
    integer(),
    fun((gleam@http@request:request(bitstring())) -> gleam@http@response:response(mist:response_data()))
) -> fun((gleam@http@request:request(mist@internal@http:connection()), fun((gleam@http@request:request(mist@internal@http:connection())) -> gleam@http@response:response(mist:response_data()))) -> gleam@http@response:response(mist:response_data())).
body_limit(Max_bytes, Handler) ->
    fun(Req, _) -> case mist:read_body(Req, Max_bytes) of
            {ok, Req_with_body} ->
                Handler(Req_with_body);

            {error, excess_body} ->
                _pipe = gleam@http@response:new(413),
                gleam@http@response:set_body(
                    _pipe,
                    {bytes, gleam@bytes_tree:new()}
                );

            {error, malformed_body} ->
                _pipe@1 = gleam@http@response:new(400),
                gleam@http@response:set_body(
                    _pipe@1,
                    {bytes, gleam@bytes_tree:new()}
                )
        end end.
