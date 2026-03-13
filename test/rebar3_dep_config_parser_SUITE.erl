-module(rebar3_dep_config_parser_SUITE).

-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").

-export([all/0, groups/0]).
-export([
    parse_direct_deps/1,
    parse_missing_config/1
]).

all() -> [{group, parsing}].

groups() ->
    [
        {parsing, [parallel], [
            parse_direct_deps,
            parse_missing_config
        ]}
    ].

parse_direct_deps(Config) ->
    DataDir = ?config(data_dir, Config),
    ConfigFile = filename:join(DataDir, "rebar.config"),
    Deps = rebar3_dep_config_parser:direct_deps(ConfigFile),
    ?assertEqual(3, length(Deps)),
    ?assert(lists:member(<<"cowboy">>, Deps)),
    ?assert(lists:member(<<"nova">>, Deps)),
    ?assert(lists:member(<<"thoas">>, Deps)).

parse_missing_config(_Config) ->
    Deps = rebar3_dep_config_parser:direct_deps("nonexistent.config"),
    ?assertEqual([], Deps).
