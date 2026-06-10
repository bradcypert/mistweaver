-module(mistweaver@response).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/mistweaver/response.gleam").
-export([ok/0, html/2, json/2, text/2, bytes/3, redirect/2, not_found/0, bad_request/1, internal_server_error/1, created/1, no_content/0, put_header/3]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-file("src/mistweaver/response.gleam", 8).
?DOC(" Plain 200 OK with no body.\n").
-spec ok() -> gleam@http@response:response(mist:response_data()).
ok() ->
    _pipe = gleam@http@response:new(200),
    gleam@http@response:set_body(_pipe, {bytes, gleam@bytes_tree:new()}).

-file("src/mistweaver/response.gleam", 14).
?DOC(" Respond with a UTF-8 HTML body.\n").
-spec html(integer(), binary()) -> gleam@http@response:response(mist:response_data()).
html(Status, Body) ->
    _pipe = gleam@http@response:new(Status),
    _pipe@1 = gleam@http@response:set_header(
        _pipe,
        <<"content-type"/utf8>>,
        <<"text/html; charset=utf-8"/utf8>>
    ),
    gleam@http@response:set_body(
        _pipe@1,
        begin
            _pipe@2 = Body,
            _pipe@3 = gleam_stdlib:identity(_pipe@2),
            _pipe@4 = gleam_stdlib:wrap_list(_pipe@3),
            {bytes, _pipe@4}
        end
    ).

-file("src/mistweaver/response.gleam", 26).
?DOC(" Respond with a JSON body. Accepts a `gleam/json.Json` value.\n").
-spec json(integer(), gleam@json:json()) -> gleam@http@response:response(mist:response_data()).
json(Status, Value) ->
    Body = gleam@json:to_string(Value),
    _pipe = gleam@http@response:new(Status),
    _pipe@1 = gleam@http@response:set_header(
        _pipe,
        <<"content-type"/utf8>>,
        <<"application/json"/utf8>>
    ),
    gleam@http@response:set_body(
        _pipe@1,
        begin
            _pipe@2 = Body,
            _pipe@3 = gleam_stdlib:identity(_pipe@2),
            _pipe@4 = gleam_stdlib:wrap_list(_pipe@3),
            {bytes, _pipe@4}
        end
    ).

-file("src/mistweaver/response.gleam", 39).
?DOC(" Respond with a plain text body.\n").
-spec text(integer(), binary()) -> gleam@http@response:response(mist:response_data()).
text(Status, Body) ->
    _pipe = gleam@http@response:new(Status),
    _pipe@1 = gleam@http@response:set_header(
        _pipe,
        <<"content-type"/utf8>>,
        <<"text/plain; charset=utf-8"/utf8>>
    ),
    gleam@http@response:set_body(
        _pipe@1,
        begin
            _pipe@2 = Body,
            _pipe@3 = gleam_stdlib:identity(_pipe@2),
            _pipe@4 = gleam_stdlib:wrap_list(_pipe@3),
            {bytes, _pipe@4}
        end
    ).

-file("src/mistweaver/response.gleam", 51).
?DOC(" Respond with raw bytes and a given content-type.\n").
-spec bytes(integer(), binary(), bitstring()) -> gleam@http@response:response(mist:response_data()).
bytes(Status, Content_type, Body) ->
    _pipe = gleam@http@response:new(Status),
    _pipe@1 = gleam@http@response:set_header(
        _pipe,
        <<"content-type"/utf8>>,
        Content_type
    ),
    gleam@http@response:set_body(
        _pipe@1,
        {bytes, gleam@bytes_tree:from_bit_array(Body)}
    ).

-file("src/mistweaver/response.gleam", 62).
?DOC(" Issue a redirect. Use status 301 for permanent, 302 for temporary.\n").
-spec redirect(integer(), binary()) -> gleam@http@response:response(mist:response_data()).
redirect(Status, Location) ->
    _pipe = gleam@http@response:new(Status),
    _pipe@1 = gleam@http@response:set_header(
        _pipe,
        <<"location"/utf8>>,
        Location
    ),
    gleam@http@response:set_body(_pipe@1, {bytes, gleam@bytes_tree:new()}).

-file("src/mistweaver/response.gleam", 69).
?DOC(" 404 Not Found with an empty body.\n").
-spec not_found() -> gleam@http@response:response(mist:response_data()).
not_found() ->
    _pipe = gleam@http@response:new(404),
    gleam@http@response:set_body(_pipe, {bytes, gleam@bytes_tree:new()}).

-file("src/mistweaver/response.gleam", 75).
?DOC(" 400 Bad Request with an optional message.\n").
-spec bad_request(binary()) -> gleam@http@response:response(mist:response_data()).
bad_request(Message) ->
    text(400, Message).

-file("src/mistweaver/response.gleam", 80).
?DOC(" 500 Internal Server Error with an optional message.\n").
-spec internal_server_error(binary()) -> gleam@http@response:response(mist:response_data()).
internal_server_error(Message) ->
    text(500, Message).

-file("src/mistweaver/response.gleam", 85).
?DOC(" 201 Created, typically with a Location header pointing at the new resource.\n").
-spec created(binary()) -> gleam@http@response:response(mist:response_data()).
created(Location) ->
    _pipe = gleam@http@response:new(201),
    _pipe@1 = gleam@http@response:set_header(
        _pipe,
        <<"location"/utf8>>,
        Location
    ),
    gleam@http@response:set_body(_pipe@1, {bytes, gleam@bytes_tree:new()}).

-file("src/mistweaver/response.gleam", 92).
?DOC(" 204 No Content.\n").
-spec no_content() -> gleam@http@response:response(mist:response_data()).
no_content() ->
    _pipe = gleam@http@response:new(204),
    gleam@http@response:set_body(_pipe, {bytes, gleam@bytes_tree:new()}).

-file("src/mistweaver/response.gleam", 98).
?DOC(" Add or replace a response header on an existing response.\n").
-spec put_header(
    gleam@http@response:response(mist:response_data()),
    binary(),
    binary()
) -> gleam@http@response:response(mist:response_data()).
put_header(Resp, Key, Value) ->
    gleam@http@response:set_header(Resp, Key, Value).
