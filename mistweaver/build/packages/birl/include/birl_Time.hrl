-record(time, {
    timestamp :: gleam@time@timestamp:timestamp(),
    offset :: gleam@time@duration:duration(),
    timezone :: gleam@option:option(binary()),
    monotonic_time :: gleam@option:option(integer())
}).
