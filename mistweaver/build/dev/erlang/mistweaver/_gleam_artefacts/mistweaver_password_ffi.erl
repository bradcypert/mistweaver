-module(mistweaver_password_ffi).
-export([pbkdf2_hash/4]).

pbkdf2_hash(Password, Salt, Iterations, KeyLength) ->
    crypto:pbkdf2_hmac(sha256, Password, Salt, Iterations, KeyLength).
