-module(mistweaver_mailer_ffi).
-export([list_ref_new/0, list_ref_push/2, list_ref_get/1]).

list_ref_new() ->
    ets_ref_new().

ets_ref_new() ->
    Ref = make_ref(),
    ets:new(Ref, [public, set]),
    ets:insert(Ref, {items, []}),
    Ref.

list_ref_push(Ref, Item) ->
    [{items, Current}] = ets:lookup(Ref, items),
    ets:insert(Ref, {items, [Item | Current]}),
    nil.

list_ref_get(Ref) ->
    case ets:lookup(Ref, items) of
        [{items, Items}] -> lists:reverse(Items);
        [] -> []
    end.
