-module(rebar3_dep_lock_parser_SUITE).

-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").

-export([all/0, groups/0]).
-export([
    parse_modern_lock/1,
    parse_legacy_lock/1,
    parse_missing_file/1,
    parse_hex_deps/1,
    parse_git_deps/1
]).

all() -> [{group, parsing}].

groups() ->
    [
        {parsing, [parallel], [
            parse_modern_lock,
            parse_legacy_lock,
            parse_missing_file,
            parse_hex_deps,
            parse_git_deps
        ]}
    ].

parse_modern_lock(Config) ->
    DataDir = ?config(data_dir, Config),
    LockFile = filename:join(DataDir, "rebar.lock"),
    {ok, Deps} = rebar3_dep_lock_parser:parse(LockFile),
    ?assertEqual(5, length(Deps)).

parse_legacy_lock(Config) ->
    DataDir = ?config(data_dir, Config),
    LockFile = filename:join(DataDir, "legacy.lock"),
    {ok, Deps} = rebar3_dep_lock_parser:parse(LockFile),
    ?assertEqual(2, length(Deps)),
    [Cowboy | _] = Deps,
    ?assertEqual(<<"cowboy">>, maps:get(name, Cowboy)),
    ?assertEqual(<<"2.10.0">>, maps:get(version, Cowboy)).

parse_missing_file(_Config) ->
    {error, _} = rebar3_dep_lock_parser:parse("nonexistent.lock").

parse_hex_deps(Config) ->
    DataDir = ?config(data_dir, Config),
    LockFile = filename:join(DataDir, "rebar.lock"),
    {ok, Deps} = rebar3_dep_lock_parser:parse(LockFile),
    HexDeps = [D || D = #{type := hex} <- Deps],
    ?assertEqual(4, length(HexDeps)),
    Cowboy = hd([D || D = #{name := <<"cowboy">>} <- HexDeps]),
    ?assertEqual(<<"2.13.0">>, maps:get(version, Cowboy)),
    ?assertEqual(<<"cowboy">>, maps:get(pkg_name, Cowboy)),
    ?assertEqual(0, maps:get(level, Cowboy)).

parse_git_deps(Config) ->
    DataDir = ?config(data_dir, Config),
    LockFile = filename:join(DataDir, "rebar.lock"),
    {ok, Deps} = rebar3_dep_lock_parser:parse(LockFile),
    GitDeps = [D || D = #{type := git} <- Deps],
    ?assertEqual(1, length(GitDeps)),
    Nova = hd(GitDeps),
    ?assertEqual(<<"nova">>, maps:get(name, Nova)),
    ?assertEqual(<<"abc123def456">>, maps:get(ref, Nova)),
    ?assertEqual(0, maps:get(level, Nova)).
