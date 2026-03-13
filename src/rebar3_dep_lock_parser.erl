-module(rebar3_dep_lock_parser).

-export([parse/1]).

-type dep_info() :: #{
    name := binary(),
    type := hex | git,
    version => binary(),
    pkg_name => binary(),
    url => binary(),
    ref => binary(),
    level := non_neg_integer()
}.

-export_type([dep_info/0]).

-spec parse(file:filename()) -> {ok, [dep_info()]} | {error, term()}.
parse(LockFile) ->
    case file:consult(LockFile) of
        {ok, Terms} ->
            {ok, parse_terms(Terms)};
        {error, Reason} ->
            {error, Reason}
    end.

-spec parse_terms(list()) -> [dep_info()].
parse_terms([{_Version, Deps} | _Rest]) when is_list(Deps) ->
    %% Modern format: {"1.2.0", [deps...]}.
    lists:filtermap(fun parse_dep/1, Deps);
parse_terms([Deps | _Rest]) when is_list(Deps) ->
    %% Legacy format: [deps...].
    lists:filtermap(fun parse_dep/1, Deps);
parse_terms(_) ->
    [].

-spec parse_dep(tuple()) -> {true, dep_info()} | false.
parse_dep({Name, {pkg, PkgName, Version}, Level}) when
    is_binary(Name), is_binary(PkgName), is_binary(Version), is_integer(Level)
->
    {true, #{
        name => Name,
        type => hex,
        version => Version,
        pkg_name => PkgName,
        level => Level
    }};
parse_dep({Name, {git, Url, {ref, Ref}}, Level}) when
    is_binary(Name), is_integer(Level)
->
    {true, #{
        name => Name,
        type => git,
        url => iolist_to_binary(Url),
        ref => iolist_to_binary(Ref),
        level => Level
    }};
parse_dep(_) ->
    false.
