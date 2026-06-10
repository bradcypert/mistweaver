-record(table, {
    name :: binary(),
    primary_key :: binary(),
    decoder :: gleam@dynamic@decode:decoder(any())
}).
