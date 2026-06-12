-module(mistweaver_config_ffi).
-export([get_env/1]).

get_env(Key) ->
    case os:getenv(binary_to_list(Key)) of
        false -> {none};
        Value -> {some, list_to_binary(Value)}
    end.
