-module(birl@duration).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/birl/duration.gleam").
-export([add/2, subtract/2, scale_up/2, scale_down/2, nano_seconds/1, micro_seconds/1, milli_seconds/1, seconds/1, minutes/1, hours/1, days/1, weeks/1, months/1, years/1, compare/2, new/1, accurate_new/1, decompose/1, accurate_decompose/1, blur_to/2, blur/1, parse/1, to_gleam_duration/1, from_gleam_duration/1]).
-export_type([unit/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-type unit() :: nano_second |
    micro_second |
    milli_second |
    second |
    minute |
    hour |
    day |
    week |
    month |
    year.

-file("src/birl/duration.gleam", 27).
-spec add(gleam@time@duration:duration(), gleam@time@duration:duration()) -> gleam@time@duration:duration().
add(A, B) ->
    gleam@time@duration:add(A, B).

-file("src/birl/duration.gleam", 31).
-spec subtract(gleam@time@duration:duration(), gleam@time@duration:duration()) -> gleam@time@duration:duration().
subtract(A, B) ->
    gleam@time@duration:difference(B, A).

-file("src/birl/duration.gleam", 90).
-spec to_nanoseconds(gleam@time@duration:duration()) -> integer().
to_nanoseconds(D) ->
    {Seconds, Nanoseconds} = gleam@time@duration:to_seconds_and_nanoseconds(D),
    (Seconds * 1000000000) + Nanoseconds.

-file("src/birl/duration.gleam", 35).
-spec scale_up(gleam@time@duration:duration(), integer()) -> gleam@time@duration:duration().
scale_up(Value, Factor) ->
    _pipe = to_nanoseconds(Value) * Factor,
    gleam@time@duration:nanoseconds(_pipe).

-file("src/birl/duration.gleam", 40).
-spec scale_down(gleam@time@duration:duration(), integer()) -> gleam@time@duration:duration().
scale_down(Value, Factor) ->
    _pipe = case Factor of
        0 -> 0;
        Gleam@denominator -> to_nanoseconds(Value) div Gleam@denominator
    end,
    gleam@time@duration:nanoseconds(_pipe).

-file("src/birl/duration.gleam", 45).
-spec nano_seconds(integer()) -> gleam@time@duration:duration().
nano_seconds(Value) ->
    gleam@time@duration:nanoseconds(Value).

-file("src/birl/duration.gleam", 49).
-spec micro_seconds(integer()) -> gleam@time@duration:duration().
micro_seconds(Value) ->
    gleam@time@duration:nanoseconds(Value * 1000).

-file("src/birl/duration.gleam", 53).
-spec milli_seconds(integer()) -> gleam@time@duration:duration().
milli_seconds(Value) ->
    gleam@time@duration:nanoseconds(Value * 1000000).

-file("src/birl/duration.gleam", 57).
-spec seconds(integer()) -> gleam@time@duration:duration().
seconds(Value) ->
    gleam@time@duration:seconds(Value).

-file("src/birl/duration.gleam", 61).
-spec minutes(integer()) -> gleam@time@duration:duration().
minutes(Value) ->
    gleam@time@duration:minutes(Value).

-file("src/birl/duration.gleam", 65).
-spec hours(integer()) -> gleam@time@duration:duration().
hours(Value) ->
    gleam@time@duration:hours(Value).

-file("src/birl/duration.gleam", 69).
-spec days(integer()) -> gleam@time@duration:duration().
days(Value) ->
    gleam@time@duration:nanoseconds(Value * 86400000000000).

-file("src/birl/duration.gleam", 73).
-spec weeks(integer()) -> gleam@time@duration:duration().
weeks(Value) ->
    gleam@time@duration:nanoseconds(Value * 604800000000000).

-file("src/birl/duration.gleam", 77).
-spec months(integer()) -> gleam@time@duration:duration().
months(Value) ->
    gleam@time@duration:nanoseconds(Value * 2592000000000000).

-file("src/birl/duration.gleam", 81).
-spec years(integer()) -> gleam@time@duration:duration().
years(Value) ->
    gleam@time@duration:nanoseconds(Value * 31536000000000000).

-file("src/birl/duration.gleam", 85).
-spec compare(gleam@time@duration:duration(), gleam@time@duration:duration()) -> gleam@order:order().
compare(A, B) ->
    gleam@int:compare(to_nanoseconds(A), to_nanoseconds(B)).

-file("src/birl/duration.gleam", 105).
-spec new_with_constants(list({integer(), unit()}), integer(), integer()) -> gleam@time@duration:duration().
new_with_constants(Values, Month_nanos, Year_nanos) ->
    _pipe = Values,
    _pipe@1 = gleam@list:fold(
        _pipe,
        0,
        fun(Total, Current) ->
            {Amount, Unit} = Current,
            Total + (Amount * case Unit of
                nano_second ->
                    1;

                micro_second ->
                    1000;

                milli_second ->
                    1000000;

                second ->
                    1000000000;

                minute ->
                    60000000000;

                hour ->
                    3600000000000;

                day ->
                    86400000000000;

                week ->
                    604800000000000;

                month ->
                    Month_nanos;

                year ->
                    Year_nanos
            end)
        end
    ),
    gleam@time@duration:nanoseconds(_pipe@1).

-file("src/birl/duration.gleam", 96).
?DOC(" use this if you need short durations where a year just means 365 days and a month just means 30 days\n").
-spec new(list({integer(), unit()})) -> gleam@time@duration:duration().
new(Values) ->
    new_with_constants(Values, 2592000000000000, 31536000000000000).

-file("src/birl/duration.gleam", 101).
?DOC(" use this if you need very long durations where small inaccuracies could lead to large errors\n").
-spec accurate_new(list({integer(), unit()})) -> gleam@time@duration:duration().
accurate_new(Values) ->
    new_with_constants(Values, 2629746000000000, 31556952000000000).

-file("src/birl/duration.gleam", 373).
-spec extract(integer(), integer()) -> {integer(), integer()}.
extract(Duration, Unit_value) ->
    {case Unit_value of
            0 -> 0;
            Gleam@denominator -> Duration div Gleam@denominator
        end, case Unit_value of
            0 -> 0;
            Gleam@denominator@1 -> Duration rem Gleam@denominator@1
        end}.

-file("src/birl/duration.gleam", 141).
-spec decompose_with_constants(
    gleam@time@duration:duration(),
    integer(),
    integer()
) -> list({integer(), unit()}).
decompose_with_constants(Duration, Month_nanos, Year_nanos) ->
    Value = to_nanoseconds(Duration),
    Absolute_value = gleam@int:absolute_value(Value),
    {Years, Remaining} = extract(Absolute_value, Year_nanos),
    {Months, Remaining@1} = extract(Remaining, Month_nanos),
    {Weeks, Remaining@2} = extract(Remaining@1, 604800000000000),
    {Days, Remaining@3} = extract(Remaining@2, 86400000000000),
    {Hours, Remaining@4} = extract(Remaining@3, 3600000000000),
    {Minutes, Remaining@5} = extract(Remaining@4, 60000000000),
    {Seconds, Remaining@6} = extract(Remaining@5, 1000000000),
    {Milli_seconds, Remaining@7} = extract(Remaining@6, 1000000),
    {Micro_seconds, Remaining@8} = extract(Remaining@7, 1000),
    _pipe = [{Years, year},
        {Months, month},
        {Weeks, week},
        {Days, day},
        {Hours, hour},
        {Minutes, minute},
        {Seconds, second},
        {Milli_seconds, milli_second},
        {Micro_seconds, micro_second},
        {Remaining@8, nano_second}],
    _pipe@1 = gleam@list:filter(
        _pipe,
        fun(Item) -> erlang:element(1, Item) > 0 end
    ),
    gleam@list:map(_pipe@1, fun(Item@1) -> case Value < 0 of
                true ->
                    {-1 * erlang:element(1, Item@1), erlang:element(2, Item@1)};

                false ->
                    Item@1
            end end).

-file("src/birl/duration.gleam", 132).
?DOC(" use this if you need short durations where a year just means 365 days and a month just means 30 days\n").
-spec decompose(gleam@time@duration:duration()) -> list({integer(), unit()}).
decompose(Duration) ->
    decompose_with_constants(Duration, 2592000000000000, 31536000000000000).

-file("src/birl/duration.gleam", 137).
?DOC(" use this if you need very long durations where small inaccuracies could lead to large errors\n").
-spec accurate_decompose(gleam@time@duration:duration()) -> list({integer(),
    unit()}).
accurate_decompose(Duration) ->
    decompose_with_constants(Duration, 2629746000000000, 31556952000000000).

-file("src/birl/duration.gleam", 225).
-spec unit_values(unit()) -> integer().
unit_values(Unit) ->
    case Unit of
        year ->
            31536000000000000;

        month ->
            2592000000000000;

        week ->
            604800000000000;

        day ->
            86400000000000;

        hour ->
            3600000000000;

        minute ->
            60000000000;

        second ->
            1000000000;

        milli_second ->
            1000000;

        micro_second ->
            1000;

        nano_second ->
            1
    end.

-file("src/birl/duration.gleam", 187).
?DOC(
    " approximates the duration by only the given unit\n"
    " \n"
    " if the duration is not an integer multiple of the unit,\n"
    " the remainder will be disgarded if it's less than two thirds of the unit,\n"
    " otherwise a single unit will be added to the multiplier.\n"
    " \n"
    "   - `blur_to(days(16), Month)` ->  `0`\n"
    "   - `blur_to(days(20), Month)` ->  `1`\n"
).
-spec blur_to(gleam@time@duration:duration(), unit()) -> integer().
blur_to(Duration, Unit) ->
    Unit_value = unit_values(Unit),
    Value = to_nanoseconds(Duration),
    {Unit_counts, Remaining} = extract(Value, Unit_value),
    case Remaining >= ((Unit_value * 2) div 3) of
        true ->
            Unit_counts + 1;

        false ->
            Unit_counts
    end.

-file("src/birl/duration.gleam", 240).
-spec inner_blur(list({integer(), unit()})) -> {integer(), unit()}.
inner_blur(Values) ->
    case Values of
        [] ->
            {0, nano_second};

        [Single] ->
            Single;

        [Smaller, Larger | Rest] ->
            Smaller_unit_value = unit_values(erlang:element(2, Smaller)),
            Larger_unit_value = unit_values(erlang:element(2, Larger)),
            At_least_two_thirds = (erlang:element(1, Smaller) * Smaller_unit_value)
            < ((Larger_unit_value * 2) div 3),
            Rounded = case At_least_two_thirds of
                true ->
                    Larger;

                false ->
                    {erlang:element(1, Larger) + 1, erlang:element(2, Larger)}
            end,
            inner_blur([Rounded | Rest])
    end.

-file("src/birl/duration.gleam", 198).
?DOC(" approximates the duration by a value in a single unit\n").
-spec blur(gleam@time@duration:duration()) -> {integer(), unit()}.
blur(Duration) ->
    _pipe = decompose(Duration),
    _pipe@1 = lists:reverse(_pipe),
    inner_blur(_pipe@1).

-file("src/birl/duration.gleam", 315).
?DOC(
    " you can use this function to create a new duration using expressions like:\n"
    "\n"
    "     \"accurate: 1 Year - 2days + 152M -1h + 25 years + 25secs\"\n"
    "\n"
    " where the units are:\n"
    "\n"
    "     Year:         y, Y, YEAR, years, Years, ...\n"
    "\n"
    "     Month:        mon, Month, mONths, ...\n"
    "\n"
    "     Week:         w, W, Week, weeks, ...\n"
    "\n"
    "     Day:          d, D, day, Days, ...\n"
    "\n"
    "     Hour:         h, H, Hour, Hours, ...\n"
    "\n"
    "     Minute:       m, M, Min, minute, Minutes, ...\n"
    "\n"
    "     Second:       s, S, sec, Secs, second, Seconds, ...\n"
    "\n"
    "     MilliSecond:  ms, Msec, mSecs, milliSecond, MilliSecond, ...\n"
    "\n"
    " numbers with no unit are considered as nanoseconds.\n"
    " specifying `accurate:` is equivalent to using `accurate_new`.\n"
).
-spec parse(binary()) -> {ok, gleam@time@duration:duration()} | {error, nil}.
parse(Expression) ->
    Re@1 = case gleam@regexp:from_string(
        <<"([+|\\-])?\\s*(\\d+)\\s*(\\w+)?"/utf8>>
    ) of
        {ok, Re} -> Re;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"birl/duration"/utf8>>,
                        function => <<"parse"/utf8>>,
                        line => 316,
                        value => _assert_fail,
                        start => 8069,
                        'end' => 8142,
                        pattern_start => 8080,
                        pattern_end => 8086})
    end,
    {Constructor, Expression@3} = case gleam_stdlib:string_starts_with(
        Expression,
        <<"accurate:"/utf8>>
    ) of
        true ->
            Expression@2 = case gleam@string:split(Expression, <<":"/utf8>>) of
                [_, Expression@1] -> Expression@1;
                _assert_fail@1 ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"birl/duration"/utf8>>,
                                function => <<"parse"/utf8>>,
                                line => 322,
                                value => _assert_fail@1,
                                start => 8256,
                                'end' => 8314,
                                pattern_start => 8267,
                                pattern_end => 8282})
            end,
            {fun accurate_new/1, Expression@2};

        false ->
            {fun new/1, Expression}
    end,
    case begin
        _pipe = Expression@3,
        _pipe@1 = string:lowercase(_pipe),
        _pipe@2 = gleam@regexp:scan(Re@1, _pipe@1),
        gleam@list:try_map(_pipe@2, fun(Item) -> case Item of
                    {match, _, [Sign_option, {some, Amount_string}]} ->
                        gleam@result:'try'(
                            gleam_stdlib:parse_int(Amount_string),
                            fun(Amount) -> case Sign_option of
                                    {some, <<"-"/utf8>>} ->
                                        {ok, {-1 * Amount, nano_second}};

                                    none ->
                                        {ok, {Amount, nano_second}};

                                    {some, <<"+"/utf8>>} ->
                                        {ok, {Amount, nano_second}};

                                    {some, _} ->
                                        {error, nil}
                                end end
                        );

                    {match,
                        _,
                        [Sign_option@1, {some, Amount_string@1}, {some, Unit}]} ->
                        gleam@result:'try'(
                            gleam_stdlib:parse_int(Amount_string@1),
                            fun(Amount@1) ->
                                gleam@result:'try'(
                                    gleam@list:find(
                                        [{year,
                                                [<<"y"/utf8>>,
                                                    <<"year"/utf8>>,
                                                    <<"years"/utf8>>]},
                                            {month,
                                                [<<"mon"/utf8>>,
                                                    <<"month"/utf8>>,
                                                    <<"months"/utf8>>]},
                                            {week,
                                                [<<"w"/utf8>>,
                                                    <<"week"/utf8>>,
                                                    <<"weeks"/utf8>>]},
                                            {day,
                                                [<<"d"/utf8>>,
                                                    <<"day"/utf8>>,
                                                    <<"days"/utf8>>]},
                                            {hour,
                                                [<<"h"/utf8>>,
                                                    <<"hour"/utf8>>,
                                                    <<"hours"/utf8>>]},
                                            {minute,
                                                [<<"m"/utf8>>,
                                                    <<"min"/utf8>>,
                                                    <<"minute"/utf8>>,
                                                    <<"minutes"/utf8>>]},
                                            {second,
                                                [<<"s"/utf8>>,
                                                    <<"sec"/utf8>>,
                                                    <<"secs"/utf8>>,
                                                    <<"second"/utf8>>,
                                                    <<"seconds"/utf8>>]},
                                            {milli_second,
                                                [<<"ms"/utf8>>,
                                                    <<"msec"/utf8>>,
                                                    <<"msecs"/utf8>>,
                                                    <<"millisecond"/utf8>>,
                                                    <<"milliseconds"/utf8>>,
                                                    <<"milli-second"/utf8>>,
                                                    <<"milli-seconds"/utf8>>,
                                                    <<"milli_second"/utf8>>,
                                                    <<"milli_seconds"/utf8>>]}],
                                        fun(Item@1) ->
                                            gleam@list:contains(
                                                erlang:element(2, Item@1),
                                                Unit
                                            )
                                        end
                                    ),
                                    fun(_use0) ->
                                        {Unit@1, _} = _use0,
                                        case Sign_option@1 of
                                            {some, <<"-"/utf8>>} ->
                                                {ok, {-1 * Amount@1, Unit@1}};

                                            none ->
                                                {ok, {Amount@1, Unit@1}};

                                            {some, <<"+"/utf8>>} ->
                                                {ok, {Amount@1, Unit@1}};

                                            {some, _} ->
                                                {error, nil}
                                        end
                                    end
                                )
                            end
                        );

                    _ ->
                        {error, nil}
                end end)
    end of
        {ok, Values} ->
            _pipe@3 = Values,
            _pipe@4 = Constructor(_pipe@3),
            {ok, _pipe@4};

        {error, nil} ->
            {error, nil}
    end.

-file("src/birl/duration.gleam", 386).
?DOC(
    " Convert birl Duration to gleam_time Duration.\n"
    "\n"
    " Deprecated: Duration is the same type as gleam_time Duration.\n"
    " This function exists for backward compatibility and is a no-op.\n"
).
-spec to_gleam_duration(gleam@time@duration:duration()) -> gleam@time@duration:duration().
to_gleam_duration(D) ->
    D.

-file("src/birl/duration.gleam", 395).
?DOC(
    " Convert gleam_time Duration to birl Duration.\n"
    "\n"
    " Deprecated: Duration is the same type as gleam_time Duration.\n"
    " This function exists for backward compatibility and is a no-op.\n"
).
-spec from_gleam_duration(gleam@time@duration:duration()) -> gleam@time@duration:duration().
from_gleam_duration(D) ->
    D.
