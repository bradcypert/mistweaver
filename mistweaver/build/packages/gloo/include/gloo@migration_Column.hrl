-record(column, {
    name :: binary(),
    type_sql :: binary(),
    nullable :: boolean(),
    default :: gleam@option:option(binary()),
    primary_key :: boolean(),
    unique :: boolean()
}).
