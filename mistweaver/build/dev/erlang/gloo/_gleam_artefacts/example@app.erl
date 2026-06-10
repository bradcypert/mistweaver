-module(example@app).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/example/app.gleam").
-export([main/0]).

-file("src/example/app.gleam", 12).
-spec main() -> nil.
main() ->
    R@1 = case begin
        _pipe = gloo@adapter@postgres:default_config(),
        _pipe@1 = gloo@adapter@postgres:database(_pipe, <<"gloo_example"/utf8>>),
        _pipe@2 = gloo@adapter@postgres:password(
            _pipe@1,
            {some, <<"postgres"/utf8>>}
        ),
        gloo@adapter@postgres:start(_pipe@2)
    end of
        {ok, R} -> R;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"example/app"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 13,
                        value => _assert_fail,
                        start => 239,
                        'end' => 395,
                        pattern_start => 250,
                        pattern_end => 255})
    end,
    gleam_stdlib:println(<<"=== gloo example app ===\n"/utf8>>),
    gleam_stdlib:println(<<"Running migrations..."/utf8>>),
    Migs = example@migrations:all(),
    Applied@1 = case gloo@runner:run(R@1, Migs, up, none) of
        {ok, Applied} -> Applied;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"example/app"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 24,
                        value => _assert_fail@1,
                        start => 718,
                        'end' => 779,
                        pattern_start => 729,
                        pattern_end => 740})
    end,
    case Applied@1 of
        0 ->
            gleam_stdlib:println(<<"Already up to date."/utf8>>);

        N ->
            gleam_stdlib:println(
                <<<<"Applied "/utf8, (erlang:integer_to_binary(N))/binary>>/binary,
                    " migration(s)."/utf8>>
            )
    end,
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"Validating inputs..."/utf8>>),
    Bad = gloo@validate:struct(
        [gloo@validate:field(
                <<"email"/utf8>>,
                <<"not-an-email"/utf8>>,
                [gloo@validate:format(<<"^[^@]+@[^@]+\\.[^@]+$"/utf8>>)]
            ),
            gloo@validate:field(
                <<"name"/utf8>>,
                <<""/utf8>>,
                [gloo@validate:max_length(100)]
            )]
    ),
    case Bad of
        {ok, _} ->
            gleam_stdlib:println(<<"unexpected ok"/utf8>>);

        {error, Errs} ->
            gleam@list:each(
                Errs,
                fun(E) ->
                    {field_error, Field, Message} = E,
                    gleam_stdlib:println(
                        <<<<<<"  validation error — "/utf8, Field/binary>>/binary,
                                ": "/utf8>>/binary,
                            Message/binary>>
                    )
                end
            )
    end,
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"Creating users..."/utf8>>),
    Alice@1 = case example@queries:create_user(
        R@1,
        <<"alice@example.com"/utf8>>,
        <<"Alice"/utf8>>
    ) of
        {ok, Alice} -> Alice;
        _assert_fail@2 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"example/app"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 51,
                        value => _assert_fail@2,
                        start => 1880,
                        'end' => 1955,
                        pattern_start => 1891,
                        pattern_end => 1900})
    end,
    Bob@1 = case example@queries:create_user(
        R@1,
        <<"bob@example.com"/utf8>>,
        <<"Bob"/utf8>>
    ) of
        {ok, Bob} -> Bob;
        _assert_fail@3 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"example/app"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 52,
                        value => _assert_fail@3,
                        start => 1958,
                        'end' => 2027,
                        pattern_start => 1969,
                        pattern_end => 1976})
    end,
    Carol@1 = case example@queries:create_user(
        R@1,
        <<"carol@example.com"/utf8>>,
        <<"Carol"/utf8>>
    ) of
        {ok, Carol} -> Carol;
        _assert_fail@4 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"example/app"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 53,
                        value => _assert_fail@4,
                        start => 2030,
                        'end' => 2105,
                        pattern_start => 2041,
                        pattern_end => 2050})
    end,
    gleam_stdlib:println(
        <<<<<<<<"  created: "/utf8, (erlang:element(4, Alice@1))/binary>>/binary,
                    " (id="/utf8>>/binary,
                (erlang:integer_to_binary(erlang:element(2, Alice@1)))/binary>>/binary,
            ")"/utf8>>
    ),
    gleam_stdlib:println(
        <<<<<<<<"  created: "/utf8, (erlang:element(4, Bob@1))/binary>>/binary,
                    " (id="/utf8>>/binary,
                (erlang:integer_to_binary(erlang:element(2, Bob@1)))/binary>>/binary,
            ")"/utf8>>
    ),
    gleam_stdlib:println(
        <<<<<<<<"  created: "/utf8, (erlang:element(4, Carol@1))/binary>>/binary,
                    " (id="/utf8>>/binary,
                (erlang:integer_to_binary(erlang:element(2, Carol@1)))/binary>>/binary,
            ")"/utf8>>
    ),
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(
        <<"Testing constraint violation (duplicate email)..."/utf8>>
    ),
    case example@queries:create_user(
        R@1,
        <<"alice@example.com"/utf8>>,
        <<"Alice2"/utf8>>
    ) of
        {ok, _} ->
            gleam_stdlib:println(<<"  unexpected ok"/utf8>>);

        {error, {constraint_error, Name}} ->
            gleam_stdlib:println(
                <<"  caught ConstraintError: "/utf8, Name/binary>>
            );

        {error, E@1} ->
            gleam_stdlib:println(
                <<"  unexpected error: "/utf8,
                    (gloo@error:to_string(E@1))/binary>>
            )
    end,
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"Creating follows..."/utf8>>),
    case example@queries:follow_user(
        R@1,
        erlang:element(2, Bob@1),
        erlang:element(2, Alice@1)
    ) of
        {ok, _} -> nil;
        _assert_fail@5 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"example/app"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 71,
                        value => _assert_fail@5,
                        start => 3184,
                        'end' => 3243,
                        pattern_start => 3195,
                        pattern_end => 3200})
    end,
    case example@queries:follow_user(
        R@1,
        erlang:element(2, Carol@1),
        erlang:element(2, Alice@1)
    ) of
        {ok, _} -> nil;
        _assert_fail@6 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"example/app"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 72,
                        value => _assert_fail@6,
                        start => 3246,
                        'end' => 3307,
                        pattern_start => 3257,
                        pattern_end => 3262})
    end,
    gleam_stdlib:println(<<"  bob -> alice, carol -> alice"/utf8>>),
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"Creating posts..."/utf8>>),
    P1@1 = case example@queries:create_post(
        R@1,
        erlang:element(2, Alice@1),
        <<"Hello from Alice!"/utf8>>
    ) of
        {ok, P1} -> P1;
        _assert_fail@7 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"example/app"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 78,
                        value => _assert_fail@7,
                        start => 3626,
                        'end' => 3699,
                        pattern_start => 3637,
                        pattern_end => 3643})
    end,
    case example@queries:create_post(
        R@1,
        erlang:element(2, Alice@1),
        <<"Second post from Alice."/utf8>>
    ) of
        {ok, _} -> nil;
        _assert_fail@8 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"example/app"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 79,
                        value => _assert_fail@8,
                        start => 3702,
                        'end' => 3780,
                        pattern_start => 3713,
                        pattern_end => 3718})
    end,
    gleam_stdlib:println(
        <<<<"  alice posted: \""/utf8, (erlang:element(4, P1@1))/binary>>/binary,
            "\""/utf8>>
    ),
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"Feed for Bob (follows Alice)..."/utf8>>),
    Feed@1 = case example@queries:feed_for_user(
        R@1,
        erlang:element(2, Bob@1),
        10
    ) of
        {ok, Feed} -> Feed;
        _assert_fail@9 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"example/app"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 85,
                        value => _assert_fail@9,
                        start => 4083,
                        'end' => 4141,
                        pattern_start => 4094,
                        pattern_end => 4102})
    end,
    gleam@list:each(
        Feed@1,
        fun(Fp) ->
            gleam_stdlib:println(
                <<<<<<<<<<"  ["/utf8,
                                    (erlang:integer_to_binary(
                                        erlang:element(2, Fp)
                                    ))/binary>>/binary,
                                "] "/utf8>>/binary,
                            (erlang:element(3, Fp))/binary>>/binary,
                        ": "/utf8>>/binary,
                    (erlang:element(4, Fp))/binary>>
            )
        end
    ),
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"Find user by email..."/utf8>>),
    Found@1 = case example@queries:find_user_by_email(
        R@1,
        <<"carol@example.com"/utf8>>
    ) of
        {ok, Found} -> Found;
        _assert_fail@10 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"example/app"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 95,
                        value => _assert_fail@10,
                        start => 4512,
                        'end' => 4585,
                        pattern_start => 4523,
                        pattern_end => 4532})
    end,
    gleam_stdlib:println(
        <<<<<<<<"  found: "/utf8, (erlang:element(4, Found@1))/binary>>/binary,
                    " <"/utf8>>/binary,
                (erlang:element(3, Found@1))/binary>>/binary,
            ">"/utf8>>
    ),
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(
        <<"Deleting Alice and her posts in a transaction..."/utf8>>
    ),
    case example@queries:delete_user_and_posts(R@1, erlang:element(2, Alice@1)) of
        {ok, nil} -> nil;
        _assert_fail@11 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"example/app"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 101,
                        value => _assert_fail@11,
                        start => 4882,
                        'end' => 4945,
                        pattern_start => 4893,
                        pattern_end => 4900})
    end,
    gleam_stdlib:println(<<"  done."/utf8>>),
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"Verifying Alice is gone..."/utf8>>),
    case example@queries:find_user_by_email(R@1, <<"alice@example.com"/utf8>>) of
        {error, no_result_error} ->
            gleam_stdlib:println(<<"  confirmed: no result."/utf8>>);

        {ok, U} ->
            gleam_stdlib:println(
                <<"  unexpected: still found "/utf8,
                    (erlang:element(4, U))/binary>>
            );

        {error, E@2} ->
            gleam_stdlib:println(
                <<"  unexpected error: "/utf8,
                    (gloo@error:to_string(E@2))/binary>>
            )
    end,
    gleam_stdlib:println(<<""/utf8>>),
    gleam_stdlib:println(<<"Rolling back all migrations..."/utf8>>),
    Rolled@1 = case gloo@runner:run(
        R@1,
        Migs,
        down,
        {some, erlang:length(Migs)}
    ) of
        {ok, Rolled} -> Rolled;
        _assert_fail@12 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"example/app"/utf8>>,
                        function => <<"main"/utf8>>,
                        line => 116,
                        value => _assert_fail@12,
                        start => 5688,
                        'end' => 5773,
                        pattern_start => 5699,
                        pattern_end => 5709})
    end,
    gleam_stdlib:println(
        <<<<"Rolled back "/utf8, (erlang:integer_to_binary(Rolled@1))/binary>>/binary,
            " migration(s)."/utf8>>
    ),
    gleam_stdlib:println(<<"\n=== all done ==="/utf8>>).
