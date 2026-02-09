---
name: ux-ui
description: "UI/UX redesign and improvement skill for HeadsUp pages and components. Responsible for implementing the 'Soft Modern' design system across all pages. Use when: (1) Redesigning or improving any page's UI/layout, (2) Creating or refactoring reusable Phoenix function components, (3) Auditing current UI against the design system, (4) Updating design documentation in project_doc/docs/design/, (5) Building mobile-first responsive layouts, (6) Implementing the 3-column social feed layout pattern. Triggers on requests involving visual redesign, component extraction, UI improvements, mobile responsiveness, or design system compliance."
argument-hint: "<page-name|component|audit|all>"
---

# HeadsUp UX/UI Redesign Skill

Redesign and improve HeadsUp pages using the "Soft Modern" aesthetic with mobile-first, component-driven architecture.

## Source of Truth

1. **Primary**: `project_doc/docs/design/ux-ui.md` - Design system DNA
2. **Secondary**: `project_doc/docs/design/style-guide.md` - Brand foundations
3. **Page specs**: `project_doc/docs/design/pages/*.md` - Per-page wireframes

If guidance conflicts between files, `ux-ui.md` takes priority.

## Design References

The UI follows a **social media feed** pattern inspired by these reference designs:
- 3-column layout: left sidebar (categories/nav), center feed, right sidebar (suggestions/popular)
- Warm blush background (`#FFF5F2`) with white cards
- Rounded corners (24px cards, 12px buttons), soft shadows
- Avatar-driven post cards with engagement metrics
- Pastel-colored tags/badges
- Mobile: collapses to single-column with bottom nav

## Arguments

- `$ARGUMENTS` = target to redesign

| Argument | Action |
|----------|--------|
| `home` | Redesign home/landing page |
| `goals` | Redesign goals listing page |
| `goal-detail` | Redesign single goal view |
| `challenges` | Redesign challenges pages |
| `profile` | Redesign user profile page |
| `create` | Redesign create goal/challenge forms |
| `groups` | Redesign groups page |
| `people` | Redesign people/connections page |
| `admin` | Redesign admin pages |
| `component:<name>` | Create/improve a specific reusable component |
| `audit` | Audit all pages against design system |
| `all` | Full redesign of all pages |

## Workflow

### Step 1: Read Design Context

1. Read `project_doc/docs/design/ux-ui.md` (design DNA)
2. Read the relevant page spec from `project_doc/docs/design/pages/`
3. Read current implementation files (LiveView + templates)
4. Read `lib/heads_up_web/components/` for existing shared components

### Step 2: Identify Reusable Components

Before writing any page-level code, extract shared UI elements into function components.

**Component location**: `lib/heads_up_web/components/`

**Component checklist** - see `references/component-library.md` for full patterns:
- `avatar.ex` - User avatars (sizes: sm/md/lg/xl)
- `card.ex` - Base card wrapper with soft shadow
- `post_card.ex` - Feed post card (avatar, content, media, engagement)
- `tag.ex` - Pastel tag/badge component
- `stat_badge.ex` - Numeric stat with label
- `sidebar_card.ex` - Right sidebar suggestion/popular card
- `category_card.ex` - Left sidebar category card
- `empty_state.ex` - Empty state with icon + message + CTA
- `skeleton.ex` - Loading skeleton components
- `engagement_bar.ex` - Like/comment/share action bar
- `progress_bar.ex` - Goal/challenge progress indicator
- `section_header.ex` - Section title with "View All" link
- `user_mini_card.ex` - Small user card for suggestions/mentions
- `bottom_nav.ex` - Mobile bottom navigation bar

### Step 3: Implement Mobile-First

Build all layouts mobile-first using Tailwind breakpoints:

```
/* Base = mobile (0-639px) */
<div class="flex flex-col gap-4">

/* Tablet (sm: 640px+) */
<div class="sm:grid sm:grid-cols-2 sm:gap-6">

/* Desktop (lg: 1024px+) */
<div class="lg:grid lg:grid-cols-12 lg:gap-8">
  <aside class="hidden lg:block lg:col-span-3">  <!-- Left sidebar -->
  <main class="lg:col-span-6">                    <!-- Center feed -->
  <aside class="hidden lg:block lg:col-span-3">  <!-- Right sidebar -->
</div>
```

**Mobile patterns:**
- Single column stack
- Bottom navigation bar (fixed)
- Horizontal scroll for categories
- Cards full-width with 16px padding
- Tap-friendly targets (min 44px)

### Step 4: Apply Design Tokens

Apply these exact values from the design system:

| Token | Value | Tailwind |
|-------|-------|----------|
| Background | `#FFF5F2` | `bg-[#FFF5F2]` |
| Card bg | `#FFFFFF` | `bg-white` |
| Card radius | `24px` | `rounded-3xl` |
| Card shadow | `0 4px 20px rgba(0,0,0,0.05)` | `shadow-[0_4px_20px_rgba(0,0,0,0.05)]` |
| Card padding | `24px` | `p-6` |
| Button radius | `12px` or pill | `rounded-xl` or `rounded-full` |
| Input bg | `#F9FAFB` | `bg-gray-50` |
| Input radius | `12px` | `rounded-xl` |
| Input height | `48px` | `h-12` |
| Primary text | `#111827` | `text-gray-900` |
| Secondary text | `#6B7280` | `text-gray-500` |
| Tertiary text | `#9CA3AF` | `text-gray-400` |
| Primary brand | `#FF6B6B` | `text-[#FF6B6B]` |
| Interactive blue | `#3B82F6` | `text-blue-500` |
| Gap between cards | `24px` | `gap-6` |
| Gap between elements | `16px` | `gap-4` |

### Step 5: Build the Page

1. Create/update the LiveView render function
2. Use extracted components via function calls
3. Implement all states: loaded, loading (skeletons), empty, error
4. Test responsive behavior at all breakpoints

### Step 6: Update Design Docs

After implementation, update the relevant page doc in `project_doc/docs/design/pages/`:
- Mark implemented sections
- Note any deviations from the spec
- Add component references used

## Component Architecture Rules

1. **One component per file** in `lib/heads_up_web/components/`
2. **Use `attr` and `slot`** declarations for all function components
3. **Default variants** via `attr :variant, :atom, default: :default`
4. **Size props** via `attr :size, :atom, values: [:sm, :md, :lg], default: :md`
5. **Composable** - components accept slots for customization
6. **No business logic** - components are purely presentational

## References

- **references/component-library.md** - Full component patterns with code examples
- **references/design-tokens.md** - Complete design token reference and Tailwind mappings
