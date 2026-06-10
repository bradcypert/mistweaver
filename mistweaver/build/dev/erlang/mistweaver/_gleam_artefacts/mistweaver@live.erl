-module(mistweaver@live).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/mistweaver/live.gleam").
-export([handler/1, handler_with_shell/2, dynamic_handler/1, dynamic_handler_with_shell/2]).
-export_type([live_view/2]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-type live_view(CPF, CPG) :: {live_view,
        fun((list({binary(), binary()})) -> {CPF, lustre@effect:effect(CPG)}),
        fun((CPF, CPG) -> {CPF, lustre@effect:effect(CPG)}),
        fun((CPF) -> lustre@vdom@vnode:element(CPG))}.

-file("src/mistweaver/live.gleam", 162).
-spec serve_shell(gleam@http@request:request(mist@internal@http:connection())) -> gleam@http@response:response(mist:response_data()).
serve_shell(Req) ->
    Page = lustre@element@html:html(
        [lustre@attribute:attribute(<<"lang"/utf8>>, <<"en"/utf8>>)],
        [lustre@element@html:head(
                [],
                [lustre@element@html:meta(
                        [lustre@attribute:attribute(
                                <<"charset"/utf8>>,
                                <<"utf-8"/utf8>>
                            )]
                    ),
                    lustre@element@html:meta(
                        [lustre@attribute:attribute(
                                <<"name"/utf8>>,
                                <<"viewport"/utf8>>
                            ),
                            lustre@attribute:attribute(
                                <<"content"/utf8>>,
                                <<"width=device-width, initial-scale=1"/utf8>>
                            )]
                    ),
                    lustre@server_component:script()]
            ),
            lustre@element@html:body(
                [],
                [lustre@server_component:element(
                        [lustre@server_component:route(erlang:element(8, Req)),
                            lustre@server_component:method(web_socket)],
                        []
                    )]
            )]
    ),
    mistweaver@response:html(200, lustre@element:to_document_string(Page)).

-file("src/mistweaver/live.gleam", 237).
-spec handle_ws(
    gleam@erlang@process:subject(lustre@runtime@server@runtime:message(CRH)),
    mist:websocket_message(lustre@runtime@transport:client_message(CRH)),
    mist@internal@websocket:websocket_connection()
) -> mist:next(gleam@erlang@process:subject(lustre@runtime@server@runtime:message(CRH)), lustre@runtime@transport:client_message(CRH)).
handle_ws(Runtime_subj, Msg, Conn) ->
    case Msg of
        {text, Data} ->
            _ = begin
                _pipe = gleam@json:parse(
                    Data,
                    lustre@server_component:runtime_message_decoder()
                ),
                gleam@result:map(
                    _pipe,
                    fun(Runtime_msg) ->
                        gleam@erlang@process:send(Runtime_subj, Runtime_msg)
                    end
                )
            end,
            mist:continue(Runtime_subj);

        {custom, Client_msg} ->
            Payload = begin
                _pipe@1 = Client_msg,
                _pipe@2 = lustre@server_component:client_message_to_json(
                    _pipe@1
                ),
                gleam@json:to_string(_pipe@2)
            end,
            _ = mist:send_text_frame(Conn, Payload),
            mist:continue(Runtime_subj);

        closed ->
            gleam@erlang@process:send(Runtime_subj, lustre:shutdown()),
            mist:stop();

        shutdown ->
            gleam@erlang@process:send(Runtime_subj, lustre:shutdown()),
            mist:stop();

        {binary, _} ->
            mist:continue(Runtime_subj)
    end.

-file("src/mistweaver/live.gleam", 194).
-spec ws_upgrade(
    live_view(any(), any()),
    gleam@http@request:request(mist@internal@http:connection()),
    list({binary(), binary()})
) -> gleam@http@response:response(mist:response_data()).
ws_upgrade(Lv, Req, Params) ->
    mist:websocket(
        Req,
        fun(State, Msg, Conn) -> handle_ws(State, Msg, Conn) end,
        fun(_) ->
            App = lustre:application(
                erlang:element(2, Lv),
                erlang:element(3, Lv),
                erlang:element(4, Lv)
            ),
            Query_params = begin
                _pipe = gleam@http@request:get_query(Req),
                gleam@result:unwrap(_pipe, [])
            end,
            All_params = lists:append(Params, Query_params),
            case lustre:start_server_component(App, All_params) of
                {ok, Runtime} ->
                    Runtime_subj = lustre@server_component:subject(Runtime),
                    Client_subj = gleam@erlang@process:new_subject(),
                    gleam@erlang@process:send(
                        Runtime_subj,
                        lustre@server_component:register_subject(Client_subj)
                    ),
                    Selector = begin
                        _pipe@1 = gleam_erlang_ffi:new_selector(),
                        gleam@erlang@process:select(_pipe@1, Client_subj)
                    end,
                    {Runtime_subj, {some, Selector}};

                {error, _} ->
                    Dummy = gleam@erlang@process:new_subject(),
                    {Dummy, none}
            end
        end,
        fun(Runtime_subj@1) ->
            gleam@erlang@process:send(Runtime_subj@1, lustre:shutdown())
        end
    ).

-file("src/mistweaver/live.gleam", 63).
?DOC(
    " Return a route handler for a LiveView. A single handler manages both the\n"
    " initial page request and the WebSocket upgrade:\n"
    "\n"
    " - Regular HTTP GET → serves an HTML shell embedding the Lustre client\n"
    "   runtime and a `<lustre-server-component>` element wired to this same URL.\n"
    " - WebSocket upgrade → starts a Lustre server component runtime for this\n"
    "   connection and bridges Mist WebSocket messages to/from the Lustre runtime.\n"
    "\n"
    "   router.new()\n"
    "   |> router.get(\"/counter\", live.handler(counter_live))\n"
    "   |> router.get(\"/counter/*\", live.handler(counter_live))\n"
).
-spec handler(live_view(any(), any())) -> fun((gleam@http@request:request(mist@internal@http:connection()), list({binary(),
    binary()})) -> gleam@http@response:response(mist:response_data())).
handler(Lv) ->
    fun(Req, Params) ->
        case gleam@http@request:get_header(Req, <<"upgrade"/utf8>>) of
            {ok, <<"websocket"/utf8>>} ->
                ws_upgrade(Lv, Req, Params);

            _ ->
                serve_shell(Req)
        end
    end.

-file("src/mistweaver/live.gleam", 98).
-spec serve_custom_shell(
    gleam@http@request:request(mist@internal@http:connection()),
    fun((gleam@http@request:request(mist@internal@http:connection()), lustre@vdom@vnode:element(nil)) -> lustre@vdom@vnode:element(nil))
) -> gleam@http@response:response(mist:response_data()).
serve_custom_shell(Req, Shell) ->
    Component = lustre@server_component:element(
        [lustre@server_component:route(
                <<(erlang:element(8, Req))/binary,
                    (case erlang:element(9, Req) of
                        {some, Q} ->
                            <<"?"/utf8, Q/binary>>;

                        none ->
                            <<""/utf8>>
                    end)/binary>>
            ),
            lustre@server_component:method(web_socket)],
        []
    ),
    mistweaver@response:html(
        200,
        lustre@element:to_document_string(Shell(Req, Component))
    ).

-file("src/mistweaver/live.gleam", 86).
?DOC(
    " Like `handler/1` but lets the caller supply the full HTML shell.\n"
    " The `shell` function receives the request and the pre-built\n"
    " `<lustre-server-component>` element; it must include\n"
    " `server_component.script()` somewhere in `<head>`.\n"
    "\n"
    " This lets you wrap the live component in a page layout with navigation,\n"
    " forms, or other static content — including session-aware content since the\n"
    " request (and its cookies) is available.\n"
    "\n"
    "   router.get(\"/timeline\", live.handler_with_shell(timeline_live, fn(req, component) {\n"
    "     layout(req, component)\n"
    "   }))\n"
).
-spec handler_with_shell(
    live_view(any(), any()),
    fun((gleam@http@request:request(mist@internal@http:connection()), lustre@vdom@vnode:element(nil)) -> lustre@vdom@vnode:element(nil))
) -> fun((gleam@http@request:request(mist@internal@http:connection()), list({binary(),
    binary()})) -> gleam@http@response:response(mist:response_data())).
handler_with_shell(Lv, Shell) ->
    fun(Req, Params) ->
        case gleam@http@request:get_header(Req, <<"upgrade"/utf8>>) of
            {ok, <<"websocket"/utf8>>} ->
                ws_upgrade(Lv, Req, Params);

            _ ->
                serve_custom_shell(Req, Shell)
        end
    end.

-file("src/mistweaver/live.gleam", 127).
?DOC(
    " Like `handler/1` but the LiveView is created fresh per request by calling\n"
    " `make_lv(req, params)`. This lets the LiveView's `init` and `update`\n"
    " functions close over session data (or any other per-request context)\n"
    " extracted from the request — analogous to Phoenix `mount/3` receiving\n"
    " the socket with session assigns.\n"
    "\n"
    "   router.get(\"/timeline\", live.dynamic_handler(fn(req, _params) {\n"
    "     let sess  = session.get(req, secret)\n"
    "     let uid   = session.fetch(sess, \"user_id\") |> option.then(int.parse >> option.from_result)\n"
    "     timeline.make(repo, uid)\n"
    "   }))\n"
).
-spec dynamic_handler(
    fun((gleam@http@request:request(mist@internal@http:connection()), list({binary(),
        binary()})) -> live_view(any(), any()))
) -> fun((gleam@http@request:request(mist@internal@http:connection()), list({binary(),
    binary()})) -> gleam@http@response:response(mist:response_data())).
dynamic_handler(Make_lv) ->
    fun(Req, Params) ->
        case gleam@http@request:get_header(Req, <<"upgrade"/utf8>>) of
            {ok, <<"websocket"/utf8>>} ->
                ws_upgrade(Make_lv(Req, Params), Req, Params);

            _ ->
                serve_shell(Req)
        end
    end.

-file("src/mistweaver/live.gleam", 143).
?DOC(
    " `dynamic_handler` with a custom HTML shell. Both the LiveView factory and\n"
    " the shell receive the full request, so both can read the session.\n"
).
-spec dynamic_handler_with_shell(
    fun((gleam@http@request:request(mist@internal@http:connection()), list({binary(),
        binary()})) -> live_view(any(), any())),
    fun((gleam@http@request:request(mist@internal@http:connection()), lustre@vdom@vnode:element(nil)) -> lustre@vdom@vnode:element(nil))
) -> fun((gleam@http@request:request(mist@internal@http:connection()), list({binary(),
    binary()})) -> gleam@http@response:response(mist:response_data())).
dynamic_handler_with_shell(Make_lv, Shell) ->
    fun(Req, Params) ->
        case gleam@http@request:get_header(Req, <<"upgrade"/utf8>>) of
            {ok, <<"websocket"/utf8>>} ->
                ws_upgrade(Make_lv(Req, Params), Req, Params);

            _ ->
                serve_custom_shell(Req, Shell)
        end
    end.
