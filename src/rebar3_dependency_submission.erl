-module(rebar3_dependency_submission).

-export([main/1]).

main(Args) ->
    application:ensure_all_started(inets),
    application:ensure_all_started(ssl),
    Opts = parse_args(Args),
    LockFile = maps:get(lock_file, Opts, "rebar.lock"),
    ConfigFile = maps:get(config_file, Opts, "rebar.config"),
    Token = get_token(Opts),
    {Owner, Repo} = get_repo(Opts),
    Sha = get_sha(Opts),
    Ref = get_ref(Opts),
    JobId = get_job_id(Opts),
    Correlator = get_correlator(Opts),

    case rebar3_dep_lock_parser:parse(LockFile) of
        {ok, LockDeps} ->
            DirectDeps = rebar3_dep_config_parser:direct_deps(ConfigFile),
            Manifests = rebar3_dep_snapshot:build_manifests(
                LockFile, LockDeps, DirectDeps
            ),
            Snapshot = rebar3_dep_snapshot:build_snapshot(
                Sha, Ref, JobId, Correlator, Manifests
            ),
            case rebar3_dep_api:submit(Owner, Repo, Token, Snapshot) of
                {ok, SnapshotId} ->
                    io:format("Snapshot submitted successfully. ID: ~s~n", [SnapshotId]),
                    write_github_output("snapshot-id", SnapshotId);
                {error, Reason} ->
                    io:format(standard_error, "Failed to submit snapshot: ~p~n", [Reason]),
                    halt(1)
            end;
        {error, Reason} ->
            io:format(standard_error, "Failed to parse ~s: ~p~n", [LockFile, Reason]),
            halt(1)
    end.

parse_args(Args) ->
    parse_args(Args, #{}).

parse_args([], Acc) ->
    Acc;
parse_args(["--lock-file", File | Rest], Acc) ->
    parse_args(Rest, Acc#{lock_file => File});
parse_args(["--config-file", File | Rest], Acc) ->
    parse_args(Rest, Acc#{config_file => File});
parse_args(["--token", Token | Rest], Acc) ->
    parse_args(Rest, Acc#{token => Token});
parse_args(["--repo", Repo | Rest], Acc) ->
    parse_args(Rest, Acc#{repo => Repo});
parse_args(["--sha", Sha | Rest], Acc) ->
    parse_args(Rest, Acc#{sha => Sha});
parse_args(["--ref", Ref | Rest], Acc) ->
    parse_args(Rest, Acc#{ref => Ref});
parse_args(["--job-id", Id | Rest], Acc) ->
    parse_args(Rest, Acc#{job_id => Id});
parse_args(["--correlator", C | Rest], Acc) ->
    parse_args(Rest, Acc#{correlator => C});
parse_args([_ | Rest], Acc) ->
    parse_args(Rest, Acc).

get_token(Opts) ->
    case maps:find(token, Opts) of
        {ok, T} -> T;
        error -> os:getenv("GITHUB_TOKEN", "")
    end.

get_repo(Opts) ->
    RepoStr =
        case maps:find(repo, Opts) of
            {ok, R} -> R;
            error -> os:getenv("GITHUB_REPOSITORY", "")
        end,
    case string:split(RepoStr, "/") of
        [Owner, Repo] -> {Owner, Repo};
        _ -> {RepoStr, ""}
    end.

get_sha(Opts) ->
    case maps:find(sha, Opts) of
        {ok, S} -> S;
        error -> os:getenv("GITHUB_SHA", "")
    end.

get_ref(Opts) ->
    case maps:find(ref, Opts) of
        {ok, R} -> R;
        error -> os:getenv("GITHUB_REF", "")
    end.

get_job_id(Opts) ->
    case maps:find(job_id, Opts) of
        {ok, Id} -> Id;
        error -> os:getenv("GITHUB_RUN_ID", "")
    end.

get_correlator(Opts) ->
    case maps:find(correlator, Opts) of
        {ok, C} ->
            C;
        error ->
            Workflow = os:getenv("GITHUB_WORKFLOW", ""),
            Job = os:getenv("GITHUB_JOB", ""),
            Workflow ++ " " ++ Job
    end.

write_github_output(Key, Value) ->
    case os:getenv("GITHUB_OUTPUT") of
        false ->
            ok;
        File ->
            case file:open(File, [append]) of
                {ok, Fd} ->
                    io:format(Fd, "~s=~s~n", [Key, Value]),
                    file:close(Fd);
                _ ->
                    ok
            end
    end.
