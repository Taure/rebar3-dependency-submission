-module(rebar3_dep_snapshot_SUITE).

-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").

-export([all/0, groups/0]).
-export([
    build_manifests_hex/1,
    build_manifests_git/1,
    build_manifests_indirect/1,
    build_snapshot_structure/1,
    github_purl/1,
    non_github_purl/1
]).

all() -> [{group, snapshot}].

groups() ->
    [
        {snapshot, [parallel], [
            build_manifests_hex,
            build_manifests_git,
            build_manifests_indirect,
            build_snapshot_structure,
            github_purl,
            non_github_purl
        ]}
    ].

build_manifests_hex(_Config) ->
    Deps = [
        #{
            name => <<"cowboy">>,
            type => hex,
            version => <<"2.13.0">>,
            pkg_name => <<"cowboy">>,
            level => 0
        }
    ],
    DirectDeps = [<<"cowboy">>],
    Manifests = rebar3_dep_snapshot:build_manifests("rebar.lock", Deps, DirectDeps),
    ?assertMatch(#{<<"rebar.lock">> := _}, Manifests),
    #{<<"resolved">> := Resolved} = maps:get(<<"rebar.lock">>, Manifests),
    #{<<"package_url">> := Purl, <<"relationship">> := Rel} = maps:get(<<"cowboy">>, Resolved),
    ?assertEqual(<<"pkg:hex/cowboy@2.13.0">>, Purl),
    ?assertEqual(<<"direct">>, Rel).

build_manifests_git(_Config) ->
    Deps = [
        #{
            name => <<"nova">>,
            type => git,
            url => <<"https://github.com/novaframework/nova.git">>,
            ref => <<"abc123">>,
            level => 0
        }
    ],
    DirectDeps = [<<"nova">>],
    Manifests = rebar3_dep_snapshot:build_manifests("rebar.lock", Deps, DirectDeps),
    #{<<"resolved">> := Resolved} = maps:get(<<"rebar.lock">>, Manifests),
    #{<<"package_url">> := Purl} = maps:get(<<"nova">>, Resolved),
    ?assertEqual(<<"pkg:github/novaframework/nova@abc123">>, Purl).

build_manifests_indirect(_Config) ->
    Deps = [
        #{
            name => <<"cowlib">>,
            type => hex,
            version => <<"2.13.0">>,
            pkg_name => <<"cowlib">>,
            level => 1
        }
    ],
    DirectDeps = [<<"cowboy">>],
    Manifests = rebar3_dep_snapshot:build_manifests("rebar.lock", Deps, DirectDeps),
    #{<<"resolved">> := Resolved} = maps:get(<<"rebar.lock">>, Manifests),
    #{<<"relationship">> := Rel} = maps:get(<<"cowlib">>, Resolved),
    ?assertEqual(<<"indirect">>, Rel).

build_snapshot_structure(_Config) ->
    Manifests = #{},
    Snapshot = rebar3_dep_snapshot:build_snapshot(
        "abc123", "refs/heads/main", "12345", "workflow job", Manifests
    ),
    ?assertEqual(0, maps:get(<<"version">>, Snapshot)),
    ?assertEqual(<<"abc123">>, maps:get(<<"sha">>, Snapshot)),
    ?assertEqual(<<"refs/heads/main">>, maps:get(<<"ref">>, Snapshot)),
    Job = maps:get(<<"job">>, Snapshot),
    ?assertEqual(<<"12345">>, maps:get(<<"id">>, Job)),
    ?assertEqual(<<"workflow job">>, maps:get(<<"correlator">>, Job)),
    Detector = maps:get(<<"detector">>, Snapshot),
    ?assertEqual(<<"rebar3-dependency-submission">>, maps:get(<<"name">>, Detector)),
    ?assertMatch(#{<<"scanned">> := _}, Snapshot).

github_purl(_Config) ->
    Deps = [
        #{
            name => <<"nova">>,
            type => git,
            url => <<"git://github.com/novaframework/nova.git">>,
            ref => <<"def456">>,
            level => 0
        }
    ],
    Manifests = rebar3_dep_snapshot:build_manifests("rebar.lock", Deps, [<<"nova">>]),
    #{<<"resolved">> := Resolved} = maps:get(<<"rebar.lock">>, Manifests),
    #{<<"package_url">> := Purl} = maps:get(<<"nova">>, Resolved),
    ?assertEqual(<<"pkg:github/novaframework/nova@def456">>, Purl).

non_github_purl(_Config) ->
    Deps = [
        #{
            name => <<"mylib">>,
            type => git,
            url => <<"https://gitlab.com/org/mylib.git">>,
            ref => <<"aaa111">>,
            level => 0
        }
    ],
    Manifests = rebar3_dep_snapshot:build_manifests("rebar.lock", Deps, [<<"mylib">>]),
    #{<<"resolved">> := Resolved} = maps:get(<<"rebar.lock">>, Manifests),
    #{<<"package_url">> := Purl} = maps:get(<<"mylib">>, Resolved),
    ?assertEqual(<<"pkg:generic/https://gitlab.com/org/mylib.git">>, Purl).
