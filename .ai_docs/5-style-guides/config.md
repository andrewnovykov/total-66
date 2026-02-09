# Config Style Guide

This style guide documents the patterns and conventions used in HeadsUp configuration files.

## File Organization

```
config/
  config.exs      # Base configuration (all environments)
  dev.exs         # Development environment
  test.exs        # Test environment
  prod.exs        # Production environment
  runtime.exs     # Runtime configuration (secrets)
```

## Base Configuration (config.exs)

```elixir
# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :heads_up,
  ecto_repos: [HeadsUp.Repo],
  generators: [timestamp_type: :utc_datetime]
```

**Pattern**:
- Add descriptive comment at top
- Configure ecto repos first
- Use UTC datetime for generators

### Endpoint Configuration

```elixir
config :heads_up, HeadsUpWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: HeadsUpWeb.ErrorHTML, json: HeadsUpWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: HeadsUp.PubSub,
  live_view: [signing_salt: "DS9ubxYu"]
```

**Pattern**: Configure error renderers for both HTML and JSON.

### Mailer Configuration

```elixir
config :heads_up, HeadsUp.Mailer, adapter: Swoosh.Adapters.Local
```

### Build Tools Configuration

```elixir
# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  heads_up: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  heads_up: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]
```

**Pattern**: Pin versions for reproducible builds.

### Logger Configuration

```elixir
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]
```

### JSON Library

```elixir
config :phoenix, :json_library, Jason
```

### Environment Import

```elixir
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
```

**Pattern**: Environment config ALWAYS imported last.

## Development Configuration (dev.exs)

```elixir
import Config

# Configure your database
config :heads_up, HeadsUp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "heads_up_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
```

**Pattern**: Enable debugging options in dev only.

### Development Server

```elixir
config :heads_up, HeadsUpWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "N9JQGzci2ouyBmoXLZLDa5O3muHP8RYJf8S9KLkGXb5HfQzAo355qnyWsgjxoeXo",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:heads_up, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:heads_up, ~w(--watch)]}
  ]
```

**Pattern**:
- Bind to `127.0.0.1` (localhost only)
- Enable code reloading
- Configure asset watchers

### Live Reload

```elixir
config :heads_up, HeadsUpWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/heads_up_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]
```

**Pattern**: Exclude uploads directory from live reload.

### Dev-Only Features

```elixir
# Enable dev routes for dashboard and mailbox
config :heads_up, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  debug_heex_annotations: true,
  enable_expensive_runtime_checks: true

# Disable swoosh api client
config :swoosh, :api_client, false
```

## Test Configuration (test.exs)

```elixir
import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1
```

**Pattern**: Speed up tests by reducing bcrypt rounds.

### Test Database

```elixir
config :heads_up, HeadsUp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "heads_up_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2
```

**Pattern**:
- Support test partitioning with `MIX_TEST_PARTITION`
- Use `SQL.Sandbox` pool for test isolation
- Dynamic pool size based on CPU cores

### Test Server

```elixir
config :heads_up, HeadsUpWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "UmNBxTd+cqumUMeopVBBq/kb/B0Ub7wq1IhvGmBfej0brj7CX2d3s8H5iYB09ZKt",
  server: false
```

**Pattern**: Disable server in tests (no HTTP server needed).

### Test Mailer

```elixir
config :heads_up, HeadsUp.Mailer, adapter: Swoosh.Adapters.Test
```

### Test Logging

```elixir
# Print only warnings and errors during test
config :logger, level: :warning
```

### Test LiveView

```elixir
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
```

## Production Configuration (prod.exs)

```elixir
import Config

# Do not print debug messages in production
config :logger, level: :info

# Runtime configuration is in runtime.exs
```

**Pattern**: Keep prod.exs minimal, use runtime.exs for secrets.

## Runtime Configuration (runtime.exs)

```elixir
import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      """

  config :heads_up, HeadsUp.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    ssl: true

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :heads_up, HeadsUpWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base
end
```

**Pattern**:
- Read secrets from environment variables
- Raise on missing required variables
- Provide defaults for optional variables

## Configuration Patterns

### Environment-Specific Values

```elixir
# In config.exs - base value
config :heads_up, feature_enabled: false

# In dev.exs - override for dev
config :heads_up, feature_enabled: true

# In prod.exs - override for prod
config :heads_up, feature_enabled: true
```

### Reading Config at Runtime

```elixir
Application.get_env(:heads_up, :feature_enabled)
Application.get_env(:heads_up, HeadsUpWeb.Endpoint)[:url][:host]
```

### Compile-Time Config Check

```elixir
if Application.compile_env(:heads_up, :dev_routes) do
  # Dev-only routes
end
```

## Naming Conventions

| Config Key | Type | Example |
|------------|------|---------|
| Application | atom | `:heads_up` |
| Module | module | `HeadsUp.Repo` |
| Feature flag | atom | `:dev_routes` |
| Setting | atom | `:pool_size` |

## Security Considerations

```elixir
# DEV ONLY - never commit real secrets
secret_key_base: "N9JQGzci2ouyBmoXLZLDa5O3muHP8RYJf8S9KLkGXb5HfQzAo355qnyWsgjxoeXo"

# PRODUCTION - always use environment variables
secret_key_base: System.get_env("SECRET_KEY_BASE")
```

**Pattern**: Development configs can have hardcoded values; production MUST use environment variables.
