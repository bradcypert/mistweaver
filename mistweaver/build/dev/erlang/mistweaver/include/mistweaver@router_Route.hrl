-record(route, {
    method :: gleam@http:method(),
    segments :: list(mistweaver@router:path_segment()),
    middlewares :: list(fun((gleam@http@request:request(any()), fun((gleam@http@request:request(any())) -> gleam@http@response:response(mist:response_data()))) -> gleam@http@response:response(mist:response_data()))),
    handler :: fun((gleam@http@request:request(any()), list({binary(), binary()})) -> gleam@http@response:response(mist:response_data()))
}).
