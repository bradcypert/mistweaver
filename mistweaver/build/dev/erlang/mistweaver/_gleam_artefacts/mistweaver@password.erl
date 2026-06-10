-module(mistweaver@password).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/mistweaver/password.gleam").
-export([hash/1, verify/2]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-file("src/mistweaver/password.gleam", 7).
?DOC(
    " Hash a password using PBKDF2-SHA256 with 100,000 iterations.\n"
    " Returns a self-describing string: \"pbkdf2$<hex_salt>$<hex_hash>\"\n"
).
-spec hash(binary()) -> binary().
hash(Password) ->
    Salt = crypto:strong_rand_bytes(16),
    Hash = mistweaver_password_ffi:pbkdf2_hash(
        <<Password/binary>>,
        Salt,
        100000,
        32
    ),
    <<<<<<"pbkdf2$"/utf8, (gleam_stdlib:base16_encode(Salt))/binary>>/binary,
            "$"/utf8>>/binary,
        (gleam_stdlib:base16_encode(Hash))/binary>>.

-file("src/mistweaver/password.gleam", 17).
?DOC(" Verify a plaintext password against a value produced by `hash/1`.\n").
-spec verify(binary(), binary()) -> boolean().
verify(Password, Stored) ->
    case gleam@string:split(Stored, <<"$"/utf8>>) of
        [<<"pbkdf2"/utf8>>, Salt_hex, Stored_hash_hex] ->
            case gleam_stdlib:base16_decode(Salt_hex) of
                {ok, Salt} ->
                    Computed = mistweaver_password_ffi:pbkdf2_hash(
                        <<Password/binary>>,
                        Salt,
                        100000,
                        32
                    ),
                    Computed_hex = gleam_stdlib:base16_encode(Computed),
                    gleam@crypto:secure_compare(
                        <<Computed_hex/binary>>,
                        <<Stored_hash_hex/binary>>
                    );

                {error, _} ->
                    false
            end;

        _ ->
            false
    end.
