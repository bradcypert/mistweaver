-module(gloo@migrate).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/gloo/migrate.gleam").
-export([main_with_migrations/2]).
-export_type([command/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    "  Migration CLI entry point.  Call `migrate.main_with_migrations(repo, migrations)`\n"
    "  from your `main` function to expose the `migrate` subcommand.\n"
    "\n"
    "  Subcommands: `up [--step N]`, `down [--step N]`, `status`, `gen <name>`.\n"
).

-type command() :: {migrate_up, gleam@option:option(integer())} |
    {migrate_down, gleam@option:option(integer())} |
    status |
    {gen, binary()}.

-file("src/gloo/migrate.gleam", 115).
-spec gen_migration(list(gloo@migration:migration()), binary()) -> nil.
gen_migration(Existing, Name) ->
    Version = case gleam@list:sort(
        Existing,
        fun(A, B) ->
            gleam@int:compare(erlang:element(2, B), erlang:element(2, A))
        end
    ) of
        [Latest | _] ->
            erlang:element(2, Latest) + 1;

        [] ->
            1
    end,
    Snake_name = begin
        _pipe = string:lowercase(Name),
        gleam@string:replace(_pipe, <<" "/utf8>>, <<"_"/utf8>>)
    end,
    Content = <<<<<<<<"import gloo/migration.{type Migration}\n\npub fn migration() -> Migration {\n  migration.execute_sql(\n    version: "/utf8,
                    (erlang:integer_to_binary(Version))/binary>>/binary,
                ",\n    name: \""/utf8>>/binary,
            Snake_name/binary>>/binary,
        "\",\n    up: \"\"\"\n    -- write your SQL here\n    \"\"\",\n    down: \"-- write your rollback SQL here\",\n  )\n}\n"/utf8>>,
    gleam_stdlib:println(
        <<<<<<"Generated migration "/utf8,
                    (erlang:integer_to_binary(Version))/binary>>/binary,
                "_"/utf8>>/binary,
            Snake_name/binary>>
    ),
    gleam_stdlib:println(<<"Content:"/utf8>>),
    gleam_stdlib:println(Content).

-file("src/gloo/migrate.gleam", 143).
-spec runner_error_msg(gloo@runner:runner_error()) -> binary().
runner_error_msg(E) ->
    case E of
        {db_error, Msg} ->
            Msg;

        {migration_failed, V, N, R} ->
            <<<<<<<<<<"migration "/utf8, (erlang:integer_to_binary(V))/binary>>/binary,
                            " ("/utf8>>/binary,
                        N/binary>>/binary,
                    "): "/utf8>>/binary,
                R/binary>>
    end.

-file("src/gloo/migrate.gleam", 69).
-spec run_command(gloo@repo:repo(), list(gloo@migration:migration()), command()) -> nil.
run_command(R, Migrations, Cmd) ->
    case Cmd of
        {migrate_up, Step} ->
            case gloo@runner:run(R, Migrations, up, Step) of
                {ok, 0} ->
                    gleam_stdlib:println(<<"Already up to date."/utf8>>);

                {ok, N} ->
                    gleam_stdlib:println(
                        <<<<"Applied "/utf8,
                                (erlang:integer_to_binary(N))/binary>>/binary,
                            " migration(s)."/utf8>>
                    );

                {error, E} ->
                    gleam_stdlib:println(
                        <<"Migration failed: "/utf8,
                            (runner_error_msg(E))/binary>>
                    )
            end;

        {migrate_down, Step@1} ->
            Effective_step = gleam@option:unwrap(Step@1, 1),
            case gloo@runner:run(R, Migrations, down, {some, Effective_step}) of
                {ok, 0} ->
                    gleam_stdlib:println(<<"Nothing to roll back."/utf8>>);

                {ok, N@1} ->
                    gleam_stdlib:println(
                        <<<<"Rolled back "/utf8,
                                (erlang:integer_to_binary(N@1))/binary>>/binary,
                            " migration(s)."/utf8>>
                    );

                {error, E@1} ->
                    gleam_stdlib:println(
                        <<"Rollback failed: "/utf8,
                            (runner_error_msg(E@1))/binary>>
                    )
            end;

        status ->
            case gloo@runner:applied_versions(R) of
                {error, E@2} ->
                    gleam_stdlib:println(
                        <<"Error: "/utf8, (runner_error_msg(E@2))/binary>>
                    );

                {ok, Applied} ->
                    gleam_stdlib:println(<<"Migration status:"/utf8>>),
                    gleam@list:each(
                        Migrations,
                        fun(M) ->
                            Mark = case gleam@list:contains(
                                Applied,
                                erlang:element(2, M)
                            ) of
                                true ->
                                    <<"[x]"/utf8>>;

                                false ->
                                    <<"[ ]"/utf8>>
                            end,
                            gleam_stdlib:println(
                                <<<<<<<<Mark/binary, " "/utf8>>/binary,
                                            (erlang:integer_to_binary(
                                                erlang:element(2, M)
                                            ))/binary>>/binary,
                                        " "/utf8>>/binary,
                                    (erlang:element(3, M))/binary>>
                            )
                        end
                    )
            end;

        {gen, Name} ->
            gen_migration(Migrations, Name)
    end.

-file("src/gloo/migrate.gleam", 139).
-spec usage() -> binary().
usage() ->
    <<"Usage: gleam run -m <module> -- migrate <command>\n  up [--step N]    apply pending migrations\n  down [--step N]  roll back migrations (default: 1)\n  status           show migration status\n  gen <name>       generate a new migration"/utf8>>.

-file("src/gloo/migrate.gleam", 56).
-spec parse_step(list(binary())) -> gleam@option:option(integer()).
parse_step(Args) ->
    case Args of
        [<<"--step"/utf8>>, N | _] ->
            case gleam_stdlib:parse_int(N) of
                {ok, V} ->
                    {some, V};

                {error, _} ->
                    none
            end;

        _ ->
            none
    end.

-file("src/gloo/migrate.gleam", 46).
-spec parse_args(list(binary())) -> {ok, command()} | {error, binary()}.
parse_args(Args) ->
    case Args of
        [<<"migrate"/utf8>>, <<"up"/utf8>> | Rest] ->
            {ok, {migrate_up, parse_step(Rest)}};

        [<<"migrate"/utf8>>, <<"down"/utf8>> | Rest@1] ->
            {ok, {migrate_down, parse_step(Rest@1)}};

        [<<"migrate"/utf8>>, <<"status"/utf8>>] ->
            {ok, status};

        [<<"migrate"/utf8>>, <<"gen"/utf8>>, Name] ->
            {ok, {gen, Name}};

        _ ->
            {error, <<"unknown command"/utf8>>}
    end.

-file("src/gloo/migrate.gleam", 24).
?DOC(
    " Entry point for the migration CLI.\n"
    " Call this from your app's main function, passing the Repo and your migration list.\n"
    "\n"
    " Usage:\n"
    "   gleam run -m myapp/db -- migrate up\n"
    "   gleam run -m myapp/db -- migrate up --step 2\n"
    "   gleam run -m myapp/db -- migrate down --step 1\n"
    "   gleam run -m myapp/db -- migrate status\n"
    "   gleam run -m myapp/db -- migrate gen create_posts\n"
).
-spec main_with_migrations(gloo@repo:repo(), list(gloo@migration:migration())) -> nil.
main_with_migrations(R, Migrations) ->
    Args = migrate_ffi:start_arguments(),
    case parse_args(Args) of
        {error, Msg} ->
            gleam_stdlib:println(<<"Error: "/utf8, Msg/binary>>),
            gleam_stdlib:println(usage());

        {ok, Cmd} ->
            run_command(R, Migrations, Cmd)
    end.
