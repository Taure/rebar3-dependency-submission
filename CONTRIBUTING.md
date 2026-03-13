# Contributing

Thanks for your interest in contributing to rebar3 Dependency Submission!

## Getting Started

1. Fork the repository
2. Clone your fork
3. Make sure you have OTP 27+ and rebar3 installed (we recommend [mise](https://mise.jdx.dev/) or [erlef/setup-beam](https://github.com/erlef/setup-beam))
4. Run `rebar3 ct` to verify tests pass

## Making Changes

### Code Style

- Format code with `rebar3 fmt` before committing
- Follow idiomatic Erlang/OTP patterns
- Keep modules focused — one responsibility per module

### Testing

All changes should include tests. We use Common Test:

```bash
rebar3 ct
```

The test suites cover:

- **`rebar3_dep_lock_parser_SUITE`** — Lock file parsing (modern, legacy, hex, git)
- **`rebar3_dep_config_parser_SUITE`** — Config file parsing for direct dependencies
- **`rebar3_dep_snapshot_SUITE`** — Snapshot building, purl generation, relationship classification

### Quality Checks

Before submitting a PR, run the full pipeline:

```bash
rebar3 fmt --check   # Formatting
rebar3 xref          # Cross-reference analysis
rebar3 dialyzer      # Type checking
rebar3 ct            # Tests
```

## Pull Requests

- Use [conventional commits](https://www.conventionalcommits.org/) (e.g. `feat:`, `fix:`, `docs:`)
- Keep PRs focused on a single change
- Include a description of what the change does and why

## Adding Support for New Dependency Types

If rebar3 gains new dependency source types, you'll need to update:

1. **`rebar3_dep_lock_parser.erl`** — Add a `parse_dep/1` clause for the new lock entry format
2. **`rebar3_dep_snapshot.erl`** — Add a `dep_to_resolved/2` clause with the appropriate purl scheme
3. **Test suites** — Add test cases covering the new type

### Package URL (purl) Guidelines

We follow the [purl spec](https://github.com/package-url/purl-spec):

- Hex packages: `pkg:hex/<name>@<version>`
- GitHub repos: `pkg:github/<owner>/<repo>@<ref>`
- Other git repos: `pkg:generic/<url>`

If a new purl type is registered that fits (e.g., GitLab, Bitbucket), prefer the specific type over `pkg:generic`.

## Reporting Issues

Please open a GitHub issue with:

- Your OTP and rebar3 versions
- The error message or unexpected behavior
- A minimal `rebar.config` / `rebar.lock` that reproduces the issue (if applicable)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
