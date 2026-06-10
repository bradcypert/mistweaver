-record(channel, {
    join :: fun((mistweaver@channel:socket()) -> {ok, any()} | {error, binary()}),
    handle_in :: fun((binary(), gleam@dynamic:dynamic_(), any(), mistweaver@channel:socket()) -> {any(),
        list(mistweaver@channel:push())}),
    handle_close :: fun((any(), mistweaver@channel:socket()) -> nil)
}).
