-record(telemetry, {
    handler :: gleam@option:option(fun((gloo@telemetry:event()) -> nil))
}).
