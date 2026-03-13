# rebar3 Dependency Submission

A GitHub Action that submits your rebar3 project dependencies to the [GitHub Dependency Graph](https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/about-the-dependency-graph), enabling **Dependabot alerts** and **security advisories** for Erlang/OTP projects.

GitHub's Advisory Database already includes [Erlang/Hex advisories](https://github.com/advisories?query=ecosystem%3Aerlang), but without a dependency submission action, rebar3 projects couldn't benefit from them — until now.

## Quick Start

Add this workflow to your repository at `.github/workflows/dependency-submission.yml`:

```yaml
name: Dependency Submission

on:
  push:
    branches: [main, master]

permissions:
  contents: write

jobs:
  dependency-submission:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          otp-version: '27'
          rebar3-version: '3.24'
      - uses: Taure/rebar3-dependency-submission@main
```

That's it. Once the workflow runs, your dependencies will appear in the repository's **Insights > Dependency graph** tab, and you'll receive Dependabot alerts for known vulnerabilities.

## Inputs

| Input | Description | Default |
|---|---|---|
| `lock-file` | Path to `rebar.lock` | `rebar.lock` |
| `config-file` | Path to `rebar.config` | `rebar.config` |
| `token` | GitHub token for API access | `${{ github.token }}` |

## Outputs

| Output | Description |
|---|---|
| `snapshot-id` | ID of the submitted dependency snapshot |

## How It Works

1. Parses `rebar.lock` using Erlang's `file:consult/1` to extract all locked dependencies
2. Reads `rebar.config` to determine which dependencies are direct vs transitive
3. Converts each dependency to a [Package URL (purl)](https://github.com/package-url/purl-spec):
   - Hex packages: `pkg:hex/cowboy@2.13.0`
   - GitHub git deps: `pkg:github/owner/repo@ref`
   - Other git deps: `pkg:generic/url`
4. Submits a dependency snapshot to the [GitHub Dependency Submission API](https://docs.github.com/en/rest/dependency-graph/dependency-submission)

## Supported Dependency Types

### Hex packages

```erlang
{deps, [
    cowboy,                          %% Latest version
    {cowboy, "2.13.0"},              %% Pinned version
    {cowboy, {pkg, cowboy_fork}}     %% Alternate package name
]}.
```

### Git dependencies

```erlang
{deps, [
    {nova, {git, "https://github.com/novaframework/nova.git", {tag, "0.9.0"}}},
    {mylib, {git, "https://gitlab.com/org/mylib.git", {ref, "abc123"}}}
]}.
```

### Lock file formats

Both modern (`rebar3 >= 3.7`) and legacy lock file formats are supported:

```erlang
%% Modern format
{"1.2.0",
 [{<<"cowboy">>, {pkg, <<"cowboy">>, <<"2.13.0">>}, 0}]}.

%% Legacy format
[{<<"cowboy">>, {pkg, <<"cowboy">>, <<"2.13.0">>}, 0}].
```

## Dependency Relationships

Dependencies are classified as **direct** or **indirect** (transitive) based on:

- The `level` field in `rebar.lock` — level `0` means direct
- Cross-reference with `rebar.config` deps list

This information is visible in the GitHub dependency graph and affects how vulnerability alerts are prioritized.

## Requirements

- **OTP 27+** — Uses the built-in `json` module (no external dependencies)
- **rebar3** — For building the escript
- Erlang and rebar3 must be available on the runner (use [erlef/setup-beam](https://github.com/erlef/setup-beam))

## Architecture

The action is a pure Erlang escript with zero external dependencies. It consists of four modules:

| Module | Purpose |
|---|---|
| `rebar3_dependency_submission` | CLI entry point, argument parsing |
| `rebar3_dep_lock_parser` | Parses `rebar.lock` via `file:consult/1` |
| `rebar3_dep_config_parser` | Extracts direct deps from `rebar.config` |
| `rebar3_dep_snapshot` | Builds the dependency graph snapshot |
| `rebar3_dep_api` | Submits the snapshot to GitHub's API |

## Development

### Running tests

```bash
rebar3 ct
```

### Full quality pipeline

```bash
rebar3 fmt --check
rebar3 xref
rebar3 dialyzer
rebar3 ct
```

## Why This Matters for Erlang/OTP

The Erlang ecosystem has lacked integration with GitHub's supply chain security features. While Elixir projects have had [mix dependency submission](https://github.com/marketplace/actions/mix-dependency-submission) for some time, rebar3 projects have been left without:

- **Vulnerability alerts** — No notifications when a dependency has a known CVE
- **Dependency graph visibility** — No way to see the full dependency tree on GitHub
- **Security policy compliance** — Organizations using GitHub's security features couldn't include Erlang projects

This action closes that gap, bringing rebar3 projects on par with other ecosystems supported by GitHub's dependency graph.

## License

MIT — see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
