-module(rebar3_dep_snapshot).

-export([build_manifests/3, build_snapshot/5]).

-spec build_manifests(string(), [rebar3_dep_lock_parser:dep_info()], [binary()]) -> map().
build_manifests(LockFile, LockDeps, DirectDeps) ->
    Resolved = maps:from_list(
        lists:map(
            fun(Dep) -> dep_to_resolved(Dep, DirectDeps) end,
            LockDeps
        )
    ),
    LockFileBin = iolist_to_binary(LockFile),
    #{
        LockFileBin => #{
            <<"name">> => LockFileBin,
            <<"file">> => #{
                <<"source_location">> => iolist_to_binary(LockFile)
            },
            <<"resolved">> => Resolved
        }
    }.

-spec build_snapshot(string(), string(), string(), string(), map()) -> map().
build_snapshot(Sha, Ref, JobId, Correlator, Manifests) ->
    #{
        <<"version">> => 0,
        <<"sha">> => iolist_to_binary(Sha),
        <<"ref">> => iolist_to_binary(Ref),
        <<"job">> => #{
            <<"id">> => iolist_to_binary(JobId),
            <<"correlator">> => iolist_to_binary(Correlator)
        },
        <<"detector">> => #{
            <<"name">> => <<"rebar3-dependency-submission">>,
            <<"version">> => version(),
            <<"url">> =>
                <<"https://github.com/Taure/rebar3-dependency-submission">>
        },
        <<"scanned">> => iso8601_now(),
        <<"manifests">> => Manifests
    }.

-spec dep_to_resolved(rebar3_dep_lock_parser:dep_info(), [binary()]) ->
    {binary(), map()}.
dep_to_resolved(#{name := Name, type := hex, version := Version} = Dep, DirectDeps) ->
    PkgName = maps:get(pkg_name, Dep, Name),
    Purl = iolist_to_binary([<<"pkg:hex/">>, PkgName, <<"@">>, Version]),
    Level = maps:get(level, Dep, 0),
    Relationship = relationship(Name, Level, DirectDeps),
    {Name, #{
        <<"package_url">> => Purl,
        <<"relationship">> => Relationship,
        <<"scope">> => <<"runtime">>
    }};
dep_to_resolved(#{name := Name, type := git, url := Url} = Dep, DirectDeps) ->
    Ref = maps:get(ref, Dep, <<>>),
    Purl = git_purl(Url, Ref),
    Level = maps:get(level, Dep, 0),
    Relationship = relationship(Name, Level, DirectDeps),
    {Name, #{
        <<"package_url">> => Purl,
        <<"relationship">> => Relationship,
        <<"scope">> => <<"runtime">>
    }}.

-spec relationship(binary(), non_neg_integer(), [binary()]) -> binary().
relationship(Name, Level, DirectDeps) ->
    case Level =:= 0 orelse lists:member(Name, DirectDeps) of
        true -> <<"direct">>;
        false -> <<"indirect">>
    end.

-spec git_purl(binary(), binary()) -> binary().
git_purl(Url, Ref) ->
    case parse_github_url(Url) of
        {ok, Owner, Repo} ->
            Base = iolist_to_binary([<<"pkg:github/">>, Owner, <<"/">>, Repo]),
            case Ref of
                <<>> -> Base;
                _ -> iolist_to_binary([Base, <<"@">>, Ref])
            end;
        error ->
            iolist_to_binary([<<"pkg:generic/">>, Url])
    end.

-spec parse_github_url(binary()) -> {ok, binary(), binary()} | error.
parse_github_url(Url) ->
    UrlStr = binary_to_list(Url),
    Patterns = [
        "https?://github\\.com/([^/]+)/([^/.]+)",
        "git@github\\.com:([^/]+)/([^/.]+)",
        "git://github\\.com/([^/]+)/([^/.]+)"
    ],
    parse_github_url(UrlStr, Patterns).

parse_github_url(_Url, []) ->
    error;
parse_github_url(Url, [Pattern | Rest]) ->
    case re:run(Url, Pattern, [{capture, [1, 2], list}]) of
        {match, [Owner, Repo]} ->
            {ok, list_to_binary(Owner), list_to_binary(Repo)};
        nomatch ->
            parse_github_url(Url, Rest)
    end.

-spec iso8601_now() -> binary().
iso8601_now() ->
    {{Y, Mo, D}, {H, Mi, S}} = calendar:universal_time(),
    iolist_to_binary(
        io_lib:format("~4..0B-~2..0B-~2..0BT~2..0B:~2..0B:~2..0BZ", [Y, Mo, D, H, Mi, S])
    ).

-spec version() -> binary().
version() ->
    case application:get_key(rebar3_dependency_submission, vsn) of
        {ok, Vsn} -> iolist_to_binary(Vsn);
        undefined -> <<"dev">>
    end.
