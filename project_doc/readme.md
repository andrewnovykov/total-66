Project Repository Structure for AI-Assisted Development

This is how to organize everything in your file system so Claude Code (or any AI agent) can work efficiently.

COMPLETE FOLDER STRUCTURE

```
my-project/
│
├── .claude/                              # AI Agent Instructions
│   ├── project-brief.md                  # Quick project overview & tech stack summary
│   ├── CLAUDE.md                         # AI agent rules, conventions & context
│   └── commands/                         # Custom slash commands
│       ├── feature.md                    # /feature command template
│       ├── bugfix.md                     # /bugfix command template
│       └── review.md                     # /review command template
│
├── docs/                                 # All Documentation
│   │
│   ├── requirements/                     # WHAT to build
│   │   ├── 01-project-overview.md        # Vision, problem, goals, constraints, NFR summary
│   │   ├── 02-user-personas.md           # Who uses this app
│   │   ├── 03-features-mvp.md            # Must-have features
│   │   ├── 04-features-future.md         # Nice-to-have features
│   │   └── 05-business-rules.md          # Rules & constraints
│   │
│   ├── specifications/                   # HOW it should work (technical specs)
│   │   ├── tech-stack.md                 # Runtime, framework, database, tooling with versions
│   │   ├── folder-structure.md           # Directory layout, naming conventions, module boundaries
│   │   ├── data-model.md                 # Database schema (column types, indexes, constraints, migrations)
│   │   ├── api-design.md                 # API style, endpoints, response envelope, pagination, rate limits
│   │   ├── api-endpoints.md              # Actual routes (AI fills during build)
│   │   ├── auth-strategy.md              # Auth method, JWT/session config, RBAC, password policy, MFA
│   │   ├── environment-config.md         # Env vars, per-environment overrides, secrets, feature flags
│   │   ├── testing-strategy.md           # Test pyramid, coverage targets, frameworks, CI pipeline
│   │   ├── deployment-infra.md           # CI/CD pipeline, Docker, monitoring, backup & DR
│   │   ├── nfr.md                        # Performance, security, accessibility, compliance, uptime
│   │   ├── code-style.md                 # Naming, linting, formatting, imports, git workflow, PR template
│   │   ├── integrations-technical.md     # SDK configs, webhooks, retry strategy, adapters, health checks
│   │   ├── integrations.md               # Business-level integration requirements
│   │   └── user-flows.md                 # Step-by-step user journeys
│   │
│   ├── design/                           # HOW it should look
│   │   ├── style-guide.md                # Colors, fonts, spacing, components
│   │   ├── pages/                        # Page specifications
│   │   │   ├── 01-landing-page.md
│   │   │   ├── 02-dashboard.md
│   │   │   ├── 03-feature-page.md
│   │   │   └── ...
│   │   └── wireframes/                   # Sketches/mockups (if any)
│   │       └── .gitkeep
│   │
│   └── guides/                           # HOW to operate
│       ├── setup-local.md                # Local development setup (AI fills)
│       ├── deployment.md                 # How to deploy (AI fills)
│       └── admin-guide.md                # How to manage the app (AI fills)
│
├── prompts/                              # AI Conversation Templates
│   │
│   ├── phase-0-folders/                  # Folder creation
│   │   └── create-folders.md
│   │
│   ├── phase-1-setup/                    # Initial setup prompts
│   │   ├── 01-project-init.md            # Init project using tech-stack.md, folder-structure.md, code-style.md
│   │   ├── 02-database-design.md         # Schema from data-model.md with migrations
│   │   └── 03-auth-system.md             # Auth from auth-strategy.md with RBAC
│   │
│   ├── phase-2-features/                 # Feature building prompts
│   │   ├── template-feature.md           # Reusable template
│   │   └── ...
│   │
│   ├── phase-3-ui/                       # UI building prompts
│   │   ├── 01-layout-navigation.md
│   │   ├── 02-page-templates.md
│   │   └── ...
│   │
│   └── phase-4-polish/                   # Finalization prompts
│       ├── 01-testing.md                 # Testing per testing-strategy.md
│       ├── 02-review.md
│       └── 03-deployment.md              # Deploy per deployment-infra.md
│
├── samples/                              # Example Data & Content
│   ├── seed-data.json                    # Sample database records
│   ├── test-users.md                     # Test account credentials
│   └── content/                          # Sample content
│       ├── email-templates.md            # Email copy
│       └── ui-text.md                    # Button labels, messages
│
├── assets/                               # Static Files (provided by you)
│   ├── logo/
│   ├── images/
│   └── icons/
│
├── references/                           # Inspiration & Research
│   ├── competitor-analysis.md
│   ├── screenshots/                      # Screenshots of apps you like
│   └── links.md                          # Useful reference URLs
│
│
│ ============================================
│ BELOW: Generated by AI Agent (source code)
│ ============================================
│
├── src/                                  # Source Code (AI creates this)
│   ├── backend/
│   └── frontend/
│
├── database/                             # Database files
│   ├── migrations/
│   └── seeds/
│
├── tests/                                # Test files
│
├── .env.example                          # Environment variables template
├── .gitignore
├── docker-compose.yml                    # Local dev services
├── Dockerfile                            # Production container
├── package.json                          # (or equivalent)
└── README.md                             # Project readme
```

## WORKFLOW SUMMARY

```
┌──────────────────────────────────────────────────────────────────┐
│                         YOUR WORKFLOW                            │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. YOU FILL OUT:                                                │
│     └── /docs/requirements/     (what you want)                  │
│     └── /docs/specifications/   (how it works — technical specs) │
│     └── /docs/design/           (how it should look)             │
│     └── /samples/               (example data)                   │
│                                                                  │
│  2. YOU COPY PROMPT FROM:                                        │
│     └── /prompts/phase-X/       (step-by-step instructions)      │
│                                                                  │
│  3. AI READS:                                                    │
│     └── /.claude/CLAUDE.md      (project context & conventions)  │
│     └── /docs/                  (your requirements & specs)      │
│                                                                  │
│  4. AI CREATES:                                                  │
│     └── /src/                   (source code)                    │
│     └── /database/              (database files)                 │
│     └── /tests/                 (test files)                     │
│                                                                  │
│  5. AI UPDATES:                                                  │
│     └── /docs/guides/           (how to run/deploy)              │
│     └── /docs/specifications/   (API docs, etc.)                 │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```
