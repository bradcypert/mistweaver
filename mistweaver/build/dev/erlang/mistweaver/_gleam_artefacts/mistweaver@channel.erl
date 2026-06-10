-module(mistweaver@channel).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/mistweaver/channel.gleam").
-export([new_socket_router/0, route/3, handler/1]).
-export_type([socket/0, push/0, channel/1, socket_router/0, topic_pattern/0, socket_router_entry/0, bound_channel/0, ws_state/0, phoenix_message/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-type socket() :: {socket, binary(), binary(), gleam@option:option(binary())}.

-type push() :: {event, binary(), gleam@json:json()}.

-type channel(BCT) :: {channel,
        fun((socket()) -> {ok, BCT} | {error, binary()}),
        fun((binary(), gleam@dynamic:dynamic_(), BCT, socket()) -> {BCT,
            list(push())}),
        fun((BCT, socket()) -> nil)}.

-opaque socket_router() :: {socket_router, list(socket_router_entry())}.

-type topic_pattern() :: {exact, binary()} | {wildcard, binary()}.

-type socket_router_entry() :: {socket_router_entry,
        topic_pattern(),
        fun((socket()) -> {ok, bound_channel()} | {error, binary()})}.

-type bound_channel() :: {bound_channel,
        fun((binary(), gleam@dynamic:dynamic_(), socket()) -> {bound_channel(),
            list(push())}),
        fun((socket()) -> nil)}.

-type ws_state() :: {ws_state,
        socket_router(),
        gleam@dict:dict(binary(), bound_channel()),
        binary()}.

-type phoenix_message() :: {phoenix_message,
        gleam@option:option(binary()),
        gleam@option:option(binary()),
        binary(),
        binary(),
        gleam@dynamic:dynamic_()}.

-file("src/mistweaver/channel.gleam", 121).
-spec new_socket_router() -> socket_router().
new_socket_router() ->
    {socket_router, []}.

-file("src/mistweaver/channel.gleam", 415).
-spec bind(channel(BDP), BDP) -> bound_channel().
bind(Ch, State) ->
    {bound_channel,
        fun(Event, Payload, Socket) ->
            {New_state, Pushes} = (erlang:element(3, Ch))(
                Event,
                Payload,
                State,
                Socket
            ),
            {bind(Ch, New_state), Pushes}
        end,
        fun(Socket@1) -> (erlang:element(4, Ch))(State, Socket@1) end}.

-file("src/mistweaver/channel.gleam", 379).
-spec parse_pattern(binary()) -> topic_pattern().
parse_pattern(Pattern) ->
    case gleam_stdlib:string_ends_with(Pattern, <<":*"/utf8>>) of
        true ->
            {wildcard, gleam@string:drop_end(Pattern, 1)};

        false ->
            case gleam_stdlib:string_ends_with(Pattern, <<"*"/utf8>>) of
                true ->
                    {wildcard, gleam@string:drop_end(Pattern, 1)};

                false ->
                    {exact, Pattern}
            end
    end.

-file("src/mistweaver/channel.gleam", 127).
?DOC(
    " Register a channel for a topic pattern. Use `\"topic:*\"` to match any\n"
    " subtopic, e.g. `\"room:*\"` matches `\"room:lobby\"` and `\"room:123\"`.\n"
).
-spec route(socket_router(), binary(), channel(any())) -> socket_router().
route(Router, Pattern, Ch) ->
    Parsed = parse_pattern(Pattern),
    Entry = {socket_router_entry,
        Parsed,
        fun(Socket) -> case (erlang:element(2, Ch))(Socket) of
                {ok, State} ->
                    {ok, bind(Ch, State)};

                {error, Msg} ->
                    {error, Msg}
            end end},
    {socket_router, lists:append(erlang:element(2, Router), [Entry])}.

-file("src/mistweaver/channel.gleam", 429).
-spec generate_socket_id() -> binary().
generate_socket_id() ->
    _pipe = crypto:strong_rand_bytes(8),
    _pipe@1 = gleam_stdlib:base16_encode(_pipe),
    string:lowercase(_pipe@1).

-file("src/mistweaver/channel.gleam", 368).
-spec nullable_string(gleam@option:option(binary())) -> gleam@json:json().
nullable_string(Opt) ->
    case Opt of
        {some, S} ->
            gleam@json:string(S);

        none ->
            gleam@json:null()
    end.

-file("src/mistweaver/channel.gleam", 322).
-spec encode_message(
    gleam@option:option(binary()),
    gleam@option:option(binary()),
    binary(),
    binary(),
    gleam@json:json()
) -> binary().
encode_message(Join_ref, Ref, Topic, Event, Payload) ->
    _pipe = gleam@json:preprocessed_array(
        [nullable_string(Join_ref),
            nullable_string(Ref),
            gleam@json:string(Topic),
            gleam@json:string(Event),
            Payload]
    ),
    gleam@json:to_string(_pipe).

-file("src/mistweaver/channel.gleam", 357).
-spec send_push(
    mist@internal@websocket:websocket_connection(),
    binary(),
    binary(),
    gleam@json:json()
) -> nil.
send_push(Conn, Topic, Event, Payload) ->
    Text = encode_message(none, none, Topic, Event, Payload),
    _ = mist:send_text_frame(Conn, Text),
    nil.

-file("src/mistweaver/channel.gleam", 339).
-spec send_reply(
    mist@internal@websocket:websocket_connection(),
    gleam@option:option(binary()),
    gleam@option:option(binary()),
    binary(),
    binary(),
    gleam@json:json()
) -> nil.
send_reply(Conn, Join_ref, Ref, Topic, Status, Response) ->
    Payload = gleam@json:object(
        [{<<"status"/utf8>>, gleam@json:string(Status)},
            {<<"response"/utf8>>, Response}]
    ),
    Text = encode_message(Join_ref, Ref, Topic, <<"phx_reply"/utf8>>, Payload),
    _ = mist:send_text_frame(Conn, Text),
    nil.

-file("src/mistweaver/channel.gleam", 404).
-spec matches_pattern(topic_pattern(), binary()) -> boolean().
matches_pattern(Pattern, Topic) ->
    case Pattern of
        {exact, P} ->
            P =:= Topic;

        {wildcard, Prefix} ->
            gleam_stdlib:string_starts_with(Topic, Prefix)
    end.

-file("src/mistweaver/channel.gleam", 390).
-spec find_channel(list(socket_router_entry()), binary()) -> {ok,
        fun((socket()) -> {ok, bound_channel()} | {error, binary()})} |
    {error, nil}.
find_channel(Entries, Topic) ->
    case Entries of
        [] ->
            {error, nil};

        [Entry | Rest] ->
            case matches_pattern(erlang:element(2, Entry), Topic) of
                true ->
                    {ok, erlang:element(3, Entry)};

                false ->
                    find_channel(Rest, Topic)
            end
    end.

-file("src/mistweaver/channel.gleam", 199).
-spec dispatch(
    ws_state(),
    phoenix_message(),
    mist@internal@websocket:websocket_connection()
) -> ws_state().
dispatch(State, Msg, Conn) ->
    case {erlang:element(4, Msg), erlang:element(5, Msg)} of
        {<<"phoenix"/utf8>>, <<"heartbeat"/utf8>>} ->
            send_reply(
                Conn,
                none,
                erlang:element(3, Msg),
                <<"phoenix"/utf8>>,
                <<"ok"/utf8>>,
                gleam@json:object([])
            ),
            State;

        {_, <<"phx_join"/utf8>>} ->
            Socket = {socket,
                erlang:element(4, State),
                erlang:element(4, Msg),
                erlang:element(2, Msg)},
            case find_channel(
                erlang:element(2, erlang:element(2, State)),
                erlang:element(4, Msg)
            ) of
                {ok, Factory} ->
                    case Factory(Socket) of
                        {ok, Bound} ->
                            send_reply(
                                Conn,
                                erlang:element(2, Msg),
                                erlang:element(3, Msg),
                                erlang:element(4, Msg),
                                <<"ok"/utf8>>,
                                gleam@json:object([])
                            ),
                            {ws_state,
                                erlang:element(2, State),
                                gleam@dict:insert(
                                    erlang:element(3, State),
                                    erlang:element(4, Msg),
                                    Bound
                                ),
                                erlang:element(4, State)};

                        {error, Reason} ->
                            send_reply(
                                Conn,
                                erlang:element(2, Msg),
                                erlang:element(3, Msg),
                                erlang:element(4, Msg),
                                <<"error"/utf8>>,
                                gleam@json:object(
                                    [{<<"reason"/utf8>>,
                                            gleam@json:string(Reason)}]
                                )
                            ),
                            State
                    end;

                {error, nil} ->
                    send_reply(
                        Conn,
                        erlang:element(2, Msg),
                        erlang:element(3, Msg),
                        erlang:element(4, Msg),
                        <<"error"/utf8>>,
                        gleam@json:object(
                            [{<<"reason"/utf8>>,
                                    gleam@json:string(
                                        <<"no channel for topic"/utf8>>
                                    )}]
                        )
                    ),
                    State
            end;

        {_, <<"phx_leave"/utf8>>} ->
            case gleam_stdlib:map_get(
                erlang:element(3, State),
                erlang:element(4, Msg)
            ) of
                {ok, Bound@1} ->
                    Socket@1 = {socket,
                        erlang:element(4, State),
                        erlang:element(4, Msg),
                        erlang:element(2, Msg)},
                    (erlang:element(3, Bound@1))(Socket@1),
                    send_reply(
                        Conn,
                        erlang:element(2, Msg),
                        erlang:element(3, Msg),
                        erlang:element(4, Msg),
                        <<"ok"/utf8>>,
                        gleam@json:object([])
                    ),
                    {ws_state,
                        erlang:element(2, State),
                        gleam@dict:delete(
                            erlang:element(3, State),
                            erlang:element(4, Msg)
                        ),
                        erlang:element(4, State)};

                {error, nil} ->
                    State
            end;

        {_, Custom_event} ->
            case gleam_stdlib:map_get(
                erlang:element(3, State),
                erlang:element(4, Msg)
            ) of
                {ok, Bound@2} ->
                    Socket@2 = {socket,
                        erlang:element(4, State),
                        erlang:element(4, Msg),
                        erlang:element(2, Msg)},
                    {New_bound, Pushes} = (erlang:element(2, Bound@2))(
                        Custom_event,
                        erlang:element(6, Msg),
                        Socket@2
                    ),
                    gleam@list:each(Pushes, fun(Push) -> case Push of
                                {event, Event, Payload} ->
                                    send_push(
                                        Conn,
                                        erlang:element(4, Msg),
                                        Event,
                                        Payload
                                    )
                            end end),
                    {ws_state,
                        erlang:element(2, State),
                        gleam@dict:insert(
                            erlang:element(3, State),
                            erlang:element(4, Msg),
                            New_bound
                        ),
                        erlang:element(4, State)};

                {error, nil} ->
                    State
            end
    end.

-file("src/mistweaver/channel.gleam", 313).
-spec phoenix_message_decoder() -> gleam@dynamic@decode:decoder(phoenix_message()).
phoenix_message_decoder() ->
    gleam@dynamic@decode:then(
        gleam@dynamic@decode:at(
            [0],
            gleam@dynamic@decode:optional(
                {decoder, fun gleam@dynamic@decode:decode_string/1}
            )
        ),
        fun(Join_ref) ->
            gleam@dynamic@decode:then(
                gleam@dynamic@decode:at(
                    [1],
                    gleam@dynamic@decode:optional(
                        {decoder, fun gleam@dynamic@decode:decode_string/1}
                    )
                ),
                fun(Ref) ->
                    gleam@dynamic@decode:then(
                        gleam@dynamic@decode:at(
                            [2],
                            {decoder, fun gleam@dynamic@decode:decode_string/1}
                        ),
                        fun(Topic) ->
                            gleam@dynamic@decode:then(
                                gleam@dynamic@decode:at(
                                    [3],
                                    {decoder,
                                        fun gleam@dynamic@decode:decode_string/1}
                                ),
                                fun(Event) ->
                                    gleam@dynamic@decode:then(
                                        gleam@dynamic@decode:at(
                                            [4],
                                            {decoder,
                                                fun gleam@dynamic@decode:decode_dynamic/1}
                                        ),
                                        fun(Payload) ->
                                            gleam@dynamic@decode:success(
                                                {phoenix_message,
                                                    Join_ref,
                                                    Ref,
                                                    Topic,
                                                    Event,
                                                    Payload}
                                            )
                                        end
                                    )
                                end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/mistweaver/channel.gleam", 308).
-spec parse_message(binary()) -> {ok, phoenix_message()} | {error, nil}.
parse_message(Text) ->
    _pipe = gleam@json:parse(Text, phoenix_message_decoder()),
    gleam@result:replace_error(_pipe, nil).

-file("src/mistweaver/channel.gleam", 181).
-spec handle_ws_message(
    ws_state(),
    mist:websocket_message(nil),
    mist@internal@websocket:websocket_connection()
) -> mist:next(ws_state(), nil).
handle_ws_message(State, Msg, Conn) ->
    case Msg of
        {text, Text} ->
            case parse_message(Text) of
                {ok, Phoenix_msg} ->
                    mist:continue(dispatch(State, Phoenix_msg, Conn));

                {error, _} ->
                    mist:continue(State)
            end;

        {binary, _} ->
            mist:continue(State);

        closed ->
            mist:stop();

        shutdown ->
            mist:stop();

        {custom, _} ->
            mist:continue(State)
    end.

-file("src/mistweaver/channel.gleam", 151).
?DOC(
    " Produce a Mistweaver route handler that upgrades HTTP to WebSocket and\n"
    " runs the socket router. Wire it up with any HTTP method (conventionally GET):\n"
    "\n"
    "   router.new()\n"
    "   |> router.get(\"/socket/websocket\", channel.handler(my_socket_router))\n"
).
-spec handler(socket_router()) -> fun((gleam@http@request:request(mist@internal@http:connection()), list({binary(),
    binary()})) -> gleam@http@response:response(mist:response_data())).
handler(Socket_router) ->
    fun(Req, _) ->
        mist:websocket(
            Req,
            fun handle_ws_message/3,
            fun(_) ->
                State = {ws_state,
                    Socket_router,
                    maps:new(),
                    generate_socket_id()},
                {State, none}
            end,
            fun(State@1) ->
                gleam@dict:each(
                    erlang:element(3, State@1),
                    fun(Topic, Bound) ->
                        Socket = {socket,
                            erlang:element(4, State@1),
                            Topic,
                            none},
                        (erlang:element(3, Bound))(Socket)
                    end
                )
            end
        )
    end.
