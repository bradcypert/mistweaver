-record(config, {
    host :: binary(),
    database :: binary(),
    user :: binary(),
    password :: gleam@option:option(binary()),
    pool_size :: integer()
}).
