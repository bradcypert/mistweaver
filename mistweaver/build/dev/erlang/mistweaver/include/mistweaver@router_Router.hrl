-record(router, {
    routes :: list(mistweaver@router:route(any())),
    prefix :: list(mistweaver@router:path_segment()),
    middlewares :: list(fun((gleam@http@request:request(any()), fun((gleam@http@request:request(any())) -> gleam@http@response:response(mist:response_data()))) -> gleam@http@response:response(mist:response_data())))
}).
