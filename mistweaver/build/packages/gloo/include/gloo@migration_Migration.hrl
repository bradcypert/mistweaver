-record(migration, {
    version :: integer(),
    name :: binary(),
    up :: binary(),
    down :: gleam@option:option(binary())
}).
