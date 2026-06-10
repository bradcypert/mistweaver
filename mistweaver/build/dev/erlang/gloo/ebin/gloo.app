{application, gloo, [
    {vsn, "1.0.2"},
    {applications, [birl,
                    gleam_erlang,
                    gleam_otp,
                    gleam_regexp,
                    gleam_stdlib,
                    gleam_time,
                    pog,
                    sqlight]},
    {description, "Small Postgres + SQLite library for Gleam. Query builder for 80% of CRUD, typed raw SQL for the rest."},
    {modules, []},
    {registered, []}
]}.
