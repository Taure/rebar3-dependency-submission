-module(rebar3_dep_config_parser).

-export([direct_deps/1]).

-spec direct_deps(file:filename()) -> [binary()].
direct_deps(ConfigFile) ->
    case file:consult(ConfigFile) of
        {ok, Terms} ->
            extract_dep_names(Terms);
        {error, _} ->
            []
    end.

-spec extract_dep_names(list()) -> [binary()].
extract_dep_names(Terms) ->
    case proplists:get_value(deps, Terms, []) of
        Deps when is_list(Deps) ->
            lists:filtermap(fun dep_name/1, Deps);
        _ ->
            []
    end.

-spec dep_name(term()) -> {true, binary()} | false.
dep_name(Name) when is_atom(Name) ->
    {true, atom_to_binary(Name, utf8)};
dep_name(Tuple) when is_tuple(Tuple), tuple_size(Tuple) >= 2 ->
    case element(1, Tuple) of
        Name when is_atom(Name) ->
            {true, atom_to_binary(Name, utf8)};
        _ ->
            false
    end;
dep_name(_) ->
    false.
