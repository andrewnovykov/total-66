# Tech Stack Specification

## Runtime & Language

| Layer    | Choice        | Version  |
| -------- | ------------- | -------- |
| Runtime  | Erlang/OTP | Aligned with Elixir 1.14 runtime requirements |
| Language | Elixir | ~> 1.14 |

## Framework & Libraries

| Layer     | Choice             | Version  | Purpose                    |
| --------- | ------------------ | -------- | -------------------------- |
| Web Framework  | Phoenix    | ~> 1.7.14 | MVC + real-time web framework |
| UI Framework   | Phoenix LiveView | ~> 1.0.0 | Server-rendered, real-time UI |
| ORM / DB Layer | Ecto SQL | ~> 3.10 | Database access and queries |
| DB Adapter     | Postgrex | >= 0.0.0 | PostgreSQL driver |
| Auth / Security | bcrypt_elixir | ~> 3.0 | Password hashing |
| Email | Swoosh + Finch | ~> 1.5 / ~> 0.13 | Email delivery and HTTP client |
| I18n | Gettext | ~> 0.20 | Localization |
| JSON | Jason | ~> 1.2 | JSON parsing |
| HTTP Server | Bandit | ~> 1.5 | Plug/Phoenix web server |
| Telemetry | telemetry_metrics + telemetry_poller | ~> 1.0 / ~> 1.0 | Metrics collection |

## Data Layer

| Component | Choice             | Version / Plan | Purpose              |
| --------- | ------------------ | -------------- | -------------------- |
| Database  | PostgreSQL | —  | Primary data store |
| Cache     | None (no Redis/cache layer configured) | — | — |
| Search    | None (no search service configured) | — | — |
| File storage | None (no external object storage configured) | — | — |

## Package Manager & Tooling

| Tool            | Choice               | Notes                         |
| --------------- | -------------------- | ----------------------------- |
| Package manager | Mix + Hex         | `mix.lock` committed          |
| Monorepo tool   | None | —           |
| Bundler         | esbuild | ~> 0.8 (dev runtime) |
| CSS tooling     | Tailwind CSS | ~> 0.2 (dev runtime) |
| Linter          | None configured | —         |
| Formatter       | `mix format` | Elixir formatter |

## Version Pinning Strategy

- [ ] Exact versions (`5.7.3`) — maximum reproducibility
- [ ] Caret ranges (`^5.7.3`) — allow patch/minor updates
- [x] Tilde ranges (`~5.7.3`) — allow patch updates only (Elixir-style `~>` constraints in `mix.exs`)

**Lockfile:** Always committed. CI installs with `--frozen-lockfile` equivalent (`mix deps.get` uses `mix.lock`).

## Stack Rationale

| Decision               | Chosen           | Alternatives Considered     | Reason                              |
| ---------------------- | ---------------- | --------------------------- | ----------------------------------- |
| Web framework          | Phoenix + LiveView | Rails, Django, SPA frameworks | Real-time UI with minimal JS and strong BEAM concurrency |
| Database               | PostgreSQL       | MySQL, SQLite               | Mature relational store with strong Ecto support |
| ORM                    | Ecto SQL         | ActiveRecord-style ORMs     | Compile-time queries, migrations, and changesets |
| Asset pipeline         | esbuild + Tailwind | Webpack/Vite + CSS frameworks | Fast, simple asset build integrated with Phoenix |
| HTTP server            | Bandit           | Cowboy                      | Modern Plug-compatible server with good HTTP/2 support |

## Compatibility Notes

- **Minimum Elixir version:** 1.14 (`mix.exs` constraint)
- **Erlang/OTP:** Must be compatible with Elixir 1.14
- **Required system dependencies:** PostgreSQL server/client (for `ecto` tasks)
