-module(mistweaver_http_ffi).
-export([post/4]).

post(Url, Headers, ContentType, Body) ->
    application:ensure_all_started(inets),
    application:ensure_all_started(ssl),
    UrlStr = binary_to_list(Url),
    HeadersList = [{binary_to_list(K), binary_to_list(V)} || {K, V} <- Headers],
    ContentTypeStr = binary_to_list(ContentType),
    BodyBin = case is_binary(Body) of
        true -> Body;
        false -> list_to_binary(Body)
    end,
    case httpc:request(post, {UrlStr, HeadersList, ContentTypeStr, BodyBin}, [{ssl, [{verify, verify_peer}, {cacerts, public_key:cacerts_get()}]}], []) of
        {ok, {{_, StatusCode, _}, _RespHeaders, RespBody}} ->
            RespBin = case is_list(RespBody) of
                true -> list_to_binary(RespBody);
                false -> RespBody
            end,
            {ok, {StatusCode, RespBin}};
        {error, Reason} ->
            {error, list_to_binary(io_lib:format("~p", [Reason]))}
    end.
