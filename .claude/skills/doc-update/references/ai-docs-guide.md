# .ai_docs Update Guide

## File Purposes and Update Rules

### 1-techstack.md
**What:** Technology versions, domain analysis, core business concepts.
**When to update:** New dependencies added, new domain concepts introduced, architecture changes.
**How:** Add to the "Core Business/Domain Concepts" list or update version numbers.

### 2-file-categorization.json
**What:** Maps file paths to architectural categories.
**When to update:** New file types or directories introduced.
**How:** Add entries to the appropriate category arrays.

### 3-architectural-domains.json
**What:** Domain constraints, required patterns, naming conventions per layer.
**When to update:** New architectural patterns established, new constraints discovered.
**How:** Add to the relevant domain's constraints or patterns.

### 4-domains/ Files

#### schemas.md
**What:** Table of all Ecto schemas with module names, file paths, table names. Standard patterns, field types, changeset patterns.
**When to update:** New schema created, fields added/removed, associations changed, new changeset patterns.
**How:** Add row to the schema table. Add field details to the relevant section.

#### contexts.md
**What:** Context modules with their public API functions, ownership patterns, error handling.
**When to update:** New context function added, function signature changed, new context module created.
**How:** Add function to the relevant context's function list with signature and description.

#### live-views.md
**What:** LiveView modules, their mount assigns, handle_event names, handle_info patterns.
**When to update:** New LiveView created, new events added, new assigns introduced.
**How:** Add module entry or update events list for existing module.

#### routing.md
**What:** Route definitions, pipeline assignments, scope groupings.
**When to update:** Routes added/removed/changed, new scopes or pipelines.
**How:** Add routes to the relevant scope section.

#### function-components.md
**What:** Shared function components, their attributes, slots, usage examples.
**When to update:** New component created, component API changed.
**How:** Add component entry with attributes and example usage.

#### api.md
**What:** API controllers, endpoints, request/response formats.
**When to update:** New API endpoints, changed response formats.
**How:** Add endpoint to the relevant controller section.

#### testing.md
**What:** Test organization, patterns, helper modules, fixture patterns.
**When to update:** New test patterns established, new fixture modules, new test helpers.
**How:** Add pattern or update existing description.

#### auth.md
**What:** Authentication flow, authorization checks, role-based access.
**When to update:** Auth logic changed, new roles, new permission checks.
**How:** Update relevant auth section.

#### data-layer.md
**What:** Database queries, preloading patterns, Ecto query patterns.
**When to update:** New complex queries, preloading strategies changed.
**How:** Add query pattern example.

#### gamification.md
**What:** XP system, levels, activity tracking logic.
**When to update:** New XP-earning actions, level thresholds changed.
**How:** Update the relevant gamification section.

### 5-style-guides/ Files

These define code conventions per architectural layer. Only update when a new convention is established or an existing one changes based on actual code patterns. Do NOT update just because new code was written following existing conventions.

## project_doc/ Update Targets

### specifications/data-model.md
**What:** ER diagrams (mermaid), schema field definitions, relationships.
**When to update:** New tables, new fields, changed relationships.
**How:**
- Add entity to mermaid ER diagram
- Add relationship lines between entities
- Add field definition table for new schema

### design/pages/NN-page-name.md
**What:** Page layout descriptions, component placement, user interactions.
**When to update:** UI elements added/removed, new sections, new modals, changed interactions.
**How:** Update the relevant page section describing what the user sees and can do.

### specifications/api-endpoints.md
**What:** REST API endpoint documentation.
**When to update:** New endpoints added, request/response formats changed.
**How:** Add endpoint with method, path, params, response format.
