-module(mistweaver_telemetry_ffi).
-export([emit/3, attach/3, detach/1]).

-define(HANDLER_TABLE, mistweaver_telemetry_handlers).

emit(Name, Measurements, Metadata) ->
    Handlers = case ets:whereis(?HANDLER_TABLE) of
        undefined -> [];
        _ ->
            case ets:lookup(?HANDLER_TABLE, Name) of
                [] -> [];
                [{_, H}] -> H
            end
    end,
    lists:foreach(fun(Handler) ->
        try Handler(Name, Measurements, Metadata)
        catch _:_ -> ok
        end
    end, Handlers),
    nil.

attach(Id, Name, Handler) ->
    ensure_table(),
    Handlers = case ets:lookup(?HANDLER_TABLE, Name) of
        [] -> [];
        [{_, H}] -> H
    end,
    Filtered = lists:filter(fun({HId, _}) -> HId =/= Id end, Handlers),
    ets:insert(?HANDLER_TABLE, {Name, [{Id, Handler} | Filtered]}),
    nil.

detach(Id) ->
    case ets:whereis(?HANDLER_TABLE) of
        undefined -> nil;
        _ ->
            ets:foldl(fun({Name, Handlers}, _) ->
                Filtered = lists:filter(fun({HId, _}) -> HId =/= Id end, Handlers),
                ets:insert(?HANDLER_TABLE, {Name, Filtered}),
                ok
            end, ok, ?HANDLER_TABLE),
            nil
    end.

ensure_table() ->
    case ets:whereis(?HANDLER_TABLE) of
        undefined ->
            ets:new(?HANDLER_TABLE, [named_table, public, set]);
        _ ->
            ok
    end.
