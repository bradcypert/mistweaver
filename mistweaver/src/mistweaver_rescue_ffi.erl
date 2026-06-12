-module(mistweaver_rescue_ffi).
-export([try_call/1]).

try_call(Fun) ->
    try Fun() of
        Result -> {ok, Result}
    catch
        Class:Reason:Stack ->
            logger:error("Unhandled error in handler: ~p ~p~n~p", [Class, Reason, Stack]),
            {error, nil}
    end.
