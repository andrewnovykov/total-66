# Folder Structure Specification

## Architecture Pattern

- [x] Feature-based (group by domain feature within contexts)
- [ ] Layered (group by technical layer)
- [x] Domain-Driven Design (bounded contexts via Phoenix Contexts)
- [ ] Hexagonal / Ports & Adapters
- [ ] Other: [describe]

## Repository Strategy

- [x] Single package (standard Mix project)
- [ ] Monorepo with workspaces
- [ ] Monorepo with Turborepo / Nx

---

## Directory Tree

```
heads_up/
├── assets/                         # Frontend assets (Tailwind, JS)
│   ├── css/                        # Stylesheets (app.css)
│   ├── js/                         # JavaScript (app.js, hooks)
│   ├── vendor/                     # Third-party assets
│   └── tailwind.config.js          # Tailwind configuration
│
├── config/                         # Application configuration
│   ├── config.exs                  # Base config
│   ├── dev.exs                     # Development config
│   ├── prod.exs                    # Production config
│   ├── runtime.exs                 # Runtime config (env vars)
│   └── test.exs                    # Test config
│
├── lib/                            # Application source code
│   ├── heads_up/                   # Domain logic (Business Layer)
│   │   ├── accounts/               # [Context] User management & Auth
│   │   ├── goals/                  # [Context] Goals, phases, steps
│   │   ├── challenges/             # [Context] Predefined & custom challenges
│   │   ├── groups/                 # [Context] Group goals & coaching
│   │   ├── services/               # [Services] Cross-cutting logic (Activity, Feed)
│   │   ├── repo.ex                 # Ecto Repository
│   │   ├── mailer.ex               # Email delivery
│   │   └── application.ex          # OTP Application entry point
│   │
│   ├── heads_up_web/               # Web Interface (Presentation Layer)
│   │   ├── components/             # Function components
│   │   │   ├── layouts/            # App & Root layouts
│   │   │   └── core_components.ex  # Shared UI components
│   │   ├── controllers/            # Standard MVC controllers (Auth, API)
│   │   ├── live/                   # LiveView modules (Interactive UI)
│   │   │   ├── [feature]_live/     # Feature-specific LiveViews
│   │   │   └── ...
│   │   ├── router.ex               # Route definitions
│   │   ├── endpoint.ex             # Phoenix Endpoint
│   │   └── gettext.ex              # Internationalization
│   │
│   ├── heads_up.ex                 # Main library file
│   └── heads_up_web.ex             # Web definitions
│
├── priv/                           # Private resources
│   ├── repo/                       # Database assets
│   │   ├── migrations/             # Database migrations
│   │   └── seeds.exs               # Seed data
│   ├── static/                     # Compiled static assets
│   └── gettext/                    # Translation files
│
├── test/                           # Tests
│   ├── heads_up/                   # Domain tests
│   ├── heads_up_web/               # Web/LiveView tests
│   ├── support/                    # Test helpers & factories
│   └── test_helper.exs             # Test runner config
│
├── project_doc/                    # Project Documentation
│   ├── docs/
│   ├── specifications/
│   └── ...
│
├── .formatter.exs                  # Code formatter config
├── mix.exs                         # Project dependencies & config
└── mix.lock                        # Dependency lockfile
```

## Naming Conventions

| Item           | Convention           | Example                           |
| -------------- | -------------------- | --------------------------------- |
| Directories    | [snake_case]         | `lib/heads_up/user_profiles/`     |
| Elixir Modules | [PascalCase]         | `HeadsUp.Goals.Goal`              |
| Elixir Files   | [snake_case]         | `lib/heads_up/goals/goal.ex`      |
| HEEx Templates | [snake_case]         | `home.html.heex`                  |
| Test files     | [filename]\_test.exs | `goal_test.exs`                   |
| Migrations     | [timestamp]\_[name]  | `20240101120000_create_users.exs` |

## Module Boundary Rules

- **Web vs Domain**: `heads_up_web/` can call `heads_up/`, but `heads_up/` must never call `heads_up_web/`.
- **Contexts**: Domain logic is organized into Contexts (e.g., `HeadsUp.Goals`). Controllers and LiveViews should invoke Context functions, not Ecto queries directly.
- **Services**: Complex cross-cutting logic (like Feeds or Activity Tracking) resides in `heads_up/services/`.
- **Components**: UI components in `heads_up_web/components/` should be purely functional and not contain business logic or side effects.
- **LiveView**: LiveViews handle UI state and events, delegating business rules to Contexts.
