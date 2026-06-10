-module(birl@interval).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/birl/interval.gleam").
-export([from_start_and_end/2, from_start_and_duration/2, shift/2, scale_up/2, scale_down/2, includes/2, contains/2, intersection/2, get_bounds/1]).
-export_type([interval/0]).

-opaque interval() :: {interval, birl:time(), birl:time()}.

-file("src/birl/interval.gleam", 12).
-spec from_start_and_end(birl:time(), birl:time()) -> {ok, interval()} |
    {error, nil}.
from_start_and_end(Start, End) ->
    case birl:compare(Start, End) of
        eq ->
            {error, nil};

        lt ->
            {ok, {interval, Start, End}};

        gt ->
            {ok, {interval, End, Start}}
    end.

-file("src/birl/interval.gleam", 20).
-spec from_start_and_duration(birl:time(), gleam@time@duration:duration()) -> {ok,
        interval()} |
    {error, nil}.
from_start_and_duration(Start, Duration) ->
    from_start_and_end(Start, birl:add(Start, Duration)).

-file("src/birl/interval.gleam", 24).
-spec shift(interval(), gleam@time@duration:duration()) -> interval().
shift(Interval, Duration) ->
    {interval, Start, End} = Interval,
    {interval, birl:add(Start, Duration), birl:add(End, Duration)}.

-file("src/birl/interval.gleam", 29).
-spec scale_up(interval(), integer()) -> interval().
scale_up(Interval, Factor) ->
    {interval, Start, End} = Interval,
    Scaled@1 = case begin
        _pipe = birl:difference(End, Start),
        _pipe@1 = birl@duration:scale_up(_pipe, Factor),
        from_start_and_duration(Start, _pipe@1)
    end of
        {ok, Scaled} -> Scaled;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"birl/interval"/utf8>>,
                        function => <<"scale_up"/utf8>>,
                        line => 31,
                        value => _assert_fail,
                        start => 776,
                        'end' => 905,
                        pattern_start => 787,
                        pattern_end => 797})
    end,
    Scaled@1.

-file("src/birl/interval.gleam", 38).
-spec scale_down(interval(), integer()) -> interval().
scale_down(Interval, Factor) ->
    {interval, Start, End} = Interval,
    Scaled@1 = case begin
        _pipe = birl:difference(End, Start),
        _pipe@1 = birl@duration:scale_down(_pipe, Factor),
        from_start_and_duration(Start, _pipe@1)
    end of
        {ok, Scaled} -> Scaled;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"birl/interval"/utf8>>,
                        function => <<"scale_down"/utf8>>,
                        line => 40,
                        value => _assert_fail,
                        start => 1011,
                        'end' => 1142,
                        pattern_start => 1022,
                        pattern_end => 1032})
    end,
    Scaled@1.

-file("src/birl/interval.gleam", 64).
-spec includes(interval(), birl:time()) -> boolean().
includes(Interval, Time) ->
    {interval, Start, End} = Interval,
    gleam@list:contains([eq, lt], birl:compare(Start, Time)) andalso gleam@list:contains(
        [eq, gt],
        birl:compare(End, Time)
    ).

-file("src/birl/interval.gleam", 70).
-spec contains(interval(), interval()) -> boolean().
contains(A, B) ->
    {interval, Start, End} = B,
    includes(A, Start) andalso includes(A, End).

-file("src/birl/interval.gleam", 47).
-spec intersection(interval(), interval()) -> gleam@option:option(interval()).
intersection(A, B) ->
    case {contains(A, B), contains(B, A)} of
        {true, false} ->
            {some, B};

        {false, true} ->
            {some, A};

        {_, _} ->
            {interval, A_start, A_end} = A,
            {interval, B_start, B_end} = B,
            case {includes(A, B_start), includes(B, A_start)} of
                {true, false} ->
                    {some, {interval, B_start, A_end}};

                {false, true} ->
                    {some, {interval, A_start, B_end}};

                {_, _} ->
                    none
            end
    end.

-file("src/birl/interval.gleam", 75).
-spec get_bounds(interval()) -> {birl:time(), birl:time()}.
get_bounds(Interval) ->
    {interval, Start, End} = Interval,
    {Start, End}.
