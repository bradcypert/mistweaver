-module(mistweaver_test).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "test/mistweaver_test.gleam").
-export([main/0, dispatches_get_test/0, dispatches_post_test/0, method_mismatch_returns_404_test/0, unknown_path_returns_404_test/0, captures_single_path_param_test/0, captures_multiple_path_params_test/0, param_does_not_match_wrong_segment_count_test/0, scope_prefixes_routes_test/0, scope_middleware_runs_before_handler_test/0, nested_scopes_accumulate_prefix_test/0, html_response_sets_content_type_test/0, json_response_sets_content_type_test/0, redirect_sets_location_header_test/0, path_param_found_test/0, path_param_missing_test/0, path_segments_test/0, query_param_test/0, request_id_generates_header_test/0, request_id_propagates_existing_test/0, request_id_echoes_id_in_response_test/0, cors_adds_headers_test/0, cors_handles_preflight_test/0, cors_restricts_origin_test/0, log_middleware_returns_response_unchanged_test/0, multiple_middleware_run_in_order_test/0, channel_join_accept_test/0, channel_join_reject_test/0, channel_handle_in_updates_state_test/0, channel_handle_in_returns_pushes_test/0, channel_socket_router_builds_without_panic_test/0]).

-file("test/mistweaver_test.gleam", 16).
-spec main() -> nil.
main() ->
    gleeunit:main().

-file("test/mistweaver_test.gleam", 24).
-spec make_request(gleam@http:method(), binary()) -> gleam@http@request:request(nil).
make_request(Method, Path) ->
    {request, Method, [], nil, http, <<"localhost"/utf8>>, none, Path, none}.

-file("test/mistweaver_test.gleam", 37).
-spec ok_text(binary()) -> gleam@http@response:response(mist:response_data()).
ok_text(Body) ->
    mistweaver@response:text(200, Body).

-file("test/mistweaver_test.gleam", 45).
-spec dispatches_get_test() -> nil.
dispatches_get_test() ->
    R = begin
        _pipe = mistweaver@router:new(),
        mistweaver@router:get(
            _pipe,
            <<"/hello"/utf8>>,
            fun(_, _) -> ok_text(<<"hello"/utf8>>) end
        )
    end,
    Resp = mistweaver@router:dispatch(R, make_request(get, <<"/hello"/utf8>>)),
    _assert_subject = erlang:element(2, Resp),
    _assert_subject@1 = 200,
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"dispatches_get_test"/utf8>>,
                line => 51,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 1304,
                    'end' => 1315
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 1319,
                    'end' => 1322
                    },
                start => 1297,
                'end' => 1322,
                expression_start => 1304})
    end.

-file("test/mistweaver_test.gleam", 54).
-spec dispatches_post_test() -> nil.
dispatches_post_test() ->
    R = begin
        _pipe = mistweaver@router:new(),
        mistweaver@router:post(
            _pipe,
            <<"/items"/utf8>>,
            fun(_, _) -> mistweaver@response:text(201, <<"created"/utf8>>) end
        )
    end,
    Resp = mistweaver@router:dispatch(R, make_request(post, <<"/items"/utf8>>)),
    _assert_subject = erlang:element(2, Resp),
    _assert_subject@1 = 201,
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"dispatches_post_test"/utf8>>,
                line => 60,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 1547,
                    'end' => 1558
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 1562,
                    'end' => 1565
                    },
                start => 1540,
                'end' => 1565,
                expression_start => 1547})
    end.

-file("test/mistweaver_test.gleam", 63).
-spec method_mismatch_returns_404_test() -> nil.
method_mismatch_returns_404_test() ->
    R = begin
        _pipe = mistweaver@router:new(),
        mistweaver@router:get(
            _pipe,
            <<"/hello"/utf8>>,
            fun(_, _) -> ok_text(<<"hello"/utf8>>) end
        )
    end,
    Resp = mistweaver@router:dispatch(R, make_request(post, <<"/hello"/utf8>>)),
    _assert_subject = erlang:element(2, Resp),
    _assert_subject@1 = 404,
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"method_mismatch_returns_404_test"/utf8>>,
                line => 69,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 1785,
                    'end' => 1796
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 1800,
                    'end' => 1803
                    },
                start => 1778,
                'end' => 1803,
                expression_start => 1785})
    end.

-file("test/mistweaver_test.gleam", 72).
-spec unknown_path_returns_404_test() -> nil.
unknown_path_returns_404_test() ->
    R = begin
        _pipe = mistweaver@router:new(),
        mistweaver@router:get(
            _pipe,
            <<"/hello"/utf8>>,
            fun(_, _) -> ok_text(<<"hello"/utf8>>) end
        )
    end,
    Resp = mistweaver@router:dispatch(R, make_request(get, <<"/goodbye"/utf8>>)),
    _assert_subject = erlang:element(2, Resp),
    _assert_subject@1 = 404,
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"unknown_path_returns_404_test"/utf8>>,
                line => 78,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 2021,
                    'end' => 2032
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 2036,
                    'end' => 2039
                    },
                start => 2014,
                'end' => 2039,
                expression_start => 2021})
    end.

-file("test/mistweaver_test.gleam", 85).
-spec captures_single_path_param_test() -> nil.
captures_single_path_param_test() ->
    R = begin
        _pipe = mistweaver@router:new(),
        mistweaver@router:get(
            _pipe,
            <<"/users/:id"/utf8>>,
            fun(_, Params) ->
                Id = case mistweaver@request:path_param(Params, <<"id"/utf8>>) of
                    {some, V} ->
                        V;

                    none ->
                        <<"missing"/utf8>>
                end,
                ok_text(Id)
            end
        )
    end,
    Resp = mistweaver@router:dispatch(
        R,
        make_request(get, <<"/users/42"/utf8>>)
    ),
    _assert_subject = erlang:element(2, Resp),
    _assert_subject@1 = 200,
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"captures_single_path_param_test"/utf8>>,
                line => 97,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 2567,
                    'end' => 2578
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 2582,
                    'end' => 2585
                    },
                start => 2560,
                'end' => 2585,
                expression_start => 2567})
    end.

-file("test/mistweaver_test.gleam", 100).
-spec captures_multiple_path_params_test() -> nil.
captures_multiple_path_params_test() ->
    R = begin
        _pipe = mistweaver@router:new(),
        mistweaver@router:get(
            _pipe,
            <<"/orgs/:org/repos/:repo"/utf8>>,
            fun(_, Params) ->
                case {mistweaver@request:path_param(Params, <<"org"/utf8>>),
                    mistweaver@request:path_param(Params, <<"repo"/utf8>>)} of
                    {{some, O}, {some, Repo}} ->
                        ok_text(<<<<O/binary, "/"/utf8>>/binary, Repo/binary>>);

                    {_, _} ->
                        mistweaver@response:bad_request(
                            <<"missing params"/utf8>>
                        )
                end
            end
        )
    end,
    Resp = mistweaver@router:dispatch(
        R,
        make_request(get, <<"/orgs/acme/repos/widget"/utf8>>)
    ),
    _assert_subject = erlang:element(2, Resp),
    _assert_subject@1 = 200,
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"captures_multiple_path_params_test"/utf8>>,
                line => 115,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 3063,
                    'end' => 3074
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 3078,
                    'end' => 3081
                    },
                start => 3056,
                'end' => 3081,
                expression_start => 3063})
    end.

-file("test/mistweaver_test.gleam", 118).
-spec param_does_not_match_wrong_segment_count_test() -> nil.
param_does_not_match_wrong_segment_count_test() ->
    R = begin
        _pipe = mistweaver@router:new(),
        mistweaver@router:get(
            _pipe,
            <<"/users/:id"/utf8>>,
            fun(_, _) -> ok_text(<<"ok"/utf8>>) end
        )
    end,
    Resp = mistweaver@router:dispatch(
        R,
        make_request(get, <<"/users/42/extra"/utf8>>)
    ),
    _assert_subject = erlang:element(2, Resp),
    _assert_subject@1 = 404,
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"param_does_not_match_wrong_segment_count_test"/utf8>>,
                line => 124,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 3323,
                    'end' => 3334
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 3338,
                    'end' => 3341
                    },
                start => 3316,
                'end' => 3341,
                expression_start => 3323})
    end.

-file("test/mistweaver_test.gleam", 131).
-spec scope_prefixes_routes_test() -> nil.
scope_prefixes_routes_test() ->
    R = begin
        _pipe = mistweaver@router:new(),
        mistweaver@router:scope(
            _pipe,
            <<"/api"/utf8>>,
            [],
            fun(S) -> _pipe@1 = S,
                mistweaver@router:get(
                    _pipe@1,
                    <<"/users"/utf8>>,
                    fun(_, _) -> ok_text(<<"users"/utf8>>) end
                ) end
        )
    end,
    Ok = mistweaver@router:dispatch(R, make_request(get, <<"/api/users"/utf8>>)),
    _assert_subject = erlang:element(2, Ok),
    _assert_subject@1 = 200,
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"scope_prefixes_routes_test"/utf8>>,
                line => 139,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 3784,
                    'end' => 3793
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 3797,
                    'end' => 3800
                    },
                start => 3777,
                'end' => 3800,
                expression_start => 3784})
    end,
    Nf = mistweaver@router:dispatch(R, make_request(get, <<"/users"/utf8>>)),
    _assert_subject@2 = erlang:element(2, Nf),
    _assert_subject@3 = 404,
    case _assert_subject@2 =:= _assert_subject@3 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"scope_prefixes_routes_test"/utf8>>,
                line => 142,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject@2,
                    start => 3875,
                    'end' => 3884
                    },
                right => #{kind => literal,
                    value => _assert_subject@3,
                    start => 3888,
                    'end' => 3891
                    },
                start => 3868,
                'end' => 3891,
                expression_start => 3875})
    end.

-file("test/mistweaver_test.gleam", 145).
-spec scope_middleware_runs_before_handler_test() -> nil.
scope_middleware_runs_before_handler_test() ->
    Marker = <<"x-scope-ran"/utf8>>,
    Scope_mw = fun(Req, Next) ->
        Next(gleam@http@request:set_header(Req, Marker, <<"true"/utf8>>))
    end,
    R = begin
        _pipe = mistweaver@router:new(),
        mistweaver@router:scope(
            _pipe,
            <<"/api"/utf8>>,
            [Scope_mw],
            fun(S) -> _pipe@1 = S,
                mistweaver@router:get(
                    _pipe@1,
                    <<"/ping"/utf8>>,
                    fun(Req@1, _) ->
                        case gleam@http@request:get_header(Req@1, Marker) of
                            {ok, <<"true"/utf8>>} ->
                                ok_text(<<"middleware ran"/utf8>>);

                            _ ->
                                mistweaver@response:internal_server_error(
                                    <<"middleware did not run"/utf8>>
                                )
                        end
                    end
                ) end
        )
    end,
    Resp = mistweaver@router:dispatch(
        R,
        make_request(get, <<"/api/ping"/utf8>>)
    ),
    _assert_subject = erlang:element(2, Resp),
    _assert_subject@1 = 200,
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"scope_middleware_runs_before_handler_test"/utf8>>,
                line => 165,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 4486,
                    'end' => 4497
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 4501,
                    'end' => 4504
                    },
                start => 4479,
                'end' => 4504,
                expression_start => 4486})
    end.

-file("test/mistweaver_test.gleam", 168).
-spec nested_scopes_accumulate_prefix_test() -> nil.
nested_scopes_accumulate_prefix_test() ->
    R = begin
        _pipe = mistweaver@router:new(),
        mistweaver@router:scope(
            _pipe,
            <<"/v1"/utf8>>,
            [],
            fun(Outer) -> _pipe@1 = Outer,
                mistweaver@router:scope(
                    _pipe@1,
                    <<"/admin"/utf8>>,
                    [],
                    fun(Inner) -> _pipe@2 = Inner,
                        mistweaver@router:get(
                            _pipe@2,
                            <<"/users"/utf8>>,
                            fun(_, _) -> ok_text(<<"admin users"/utf8>>) end
                        ) end
                ) end
        )
    end,
    Ok = mistweaver@router:dispatch(
        R,
        make_request(get, <<"/v1/admin/users"/utf8>>)
    ),
    _assert_subject = erlang:element(2, Ok),
    _assert_subject@1 = 200,
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"nested_scopes_accumulate_prefix_test"/utf8>>,
                line => 180,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 4877,
                    'end' => 4886
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 4890,
                    'end' => 4893
                    },
                start => 4870,
                'end' => 4893,
                expression_start => 4877})
    end,
    Nf = mistweaver@router:dispatch(
        R,
        make_request(get, <<"/admin/users"/utf8>>)
    ),
    _assert_subject@2 = erlang:element(2, Nf),
    _assert_subject@3 = 404,
    case _assert_subject@2 =:= _assert_subject@3 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"nested_scopes_accumulate_prefix_test"/utf8>>,
                line => 183,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject@2,
                    start => 4974,
                    'end' => 4983
                    },
                right => #{kind => literal,
                    value => _assert_subject@3,
                    start => 4987,
                    'end' => 4990
                    },
                start => 4967,
                'end' => 4990,
                expression_start => 4974})
    end.

-file("test/mistweaver_test.gleam", 190).
-spec html_response_sets_content_type_test() -> nil.
html_response_sets_content_type_test() ->
    Resp = mistweaver@response:html(200, <<"<h1>Hi</h1>"/utf8>>),
    _assert_subject = erlang:element(2, Resp),
    _assert_subject@1 = 200,
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"html_response_sets_content_type_test"/utf8>>,
                line => 192,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 5280,
                    'end' => 5291
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 5295,
                    'end' => 5298
                    },
                start => 5273,
                'end' => 5298,
                expression_start => 5280})
    end,
    _assert_subject@2 = gleam@http@response:get_header(
        Resp,
        <<"content-type"/utf8>>
    ),
    _assert_subject@3 = {ok, <<"text/html; charset=utf-8"/utf8>>},
    case _assert_subject@2 =:= _assert_subject@3 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"html_response_sets_content_type_test"/utf8>>,
                line => 193,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject@2,
                    start => 5308,
                    'end' => 5349
                    },
                right => #{kind => literal,
                    value => _assert_subject@3,
                    start => 5357,
                    'end' => 5387
                    },
                start => 5301,
                'end' => 5387,
                expression_start => 5308})
    end.

-file("test/mistweaver_test.gleam", 197).
-spec json_response_sets_content_type_test() -> nil.
json_response_sets_content_type_test() ->
    Resp = mistweaver@response:json(200, gleam@json:null()),
    _assert_subject = gleam@http@response:get_header(
        Resp,
        <<"content-type"/utf8>>
    ),
    _assert_subject@1 = {ok, <<"application/json"/utf8>>},
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"json_response_sets_content_type_test"/utf8>>,
                line => 199,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 5496,
                    'end' => 5537
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 5541,
                    'end' => 5563
                    },
                start => 5489,
                'end' => 5563,
                expression_start => 5496})
    end.

-file("test/mistweaver_test.gleam", 202).
-spec redirect_sets_location_header_test() -> nil.
redirect_sets_location_header_test() ->
    Resp = mistweaver@response:redirect(302, <<"/new-path"/utf8>>),
    _assert_subject = erlang:element(2, Resp),
    _assert_subject@1 = 302,
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"redirect_sets_location_header_test"/utf8>>,
                line => 204,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 5678,
                    'end' => 5689
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 5693,
                    'end' => 5696
                    },
                start => 5671,
                'end' => 5696,
                expression_start => 5678})
    end,
    _assert_subject@2 = gleam@http@response:get_header(
        Resp,
        <<"location"/utf8>>
    ),
    _assert_subject@3 = {ok, <<"/new-path"/utf8>>},
    case _assert_subject@2 =:= _assert_subject@3 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"redirect_sets_location_header_test"/utf8>>,
                line => 205,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject@2,
                    start => 5706,
                    'end' => 5743
                    },
                right => #{kind => literal,
                    value => _assert_subject@3,
                    start => 5747,
                    'end' => 5762
                    },
                start => 5699,
                'end' => 5762,
                expression_start => 5706})
    end.

-file("test/mistweaver_test.gleam", 212).
-spec path_param_found_test() -> nil.
path_param_found_test() ->
    Params = [{<<"id"/utf8>>, <<"99"/utf8>>},
        {<<"name"/utf8>>, <<"alice"/utf8>>}],
    _assert_subject = mistweaver@request:path_param(Params, <<"id"/utf8>>),
    _assert_subject@1 = {some, <<"99"/utf8>>},
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"path_param_found_test"/utf8>>,
                line => 214,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 6037,
                    'end' => 6072
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 6076,
                    'end' => 6086
                    },
                start => 6030,
                'end' => 6086,
                expression_start => 6037})
    end,
    _assert_subject@2 = mistweaver@request:path_param(Params, <<"name"/utf8>>),
    _assert_subject@3 = {some, <<"alice"/utf8>>},
    case _assert_subject@2 =:= _assert_subject@3 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"path_param_found_test"/utf8>>,
                line => 215,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject@2,
                    start => 6096,
                    'end' => 6133
                    },
                right => #{kind => literal,
                    value => _assert_subject@3,
                    start => 6137,
                    'end' => 6150
                    },
                start => 6089,
                'end' => 6150,
                expression_start => 6096})
    end.

-file("test/mistweaver_test.gleam", 218).
-spec path_param_missing_test() -> nil.
path_param_missing_test() ->
    Params = [{<<"id"/utf8>>, <<"99"/utf8>>}],
    _assert_subject = mistweaver@request:path_param(Params, <<"other"/utf8>>),
    case _assert_subject =:= none of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"path_param_missing_test"/utf8>>,
                line => 220,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 6229,
                    'end' => 6267
                    },
                right => #{kind => literal,
                    value => none,
                    start => 6271,
                    'end' => 6275
                    },
                start => 6222,
                'end' => 6275,
                expression_start => 6229})
    end.

-file("test/mistweaver_test.gleam", 223).
-spec path_segments_test() -> nil.
path_segments_test() ->
    Req = make_request(get, <<"/users/42/posts"/utf8>>),
    _assert_subject = mistweaver@request:path_segments(Req),
    _assert_subject@1 = [<<"users"/utf8>>, <<"42"/utf8>>, <<"posts"/utf8>>],
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"path_segments_test"/utf8>>,
                line => 225,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 6372,
                    'end' => 6401
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 6405,
                    'end' => 6429
                    },
                start => 6365,
                'end' => 6429,
                expression_start => 6372})
    end.

-file("test/mistweaver_test.gleam", 228).
-spec query_param_test() -> nil.
query_param_test() ->
    Req = begin
        _record = make_request(get, <<"/search"/utf8>>),
        {request,
            erlang:element(2, _record),
            erlang:element(3, _record),
            erlang:element(4, _record),
            erlang:element(5, _record),
            erlang:element(6, _record),
            erlang:element(7, _record),
            erlang:element(8, _record),
            {some, <<"q=gleam&page=2"/utf8>>}}
    end,
    _assert_subject = mistweaver@request:query_param(Req, <<"q"/utf8>>),
    _assert_subject@1 = {some, <<"gleam"/utf8>>},
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"query_param_test"/utf8>>,
                line => 234,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 6589,
                    'end' => 6621
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 6625,
                    'end' => 6638
                    },
                start => 6582,
                'end' => 6638,
                expression_start => 6589})
    end,
    _assert_subject@2 = mistweaver@request:query_param(Req, <<"page"/utf8>>),
    _assert_subject@3 = {some, <<"2"/utf8>>},
    case _assert_subject@2 =:= _assert_subject@3 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"query_param_test"/utf8>>,
                line => 235,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject@2,
                    start => 6648,
                    'end' => 6683
                    },
                right => #{kind => literal,
                    value => _assert_subject@3,
                    start => 6687,
                    'end' => 6696
                    },
                start => 6641,
                'end' => 6696,
                expression_start => 6648})
    end,
    _assert_subject@4 = mistweaver@request:query_param(Req, <<"missing"/utf8>>),
    case _assert_subject@4 =:= none of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"query_param_test"/utf8>>,
                line => 236,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject@4,
                    start => 6706,
                    'end' => 6744
                    },
                right => #{kind => literal,
                    value => none,
                    start => 6748,
                    'end' => 6752
                    },
                start => 6699,
                'end' => 6752,
                expression_start => 6706})
    end.

-file("test/mistweaver_test.gleam", 243).
-spec request_id_generates_header_test() -> nil.
request_id_generates_header_test() ->
    Resp = mistweaver@middleware:request_id(
        make_request(get, <<"/"/utf8>>),
        fun(_) -> mistweaver@response:ok() end
    ),
    _assert_subject = gleam@http@response:get_header(
        Resp,
        <<"x-request-id"/utf8>>
    ),
    _assert_subject@1 = {error, nil},
    case _assert_subject /= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"request_id_generates_header_test"/utf8>>,
                line => 248,
                kind => binary_operator,
                operator => '!=',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 7091,
                    'end' => 7132
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 7136,
                    'end' => 7146
                    },
                start => 7084,
                'end' => 7146,
                expression_start => 7091})
    end.

-file("test/mistweaver_test.gleam", 251).
-spec request_id_propagates_existing_test() -> nil.
request_id_propagates_existing_test() ->
    Req = begin
        _pipe = make_request(get, <<"/"/utf8>>),
        gleam@http@request:set_header(
            _pipe,
            <<"x-request-id"/utf8>>,
            <<"my-custom-id"/utf8>>
        )
    end,
    Resp = mistweaver@middleware:request_id(
        Req,
        fun(_) -> mistweaver@response:ok() end
    ),
    _assert_subject = gleam@http@response:get_header(
        Resp,
        <<"x-request-id"/utf8>>
    ),
    _assert_subject@1 = {ok, <<"my-custom-id"/utf8>>},
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"request_id_propagates_existing_test"/utf8>>,
                line => 258,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 7453,
                    'end' => 7494
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 7498,
                    'end' => 7516
                    },
                start => 7446,
                'end' => 7516,
                expression_start => 7453})
    end.

-file("test/mistweaver_test.gleam", 261).
-spec request_id_echoes_id_in_response_test() -> nil.
request_id_echoes_id_in_response_test() ->
    Req = begin
        _pipe = make_request(get, <<"/"/utf8>>),
        gleam@http@request:set_header(
            _pipe,
            <<"x-request-id"/utf8>>,
            <<"echo-me"/utf8>>
        )
    end,
    Resp = mistweaver@middleware:request_id(
        Req,
        fun(_) -> mistweaver@response:ok() end
    ),
    _assert_subject = gleam@http@response:get_header(
        Resp,
        <<"x-request-id"/utf8>>
    ),
    _assert_subject@1 = {ok, <<"echo-me"/utf8>>},
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"request_id_echoes_id_in_response_test"/utf8>>,
                line => 267,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 7747,
                    'end' => 7788
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 7792,
                    'end' => 7805
                    },
                start => 7740,
                'end' => 7805,
                expression_start => 7747})
    end.

-file("test/mistweaver_test.gleam", 270).
-spec cors_adds_headers_test() -> nil.
cors_adds_headers_test() ->
    Opts = mistweaver@middleware:cors_allow_all(),
    Resp = mistweaver@middleware:cors(
        Opts,
        make_request(get, <<"/"/utf8>>),
        fun(_) -> mistweaver@response:ok() end
    ),
    _assert_subject = gleam@http@response:get_header(
        Resp,
        <<"access-control-allow-origin"/utf8>>
    ),
    _assert_subject@1 = {ok, <<"*"/utf8>>},
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"cors_adds_headers_test"/utf8>>,
                line => 276,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 8002,
                    'end' => 8058
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 8062,
                    'end' => 8069
                    },
                start => 7995,
                'end' => 8069,
                expression_start => 8002})
    end,
    _assert_subject@2 = gleam@http@response:get_header(
        Resp,
        <<"access-control-allow-methods"/utf8>>
    ),
    _assert_subject@3 = {error, nil},
    case _assert_subject@2 /= _assert_subject@3 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"cors_adds_headers_test"/utf8>>,
                line => 277,
                kind => binary_operator,
                operator => '!=',
                left => #{kind => expression,
                    value => _assert_subject@2,
                    start => 8079,
                    'end' => 8136
                    },
                right => #{kind => literal,
                    value => _assert_subject@3,
                    start => 8140,
                    'end' => 8150
                    },
                start => 8072,
                'end' => 8150,
                expression_start => 8079})
    end.

-file("test/mistweaver_test.gleam", 280).
-spec cors_handles_preflight_test() -> nil.
cors_handles_preflight_test() ->
    Opts = mistweaver@middleware:cors_allow_all(),
    Resp = mistweaver@middleware:cors(
        Opts,
        make_request(options, <<"/api/users"/utf8>>),
        fun(_) -> mistweaver@response:ok() end
    ),
    _assert_subject = erlang:element(2, Resp),
    _assert_subject@1 = 204,
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"cors_handles_preflight_test"/utf8>>,
                line => 286,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 8365,
                    'end' => 8376
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 8380,
                    'end' => 8383
                    },
                start => 8358,
                'end' => 8383,
                expression_start => 8365})
    end,
    _assert_subject@2 = gleam@http@response:get_header(
        Resp,
        <<"access-control-allow-origin"/utf8>>
    ),
    _assert_subject@3 = {ok, <<"*"/utf8>>},
    case _assert_subject@2 =:= _assert_subject@3 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"cors_handles_preflight_test"/utf8>>,
                line => 287,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject@2,
                    start => 8393,
                    'end' => 8449
                    },
                right => #{kind => literal,
                    value => _assert_subject@3,
                    start => 8453,
                    'end' => 8460
                    },
                start => 8386,
                'end' => 8460,
                expression_start => 8393})
    end.

-file("test/mistweaver_test.gleam", 290).
-spec cors_restricts_origin_test() -> nil.
cors_restricts_origin_test() ->
    Opts = {cors_options,
        [<<"https://example.com"/utf8>>],
        [<<"GET"/utf8>>],
        [],
        none},
    Req = begin
        _pipe = make_request(get, <<"/"/utf8>>),
        gleam@http@request:set_header(
            _pipe,
            <<"origin"/utf8>>,
            <<"https://evil.com"/utf8>>
        )
    end,
    Resp = mistweaver@middleware:cors(
        Opts,
        Req,
        fun(_) -> mistweaver@response:ok() end
    ),
    _assert_subject = gleam@http@response:get_header(
        Resp,
        <<"access-control-allow-origin"/utf8>>
    ),
    _assert_subject@1 = {ok, <<""/utf8>>},
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"cors_restricts_origin_test"/utf8>>,
                line => 306,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 8927,
                    'end' => 8983
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 8987,
                    'end' => 8993
                    },
                start => 8920,
                'end' => 8993,
                expression_start => 8927})
    end.

-file("test/mistweaver_test.gleam", 309).
-spec log_middleware_returns_response_unchanged_test() -> nil.
log_middleware_returns_response_unchanged_test() ->
    Resp = mistweaver@middleware:log(
        make_request(get, <<"/health"/utf8>>),
        fun(_) -> mistweaver@response:text(200, <<"ok"/utf8>>) end
    ),
    _assert_subject = erlang:element(2, Resp),
    _assert_subject@1 = 200,
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"log_middleware_returns_response_unchanged_test"/utf8>>,
                line => 314,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 9183,
                    'end' => 9194
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 9198,
                    'end' => 9201
                    },
                start => 9176,
                'end' => 9201,
                expression_start => 9183})
    end.

-file("test/mistweaver_test.gleam", 446).
-spec result_or({ok, CYO} | {error, any()}, CYO) -> CYO.
result_or(R, Default) ->
    case R of
        {ok, V} ->
            V;

        {error, _} ->
            Default
    end.

-file("test/mistweaver_test.gleam", 321).
-spec multiple_middleware_run_in_order_test() -> nil.
multiple_middleware_run_in_order_test() ->
    Trace_header = <<"x-trace"/utf8>>,
    Mw_a = fun(Req, Next) ->
        Existing = begin
            _pipe = gleam@http@request:get_header(Req, Trace_header),
            result_or(_pipe, <<""/utf8>>)
        end,
        Next(
            gleam@http@request:set_header(
                Req,
                Trace_header,
                <<Existing/binary, "a"/utf8>>
            )
        )
    end,
    Mw_b = fun(Req@1, Next@1) ->
        Existing@1 = begin
            _pipe@1 = gleam@http@request:get_header(Req@1, Trace_header),
            result_or(_pipe@1, <<""/utf8>>)
        end,
        Next@1(
            gleam@http@request:set_header(
                Req@1,
                Trace_header,
                <<Existing@1/binary, "b"/utf8>>
            )
        )
    end,
    R = begin
        _pipe@2 = mistweaver@router:new(),
        mistweaver@router:scope(
            _pipe@2,
            <<"/"/utf8>>,
            [Mw_a, Mw_b],
            fun(S) -> _pipe@3 = S,
                mistweaver@router:get(
                    _pipe@3,
                    <<"/trace"/utf8>>,
                    fun(Req@2, _) ->
                        Trace = begin
                            _pipe@4 = gleam@http@request:get_header(
                                Req@2,
                                Trace_header
                            ),
                            result_or(_pipe@4, <<""/utf8>>)
                        end,
                        mistweaver@response:text(200, Trace)
                    end
                ) end
        )
    end,
    Resp = mistweaver@router:dispatch(R, make_request(get, <<"/trace"/utf8>>)),
    _assert_subject = erlang:element(2, Resp),
    _assert_subject@1 = 200,
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"multiple_middleware_run_in_order_test"/utf8>>,
                line => 346,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 10263,
                    'end' => 10274
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 10278,
                    'end' => 10281
                    },
                start => 10256,
                'end' => 10281,
                expression_start => 10263})
    end.

-file("test/mistweaver_test.gleam", 361).
-spec channel_join_accept_test() -> nil.
channel_join_accept_test() ->
    Ch = {channel,
        fun(_) -> {ok, 0} end,
        fun(_, _, State, _) -> {State, []} end,
        fun(_, _) -> nil end},
    Socket = {socket, <<"test"/utf8>>, <<"room:lobby"/utf8>>, none},
    _assert_subject = (erlang:element(2, Ch))(Socket),
    _assert_subject@1 = {ok, 0},
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"channel_join_accept_test"/utf8>>,
                line => 370,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 11246,
                    'end' => 11261
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 11265,
                    'end' => 11270
                    },
                start => 11239,
                'end' => 11270,
                expression_start => 11246})
    end.

-file("test/mistweaver_test.gleam", 373).
-spec channel_join_reject_test() -> nil.
channel_join_reject_test() ->
    Ch = {channel,
        fun(_) -> {error, <<"unauthorized"/utf8>>} end,
        fun(_, _, State, _) -> {State, []} end,
        fun(_, _) -> nil end},
    Socket = {socket, <<"test"/utf8>>, <<"room:lobby"/utf8>>, none},
    _assert_subject = (erlang:element(2, Ch))(Socket),
    _assert_subject@1 = {error, <<"unauthorized"/utf8>>},
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"channel_join_reject_test"/utf8>>,
                line => 382,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 11609,
                    'end' => 11624
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 11628,
                    'end' => 11649
                    },
                start => 11602,
                'end' => 11649,
                expression_start => 11609})
    end.

-file("test/mistweaver_test.gleam", 385).
-spec channel_handle_in_updates_state_test() -> nil.
channel_handle_in_updates_state_test() ->
    Ch = {channel,
        fun(_) -> {ok, 0} end,
        fun(Event, _, State, _) -> case Event of
                <<"increment"/utf8>> ->
                    {State + 1, []};

                _ ->
                    {State, []}
            end end,
        fun(_, _) -> nil end},
    Socket = {socket, <<"test"/utf8>>, <<"counter:1"/utf8>>, none},
    State0@1 = case (erlang:element(2, Ch))(Socket) of
        {ok, State0} -> State0;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"mistweaver_test"/utf8>>,
                        function => <<"channel_handle_in_updates_state_test"/utf8>>,
                        line => 399,
                        value => _assert_fail,
                        start => 12069,
                        'end' => 12108,
                        pattern_start => 12080,
                        pattern_end => 12090})
    end,
    {State1, _} = (erlang:element(3, Ch))(
        <<"increment"/utf8>>,
        gleam@dynamic:nil(),
        State0@1,
        Socket
    ),
    {State2, _} = (erlang:element(3, Ch))(
        <<"increment"/utf8>>,
        gleam@dynamic:nil(),
        State1,
        Socket
    ),
    {State3, _} = (erlang:element(3, Ch))(
        <<"other"/utf8>>,
        gleam@dynamic:nil(),
        State2,
        Socket
    ),
    _assert_subject = 2,
    case State3 =:= _assert_subject of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"channel_handle_in_updates_state_test"/utf8>>,
                line => 403,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => State3,
                    start => 12348,
                    'end' => 12354
                    },
                right => #{kind => literal,
                    value => _assert_subject,
                    start => 12358,
                    'end' => 12359
                    },
                start => 12341,
                'end' => 12359,
                expression_start => 12348})
    end.

-file("test/mistweaver_test.gleam", 406).
-spec channel_handle_in_returns_pushes_test() -> nil.
channel_handle_in_returns_pushes_test() ->
    Ch = {channel,
        fun(_) -> {ok, nil} end,
        fun(_, _, State, _) ->
            {State,
                [{event, <<"echo"/utf8>>, gleam@json:string(<<"hello"/utf8>>)}]}
        end,
        fun(_, _) -> nil end},
    Socket = {socket, <<"s1"/utf8>>, <<"chat:lobby"/utf8>>, none},
    State@2 = case (erlang:element(2, Ch))(Socket) of
        {ok, State@1} -> State@1;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"mistweaver_test"/utf8>>,
                        function => <<"channel_handle_in_returns_pushes_test"/utf8>>,
                        line => 417,
                        value => _assert_fail,
                        start => 12745,
                        'end' => 12783,
                        pattern_start => 12756,
                        pattern_end => 12765})
    end,
    {_, Pushes} = (erlang:element(3, Ch))(
        <<"msg"/utf8>>,
        gleam@dynamic:nil(),
        State@2,
        Socket
    ),
    _assert_subject = erlang:length(Pushes),
    _assert_subject@1 = 1,
    case _assert_subject =:= _assert_subject@1 of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"mistweaver_test"/utf8>>,
                function => <<"channel_handle_in_returns_pushes_test"/utf8>>,
                line => 419,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => _assert_subject,
                    start => 12864,
                    'end' => 12883
                    },
                right => #{kind => literal,
                    value => _assert_subject@1,
                    start => 12887,
                    'end' => 12888
                    },
                start => 12857,
                'end' => 12888,
                expression_start => 12864})
    end.

-file("test/mistweaver_test.gleam", 422).
-spec channel_socket_router_builds_without_panic_test() -> fun((gleam@http@request:request(mist@internal@http:connection()), list({binary(),
    binary()})) -> gleam@http@response:response(mist:response_data())).
channel_socket_router_builds_without_panic_test() ->
    Ch = {channel,
        fun(_) -> {ok, nil} end,
        fun(_, _, S, _) -> {S, []} end,
        fun(_, _) -> nil end},
    Socket_router = begin
        _pipe = mistweaver@channel:new_socket_router(),
        _pipe@1 = mistweaver@channel:route(_pipe, <<"system:lobby"/utf8>>, Ch),
        mistweaver@channel:route(_pipe@1, <<"room:*"/utf8>>, Ch)
    end,
    _ = mistweaver@channel:handler(Socket_router).
