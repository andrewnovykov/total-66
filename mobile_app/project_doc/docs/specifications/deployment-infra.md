# Deployment & Infrastructure

## Platform Overview

| Component      | Provider         | Plan     | Region  |
| -------------- | ---------------- | -------- | ------- |
| Web Service    | Render.com       | Free     | Oregon  |
| Database       | Render PostgreSQL | Free    | Oregon  |
| Container      | Docker           | —        | —       |
| Preview Envs   | Render.com       | Auto     | Oregon  |

---

## CI/CD Pipeline

### Pipeline Stages

```yaml
# GitHub Actions + Render.com Auto-Deploy
pipeline:
    - stage: lint-and-format
      trigger: [push, pull_request]
      steps:
          - mix deps.get
          - mix format --check-formatted
          - mix credo --strict

    - stage: test
      trigger: [push, pull_request]
      services:
          - postgres:16
      steps:
          - mix ecto.create
          - mix ecto.migrate
          - mix test

    - stage: build
      trigger: [push to main]
      steps:
          - docker build -t heads_up .

    - stage: deploy-preview
      trigger: [pull_request]
      provider: Render.com Preview Environments
      ttl: 30 days

    - stage: deploy-production
      trigger: [push to main]
      provider: Render.com Auto-Deploy
```

### GitHub Actions Workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
    push:
        branches: [main, develop]
    pull_request:
        branches: [main]

jobs:
    test:
        runs-on: ubuntu-latest

        services:
            postgres:
                image: postgres:16
                env:
                    POSTGRES_USER: postgres
                    POSTGRES_PASSWORD: postgres
                    POSTGRES_DB: heads_up_test
                ports:
                    - 5432:5432
                options: >-
                    --health-cmd pg_isready
                    --health-interval 10s
                    --health-timeout 5s
                    --health-retries 5

        steps:
            - uses: actions/checkout@v4

            - name: Set up Elixir
              uses: erlef/setup-beam@v1
              with:
                  elixir-version: '1.14.5'
                  otp-version: '25.3'

            - name: Restore dependencies cache
              uses: actions/cache@v3
              with:
                  path: |
                      deps
                      _build
                  key: ${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}

            - name: Install dependencies
              run: mix deps.get

            - name: Check formatting
              run: mix format --check-formatted

            - name: Run Credo
              run: mix credo --strict

            - name: Setup database
              run: |
                  mix ecto.create
                  mix ecto.migrate
              env:
                  MIX_ENV: test

            - name: Run tests
              run: mix test --cover
              env:
                  MIX_ENV: test
```

---

## Docker Configuration

### Dockerfile

```dockerfile
# Multi-stage build for Phoenix/Elixir application
# Based on Hex.pm's Elixir image with Debian Bullseye

ARG ELIXIR_VERSION=1.14.5
ARG OTP_VERSION=25.3.2.2
ARG DEBIAN_VERSION=bullseye-20251208-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

# ============================================
# BUILD STAGE
# ============================================
FROM ${BUILDER_IMAGE} AS builder

# Install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build environment
ENV MIX_ENV="prod"

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Copy compile-time config
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# Copy application code
COPY priv priv
COPY lib lib
COPY assets assets

# Compile assets (Tailwind + esbuild)
RUN mix assets.deploy

# Compile release
COPY rel rel
RUN mix compile

# Copy runtime config
COPY config/runtime.exs config/

# Build release
RUN mix release

# ============================================
# RUNTIME STAGE
# ============================================
FROM ${RUNNER_IMAGE}

# Install runtime dependencies
RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

ENV MIX_ENV="prod"

# Copy release from builder
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/heads_up ./

USER nobody

# Run migrations then start server
CMD /app/bin/migrate && /app/bin/server
```

### Key Dockerfile Features

| Feature              | Description                                    |
| -------------------- | ---------------------------------------------- |
| Multi-stage build    | Smaller final image (~100MB vs ~1GB)           |
| Debian (not Alpine)  | Avoids DNS resolution issues in production     |
| Non-root user        | Security: runs as `nobody`                     |
| Auto-migrations      | Runs `migrate` script before server start      |
| Asset compilation    | Tailwind + esbuild compiled at build time      |

---

## Render.com Configuration

### render.yaml (Infrastructure as Code)

```yaml
services:
    - type: web
      name: heads_up
      env: docker
      plan: free
      region: oregon
      buildCommand: docker build -t heads_up .
      startCommand: /app/bin/migrate && /app/bin/server
      healthCheckPath: /
      envVars:
          - key: DATABASE_URL
            fromDatabase:
                name: heads_up_db
                property: connectionString
          - key: SECRET_KEY_BASE
            generateValue: true
          - key: POOL_SIZE
            value: '10'

databases:
    - name: heads_up_db
      plan: free
      region: oregon
      ipAllowList: [] # Access from anywhere

# Preview Environments for Pull Requests
previews:
    - generation: automatic
      ttl: 30d
      envVars:
          - key: SECRET_KEY_BASE
            generateValue: true
```

### Render Service Configuration

| Setting           | Value                                    |
| ----------------- | ---------------------------------------- |
| Service Type      | Web Service                              |
| Environment       | Docker                                   |
| Build Command     | `docker build -t heads_up .`             |
| Start Command     | `/app/bin/migrate && /app/bin/server`    |
| Health Check      | `GET /` returns 200                      |
| Auto-Deploy       | Yes (on push to main)                    |
| Preview Envs      | Auto-created for PRs, TTL 30 days        |

---

## Database Hosting & Migrations

| Environment | Provider          | Connection                              |
| ----------- | ----------------- | --------------------------------------- |
| Local       | Docker/Local PG   | `localhost:5432/heads_up_dev`           |
| Test        | Docker/Local PG   | `localhost:5432/heads_up_test`          |
| Preview     | Render PostgreSQL | Auto-provisioned per PR                 |
| Production  | Render PostgreSQL | `DATABASE_URL` from `heads_up_db`       |

### Migration Strategy

- **Automatic:** Migrations run during container startup via `/app/bin/migrate`
- **Migration tool:** Ecto.Migration
- **Rollback approach:** Manual via `mix ecto.rollback` (dev only) or restore from backup (prod)
- **Schema changes:** Require PR review before merging

### Migration Scripts

```bash
# Development
mix ecto.create          # Create database
mix ecto.migrate         # Run pending migrations
mix ecto.rollback        # Rollback last migration
mix ecto.reset           # Drop, create, migrate

# Production (via release)
/app/bin/migrate         # Run in Dockerfile CMD
```

---

## Release Configuration

### rel/overlays/bin/migrate

```bash
#!/bin/sh
cd -P -- "$(dirname -- "$0")"
exec ./heads_up eval HeadsUp.Release.migrate
```

### rel/overlays/bin/server

```bash
#!/bin/sh
cd -P -- "$(dirname -- "$0")"
PHX_SERVER=true exec ./heads_up start
```

### lib/heads_up/release.ex

```elixir
defmodule HeadsUp.Release do
  @app :heads_up

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
```

---

## Monitoring, Logging & Alerting

| Concern        | Tool                       | Configuration                     |
| -------------- | -------------------------- | --------------------------------- |
| Error tracking | Render Logs                | Built-in log streaming            |
| Logging        | Elixir Logger (structured) | Log level: `info` in prod         |
| Uptime         | Render Health Checks       | `GET /` every 30s                 |
| APM            | (Future) Sentry            | Optional integration              |
| Alerting       | Render Notifications       | Deploy success/failure            |

### Logger Configuration

```elixir
# Production (config/prod.exs)
config :logger, level: :info

# Log format (config/config.exs)
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]
```

### Key Alerts

| Alert                 | Condition                      | Severity | Action                 |
| --------------------- | ------------------------------ | -------- | ---------------------- |
| Deploy failed         | Build/start command fails      | Critical | Check Render logs      |
| Health check failed   | `GET /` returns non-200        | Critical | Auto-restart by Render |
| Database unreachable  | Connection timeout             | Critical | Check Render PostgreSQL |
| High memory usage     | > 512MB (free tier limit)      | Medium   | Optimize queries       |

---

## Backup & Disaster Recovery

| Component  | Backup Frequency | Retention | Recovery Method              |
| ---------- | ---------------- | --------- | ---------------------------- |
| Database   | Daily (Render)   | 7 days    | Render dashboard restore     |
| Code       | Git-versioned    | Indefinite | Redeploy from repo          |
| Uploads    | (Future)         | —         | (Future: S3 versioning)      |
| Config     | Git-versioned    | Indefinite | Redeploy with env vars      |

**RTO (Recovery Time Objective):** < 30 minutes (redeploy from Git)
**RPO (Recovery Point Objective):** < 24 hours (daily database backups)

---

## Local Development with Docker

### docker-compose.yml (Optional)

```yaml
services:
    db:
        image: postgres:16
        ports:
            - '5432:5432'
        environment:
            POSTGRES_USER: postgres
            POSTGRES_PASSWORD: postgres
            POSTGRES_DB: heads_up_dev
        volumes:
            - pgdata:/var/lib/postgresql/data
        healthcheck:
            test: ['CMD-SHELL', 'pg_isready -U postgres']
            interval: 5s
            timeout: 5s
            retries: 5

volumes:
    pgdata:
```

### Commands

```bash
# Start local database
docker-compose up -d db

# Or without Docker Compose
docker run -d \
  --name heads_up_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=heads_up_dev \
  -p 5432:5432 \
  postgres:16

# Build production image locally
docker build -t heads_up .

# Run production image locally
docker run -p 4000:4000 \
  -e DATABASE_URL=ecto://postgres:postgres@host.docker.internal:5432/heads_up_dev \
  -e SECRET_KEY_BASE=$(mix phx.gen.secret) \
  -e PHX_HOST=localhost \
  heads_up
```

---

## Deployment Checklist

### Before First Deploy

- [ ] `render.yaml` committed to repo
- [ ] Dockerfile tested locally with `docker build`
- [ ] Database migrations work with `mix ecto.migrate`
- [ ] Assets compile with `mix assets.deploy`
- [ ] Health check endpoint (`/`) returns 200

### For Each Deploy

- [ ] All tests pass (`mix test`)
- [ ] Code formatted (`mix format --check-formatted`)
- [ ] No Credo warnings (`mix credo --strict`)
- [ ] Migrations are backward-compatible
- [ ] Environment variables updated if needed

### After Deploy

- [ ] Health check passes on Render dashboard
- [ ] Application loads in browser
- [ ] Check Render logs for errors
- [ ] Verify database migrations applied

---

## Scaling Considerations (Future)

| When Traffic Grows          | Action                              |
| --------------------------- | ----------------------------------- |
| Response times > 500ms      | Upgrade Render plan (Starter+)      |
| Database connections maxed  | Increase `POOL_SIZE`                |
| Memory > 512MB              | Upgrade plan or optimize queries    |
| Need horizontal scaling     | Add more Render instances           |
| Need CDN                    | Add Cloudflare or Render CDN        |
| Need background jobs        | Add Oban with Redis/PostgreSQL      |
