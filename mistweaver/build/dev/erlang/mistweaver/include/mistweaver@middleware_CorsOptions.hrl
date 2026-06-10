-record(cors_options, {
    allow_origins :: list(binary()),
    allow_methods :: list(binary()),
    allow_headers :: list(binary()),
    max_age_seconds :: gleam@option:option(integer())
}).
