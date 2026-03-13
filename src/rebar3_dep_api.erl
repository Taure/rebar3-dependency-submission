-module(rebar3_dep_api).

-export([submit/4]).

-define(API_BASE, "https://api.github.com").
-define(API_VERSION, "2022-11-28").

-spec submit(string(), string(), string(), map()) -> {ok, string()} | {error, term()}.
submit(Owner, Repo, Token, Snapshot) ->
    Url =
        ?API_BASE ++ "/repos/" ++ Owner ++ "/" ++ Repo ++
            "/dependency-graph/snapshots",
    Body = json:encode(Snapshot),
    Headers = [
        {"Authorization", "Bearer " ++ Token},
        {"Accept", "application/vnd.github+json"},
        {"X-GitHub-Api-Version", ?API_VERSION},
        {"Content-Type", "application/json"},
        {"User-Agent", "rebar3-dependency-submission"}
    ],
    Request = {Url, Headers, "application/json", Body},
    case httpc:request(post, Request, [{ssl, ssl_opts()}], [{body_format, binary}]) of
        {ok, {{_, 201, _}, _RespHeaders, RespBody}} ->
            case json:decode(RespBody) of
                #{<<"id">> := Id} ->
                    {ok, integer_to_list(Id)};
                _ ->
                    {ok, "unknown"}
            end;
        {ok, {{_, StatusCode, _}, _RespHeaders, RespBody}} ->
            {error, {http_error, StatusCode, RespBody}};
        {error, Reason} ->
            {error, Reason}
    end.

-spec ssl_opts() -> list().
ssl_opts() ->
    CACerts = public_key:cacerts_get(),
    [
        {verify, verify_peer},
        {cacerts, CACerts},
        {depth, 3}
    ].
