-record(adapter, {
    name :: binary(),
    connection :: gloo@adapter:db_connection(),
    quote_identifier :: fun((binary()) -> binary()),
    placeholder :: fun((integer()) -> binary()),
    savepoint_depth :: integer(),
    telemetry :: gloo@telemetry:telemetry()
}).
