-record(sql, {
    statement :: binary(),
    parameters :: list(gloo@value:gloo_value()),
    decoder :: gleam@dynamic@decode:decoder(any()),
    param_count :: integer()
}).
