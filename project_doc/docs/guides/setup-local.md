# Local Development Setup

Complete guide for setting up HeadsUp development environment on your local machine.

---

## Prerequisites

### Required Software

| Software      | Version        | Installation                                    |
| ------------- | -------------- | ----------------------------------------------- |
| Elixir        | ~> 1.14        | `brew install elixir` (macOS) or [asdf](https://asdf-vm.com/) |
| Erlang/OTP    | ~> 25          | Installed with Elixir or via asdf              |
| PostgreSQL    | 16+            | `brew install postgresql@16` or [Postgres.app](https://postgresapp.com/) |
| Git           | Latest         | `brew install git`                              |

### Recommended Tools

| Tool          | Purpose                     | Installation                |
| ------------- | --------------------------- | --------------------------- |
| asdf          | Version management          | `brew install asdf`         |
| VS Code       | IDE with ElixirLS extension | [code.visualstudio.com](https://code.visualstudio.com/) |
| TablePlus     | Database GUI                | `brew install tableplus`    |
| Postman       | API testing                 | `brew install postman`      |

---

## Verify Prerequisites

```bash
# Check Elixir version (should be 1.14+)
elixir --version

# Check Erlang version (should be 25+)
erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().'

# Check PostgreSQL is running
psql --version
pg_isready
```

---

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/heads_up.git
cd heads_up
```

### 2. Install Dependencies

```bash
# Install Elixir dependencies
mix deps.get
```

### 3. Setup Database

```bash
# Full setup (create, migrate, seed)
mix ecto.setup

# Or step by step:
mix ecto.create        # Create heads_up_dev database
mix ecto.migrate       # Run migrations
mix run priv/repo/seeds.exs  # Seed sample data
```

### 4. Setup Assets

```bash
# Install Tailwind and esbuild (if not installed)
mix assets.setup

# Build assets
mix assets.build
```

### 5. One-Command Setup

For a fresh setup, use the convenience alias:

```bash
mix setup
```

This runs: `deps.get` → `ecto.setup` → `assets.setup` → `assets.build`

---

## Running the Application

### Start Development Server

```bash
# Standard server
mix phx.server

# With IEx console (recommended for development)
iex -S mix phx.server
```

**Access the application:** [http://localhost:4000](http://localhost:4000)

### Development Routes

In development mode, additional routes are available:

| Route               | Purpose                     |
| ------------------- | --------------------------- |
| `/dev/dashboard`    | Phoenix LiveDashboard       |
| `/dev/mailbox`      | Local email preview (Swoosh) |

---

## Database Configuration

### Development Database

| Setting    | Value           |
| ---------- | --------------- |
| Host       | `localhost`     |
| Port       | `5432`          |
| Database   | `heads_up_dev`  |
| Username   | `postgres`      |
| Password   | `postgres`      |
| Pool Size  | `10`            |

### Common Database Commands

```bash
# Reset database (drop, create, migrate, seed)
mix ecto.reset

# Run pending migrations only
mix ecto.migrate

# Rollback last migration
mix ecto.rollback

# Check migration status
mix ecto.migrations

# Generate new migration
mix ecto.gen.migration add_column_to_table
```

### Database Connection in IEx

```elixir
# In IEx console
alias HeadsUp.Repo
alias HeadsUp.Accounts.User

# Query examples
Repo.all(User)
Repo.get(User, 1)
```

---

## Running Tests

### Run All Tests

```bash
mix test
```

### Run Specific Tests

```bash
# Single file
mix test test/heads_up/accounts_test.exs

# Single test by line number
mix test test/heads_up/accounts_test.exs:42

# Run tests with specific tag
mix test --only integration

# Exclude certain tags
mix test --exclude pending
```

### Test with Coverage

```bash
mix test --cover
```

### Watch Mode (requires mix_test_watch)

```bash
mix test.watch
```

### Test Database

Tests use a separate database: `heads_up_test`

The test database is automatically:
- Created before tests run
- Migrated before tests run
- Sandboxed for test isolation

---

## Code Quality Tools

### Format Code

```bash
# Check formatting
mix format --check-formatted

# Auto-format all files
mix format
```

### Run Credo (Linter)

```bash
# Standard check
mix credo

# Strict mode (CI pipeline uses this)
mix credo --strict
```

### Run Dialyzer (Type Checker)

```bash
# First run builds PLT (takes time)
mix dialyzer
```

---

## Asset Management

### Tailwind CSS

```bash
# Watch for changes (already runs with phx.server)
mix tailwind heads_up --watch

# Build for production
mix tailwind heads_up --minify
```

### esbuild (JavaScript)

```bash
# Watch for changes (already runs with phx.server)
mix esbuild heads_up --watch

# Build for production
mix esbuild heads_up --minify
```

### Deploy Assets (Production Build)

```bash
mix assets.deploy
```

---

## Environment Variables

Development uses hardcoded values in `config/dev.exs`. No environment variables required.

For local testing of production config:

```bash
export DATABASE_URL="ecto://postgres:postgres@localhost:5432/heads_up_dev"
export SECRET_KEY_BASE=$(mix phx.gen.secret)
export PHX_HOST="localhost"
export PORT="4000"
```

---

## Mix Aliases Reference

| Alias            | Commands                                                      |
| ---------------- | ------------------------------------------------------------- |
| `mix setup`      | `deps.get` → `ecto.setup` → `assets.setup` → `assets.build`  |
| `mix ecto.setup` | `ecto.create` → `ecto.migrate` → `run priv/repo/seeds.exs`   |
| `mix ecto.reset` | `ecto.drop` → `ecto.setup`                                    |
| `mix test`       | `ecto.create --quiet` → `ecto.migrate --quiet` → `test`      |
| `mix assets.setup` | `tailwind.install --if-missing` → `esbuild.install --if-missing` |
| `mix assets.build` | `tailwind heads_up` → `esbuild heads_up`                    |
| `mix assets.deploy` | `tailwind --minify` → `esbuild --minify` → `phx.digest`   |

---

## Troubleshooting

### PostgreSQL Connection Failed

```bash
# Check if PostgreSQL is running
pg_isready

# Start PostgreSQL (macOS with Homebrew)
brew services start postgresql@16

# Check PostgreSQL logs
tail -f /usr/local/var/log/postgresql@16.log
```

### Database Already Exists

```bash
# Drop and recreate
mix ecto.drop
mix ecto.create
mix ecto.migrate
```

### Dependencies Out of Sync

```bash
# Clean and refetch
rm -rf deps _build
mix deps.get
mix deps.compile
```

### Assets Not Loading

```bash
# Reinstall asset tools
mix assets.setup

# Rebuild assets
mix assets.build

# Clear Phoenix digest
rm -rf priv/static/assets
mix assets.deploy
```

### Port 4000 Already in Use

```bash
# Find process using port 4000
lsof -i :4000

# Kill the process
kill -9 <PID>

# Or run on different port
PORT=4001 mix phx.server
```

### Migration Issues

```bash
# Check migration status
mix ecto.migrations

# Rollback problematic migration
mix ecto.rollback --step 1

# Force reset (WARNING: loses all data)
mix ecto.reset
```

---

## Docker Development (Optional)

### Using Docker for PostgreSQL Only

```bash
# Start PostgreSQL container
docker run -d \
  --name heads_up_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=heads_up_dev \
  -p 5432:5432 \
  postgres:16

# Stop container
docker stop heads_up_db

# Remove container
docker rm heads_up_db
```

### Using Docker Compose

```bash
# Start services (PostgreSQL)
docker-compose up -d db

# Stop services
docker-compose down
```

---

## IDE Setup

### VS Code Extensions

| Extension       | ID                            | Purpose              |
| --------------- | ----------------------------- | -------------------- |
| ElixirLS        | `jakebecker.elixir-ls`        | Elixir language server |
| Phoenix         | `phoenixframework.phoenix`    | Phoenix snippets     |
| Tailwind CSS    | `bradlc.vscode-tailwindcss`   | Tailwind IntelliSense |
| PostgreSQL      | `ckolkman.vscode-postgres`    | Database explorer    |

### VS Code Settings

```json
{
  "elixirLS.suggestSpecs": false,
  "elixirLS.dialyzerEnabled": true,
  "elixirLS.fetchDeps": false,
  "[elixir]": {
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "jakebecker.elixir-ls"
  },
  "[heex]": {
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "jakebecker.elixir-ls"
  }
}
```

---

## Quick Reference

```bash
# Daily workflow
mix phx.server              # Start dev server
iex -S mix phx.server       # Start with console
mix test                    # Run tests
mix format                  # Format code

# Database
mix ecto.migrate            # Run new migrations
mix ecto.reset              # Full database reset
mix run priv/repo/seeds.exs # Re-seed data

# Code quality
mix format --check-formatted
mix credo --strict

# Generate code
mix phx.gen.live Context Schema table col:type
mix phx.gen.context Context Schema table col:type
mix ecto.gen.migration migration_name
```

---

## Seed Data

After running `mix ecto.setup`, the development database includes:

- **Admin User**: `admin@headsup.com` / `password123`
- **Sample Users**: Various users with goals and posts
- **Goal Categories**: Predefined categories for goals
- **Sample Goals**: Goals with steps, posts, and engagement

Check [priv/repo/seeds.exs](../../priv/repo/seeds.exs) for seed data details.
