-module(migrate_ffi).
-export([start_arguments/0]).

start_arguments() ->
    [list_to_binary(A) || A <- init:get_plain_arguments()].
