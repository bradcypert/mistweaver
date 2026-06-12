-module(mistweaver_pubsub_ffi).
-export([start/0, subscribe/2, unsubscribe/2, broadcast/2]).

-define(SCOPE, mistweaver_pubsub).

start() ->
    case pg:start_link(?SCOPE) of
        {ok, _} -> ok;
        {error, {already_started, _}} -> ok
    end.

subscribe(Topic, Pid) ->
    pg:join(?SCOPE, Topic, Pid),
    nil.

unsubscribe(Topic, Pid) ->
    try pg:leave(?SCOPE, Topic, Pid) of
        _ -> nil
    catch
        _:_ -> nil
    end.

broadcast(Topic, Message) ->
    Members = try pg:get_members(?SCOPE, Topic) of
        Pids -> Pids
    catch
        _:_ -> []
    end,
    lists:foreach(fun(Pid) -> Pid ! {pubsub, Topic, Message} end, Members),
    nil.
