### UI/UX Design System Guide: "Dark Premium" Aesthetic

This guide defines the visual language (DNA) of Total 66. By strictly adhering to these rules for colors, typography, shapes, and spacing, you can build unlimited pages with different structures that all feel intense, disciplined, and visually identical to the dark fitness style established across the project.

---

### 1. The Color Palette

**Philosophy:** A deep, near-black canvas where accent colors burn with purpose. Pure white is never used — warmth comes from slightly desaturated off-whites. Depth comes from colored glows, not grey shadows.

#### **Backgrounds (The Canvas)**

- **Global Background:** `#0a0a0a` (Void Black)
- _Usage:_ The main page background behind everything. Never use pure `#000000`.

- **Surface (Cards):** `#131313` (Card Dark)
- _Usage:_ All containers, panels, content blocks, feed entries.

- **Surface Hover:** `#1a1a1a` (Card Hover)
- _Usage:_ Card hover states, pressed states.

- **Elevated (Modals/Dropdowns):** `#1c1c1c` (Elevated Dark)
- _Usage:_ Dropdowns, modals, sidebar on mobile, popovers.

- **Input Fields:** `#0f0f0f` (Input Dark)
- _Usage:_ Form inputs, textareas, search bars. Slightly darker than cards.

- **Separators:** `rgba(255, 255, 255, 0.06)` (Ghost Line)
- _Usage:_ Borders, dividers, card outlines. Semi-transparent, never solid grey.

#### **Typography Colors**

- **Primary Text:** `#f0ece6` (Warm White)
- _Usage:_ Headings, names, important values, stat numbers.

- **Secondary Text:** `#8a8680` (Warm Grey)
- _Usage:_ Body text, descriptions, non-critical content.

- **Tertiary Text:** `#5a5754` (Faded Grey)
- _Usage:_ Placeholders, captions, timestamps, micro-labels, inactive icons.

#### **Accent & Interactive Colors**

- **Primary Brand:** `#ff4d00` (Total Orange)
- _Usage:_ Main CTAs, active nav states, progress bars, primary focus.

- **Primary Hover/Gradient:** `#ff8a50` (Light Orange)
- _Usage:_ Hover states, gradient endpoints, secondary accent.

- **Primary Glow:** `rgba(255, 77, 0, 0.15)` (Orange Glow)
- _Usage:_ Active badges, selected states, button ambience, nav highlights.

- **Secondary Brand:** `#00d4aa` (Evolution Cyan)
- _Usage:_ Evolution challenge type, secondary feature accents.

- **Tertiary Brand:** `#a855f7` (Custom Purple)
- _Usage:_ Custom/user-created items, third challenge variant.

- **Trophy:** `#ffc642` (Gold)
- _Usage:_ Achievements, finisher badges, reward states.

- **Functional Colors (Dim Variants):**
    - _Success:_ Bg: `rgba(34, 197, 94, 0.12)` / Text: `#22c55e`
    - _Warning:_ Bg: `rgba(234, 179, 8, 0.12)` / Text: `#eab308`
    - _Error:_ Bg: `rgba(239, 68, 68, 0.12)` / Text: `#ef4444`
    - _Info:_ Bg: `rgba(59, 130, 246, 0.12)` / Text: `#3b82f6`

**Critical rule:** Semantic colors are never used at full opacity for backgrounds. Always use the dim/glow variant (10–15% opacity) as the background with the full-strength color for text and icons.

---

### 2. Shape & Form (The "Dark Premium" Look)

The defining characteristic of this style is **controlled intensity**. Surfaces are dark and quiet; accents burn through with color.

#### **Border Radius (The Roundness)**

- **Large Containers (Cards, Modals):** `16px`
- **Medium Elements (Inputs, Dropdowns, Inner Blocks):** `12px`
- **Small Elements (Buttons, Tags):** `8–10px`
- **Pill Elements (Badges, Nav Filters):** `100px` (Full Pill)
- **Avatars:** `50%` (Circle)
- **Mood/Data Cells:** `8px`
- **Progress Bars:** `10px`

_Rule:_ Buttons use `12–14px` radius. Badges and nav pills use `100px`. Cards always `16px`. Nothing uses sharp `0px` corners.

#### **Shadows (The Depth)**

Avoid traditional grey box-shadows entirely. All depth is communicated through colored glows and border brightness changes.

- **Card Hover:** `0 16px 40px rgba(0, 0, 0, 0.3)` + `border-color: rgba(255, 255, 255, 0.1)`
- **Dropdown/Modal:** `0 20px 60px rgba(0, 0, 0, 0.6)`
- **Accent Button Glow:** `0 0 40px rgba(255, 77, 0, 0.2)`
- **Accent Button Hover Glow:** `0 0 60px rgba(255, 77, 0, 0.35)`
- **Success Glow:** `0 0 40px rgba(34, 197, 94, 0.2)`

_Rule:_ On dark backgrounds, depth comes from darkness intensification (deeper black shadows) and edge lightening (brighter borders on hover), not from light/grey shadow spread.

#### **Texture**

Every page carries a subtle noise texture overlay via a fixed pseudo-element:

```css
body::before {
	content: '';
	position: fixed;
	top: 0;
	left: 0;
	width: 100%;
	height: 100%;
	background-image: url('data:image/svg+xml,...fractalNoise...');
	opacity: 0.03;
	pointer-events: none;
	z-index: 9999;
}
```

This gives a subtle film-grain quality to all surfaces. Never remove it — it is part of the brand identity.

---

### 3. Typography System

**Display Font:** **Bebas Neue** — condensed, uppercase display font for all headings, stat values, and labels.
**Body Font:** **DM Sans** — clean geometric sans-serif for all body text, buttons, and UI content.

```html
<link
	href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=DM+Sans:ital,wght@0,400;0,500;0,700;1,400&display=swap"
	rel="stylesheet"
/>
```

| Role            | Font       | Size                         | Weight | Spacing |
| --------------- | ---------- | ---------------------------- | ------ | ------- |
| H1 (Hero)       | Bebas Neue | `clamp(2.2rem, 5vw, 3.4rem)` | 400    | 3px     |
| H2 (Page Title) | Bebas Neue | `clamp(2rem, 4vw, 3rem)`     | 400    | 2px     |
| H3 (Section)    | Bebas Neue | `1.6rem`                     | 400    | 2px     |
| H4 (Card Title) | Bebas Neue | `1.4rem`                     | 400    | 2px     |
| Stat Value      | Bebas Neue | `2rem`                       | 400    | 0       |
| Body            | DM Sans    | `0.9rem`                     | 400    | 0       |
| Body Small      | DM Sans    | `0.85rem`                    | 400    | 0       |
| Button Text     | DM Sans    | `0.85rem`                    | 700    | 2px     |
| Caption/Label   | DM Sans    | `0.7rem`                     | 700    | 2px     |
| Micro Label     | DM Sans    | `0.6rem`                     | 700    | 3px     |
| Nav Link        | DM Sans    | `0.78rem`                    | 400    | 1px     |

_Line Height:_ `1.7` for body text. `1.1` for Bebas Neue headings.

**Critical convention:** All labels, badges, nav links, section headers, and buttons use `text-transform: uppercase` with `letter-spacing: 1–3px`. This creates the athletic/performance voice of the brand.

---

### 4. Spacing Rules (Whitespace)

Generous dark space makes the UI feel powerful and focused. Content breathes inside wide dark margins.

- **Padding Inside Cards:** `28–32px` (Never less than 24px).
- **Gap Between Elements Inside Card:** `14–20px`.
- **Gap Between Cards/Sections:** `20–24px`.
- **Main Content Top Padding:** `88px` (accounts for 64px fixed nav + breathing room).
- **Main Content Side Padding:** `40px` desktop, `20px` tablet, `16px` mobile.
- **Nav Height:** `64px` (fixed, always).
- **Sidebar Width:** `260px` (fixed, collapses on mobile).

---

### 5. Component Styles (Reusable Elements)

#### **Buttons**

- **Primary (CTA):** Solid `#ff4d00` background, white text, no border. `14px` radius. Orange glow shadow. Hover: `translateY(-2px)` + intensified glow.
- **Secondary:** `#131313` background, `rgba(255,255,255,0.06)` border, `#8a8680` text. Hover: brighter border + primary text color.
- **Danger:** `rgba(239,68,68,0.12)` background, `#ef4444` text, red-tinted border. Hover: solid red fill, white text.
- **Ghost/Pill (Filters):** Transparent background, ghost border, muted text. Active: accent color + glow background.
- **Icon Button (Task Actions):** `34×34px`, `8px` radius, ghost border. Done = green fill. Fail = red fill.

_Rule:_ All button text is uppercase with `letter-spacing: 1.5–2px` and `font-weight: 700`.

#### **Input Fields**

- **Background:** `#0f0f0f` (darker than cards — inputs recede into surfaces).
- **Border:** `1px solid rgba(255, 255, 255, 0.08)`.
- **Focus:** `border-color: rgba(255, 77, 0, 0.4); box-shadow: 0 0 0 3px rgba(255, 77, 0, 0.08);`
- **Height:** Padding `14px 16px` (tall and comfortable).
- **Radius:** `12px`.
- **Placeholder:** `#5a5754` (Faded Grey).
- **Date inputs:** Apply `color-scheme: dark` for native dark pickers.

_Rule:_ Labels sit above inputs, always uppercase micro-labels (`0.68rem`, `700 weight`, `2px` letter-spacing, `#5a5754` color).

#### **Cards**

- **Background:** `#131313`.
- **Border:** `1px solid rgba(255, 255, 255, 0.06)`.
- **Radius:** `16px`.
- **Padding:** `28px`.
- **Hover (interactive):** Border brightens to `rgba(255, 255, 255, 0.1)`, card lifts `translateY(-4px)`, shadow deepens.

_Variant — Stat Card:_ Same base + a `2px` colored top-line via `::before` pseudo-element (orange, green, blue, or gold).

_Variant — Hub Card:_ Same base + `48×48px` icon block with colored dim background + title + description + footer with stats + arrow circle.

#### **Avatars**

- Always circles (`border-radius: 50%`).
- Background: `rgba(255, 255, 255, 0.06)`.
- Text: Initials in Bebas Neue, `#5a5754` color.
- Sizes: `32px` (nav), `40px` (dropdown), `42px` (feed), `56px` (member card), `110px` (profile page).
- Finisher badge: Gold circle overlay with 🏆 emoji.

#### **Badges & Tags**

- Shape: Pill (`border-radius: 100px`).
- Size: `0.6rem`, `700 weight`, `2px` letter-spacing, uppercase.
- Pattern: Colored text on matching dim background.
    - Orange badge: `color: #ff4d00; background: rgba(255, 77, 0, 0.15);`
    - Green badge: `color: #22c55e; background: rgba(34, 197, 94, 0.12);`
    - Blue badge: `color: #3b82f6; background: rgba(59, 130, 246, 0.12);`

#### **Progress Bars**

- Track: `10px` height, `10px` radius, `rgba(255,255,255,0.05)` background.
- Fill: `linear-gradient(90deg, #ff4d00, #ff8a50)` with a white sheen `::after`.
- Thin variant (sidebar): `4px` height.
- Animation: `transition: width 1s ease`.

#### **Images & Media**

- Not heavily used — the UI is data/text/emoji driven.
- If images appear: `border-radius: 12px`, `object-fit: cover`.
- Avatars are always circles.
- Future photography: dark/moody fitness imagery with warm orange color grading.

#### **Icons**

All icons are native emoji, not SVG icon libraries. This is intentional:

- Cross-platform consistency
- Personality and warmth inside a dark UI
- Zero library weight

---

### **How to Apply This Guide**

Whenever you create a new page (e.g., Settings, Messages, Leaderboard), ask:

1. **Is it dark?** (Is the background `#0a0a0a` with cards at `#131313`?)
2. **Is it intense?** (Are accents glowing against deep blacks, not floating on grey?)
3. **Is it breathable?** (Is there at least 28px of padding inside every card?)
4. **Is the hierarchy clear?** (Are Bebas Neue headings loud and DM Sans body text quiet?)
5. **Does it have texture?** (Is the noise overlay present?)
6. **Are borders ghosts?** (Are they `rgba(255,255,255,0.06)`, not solid grey?)

If the answer is **Yes** to all, your new pages will match the Total 66 design.

---

### 6. Design References

The Total 66 design is inspired by a **fitness performance dashboard** pattern crossed with **social accountability feeds**.

#### Reference A (Active Challenge Dashboard)

- Sidebar + main content layout for logged-in hub pages
- Fixed sidebar with navigation links, active-state left-border, and mini challenge progress card
- Main area: challenge header with progress bar, mood tracker grid (66 cells), daily task list with done/fail actions, and community feed with likes/comments
- Everything rendered on dark card surfaces with orange/green/red semantic feedback

#### Reference B (Public Pages — Homepage, Challenges, Members)

- Centered single-column layout (max-width 1100px)
- Hero section with giant watermark text, gradient glow, and bold Bebas Neue headline
- Content sections: rule grids, FAQ accordion, member card grids, challenge tab switchers
- No sidebar — clean, marketing-focused presentation

#### Reference C (Start Challenge Wizard)

- Centered narrow layout (max-width 780px)
- Multi-step stepper with animated transitions between panels
- Preset selection cards (3-column grid), task list with per-task schedule selectors, goal input, review summary
- Step progression: done (green) → active (orange) → pending (grey)

---

### 7. Layout Translation Rules (Total 66)

#### Desktop (861px+)

- **Hub pages:** Sidebar (260px fixed) + main content column
- **Public pages:** Centered content (max-width 780–1100px) + 40px side padding
- **Wizard pages:** Centered narrow (max-width 780px)
- Card grids: 2-column with `20px` gap
- Stat grids: 4-column with `16px` gap
- Member grids: `auto-fill, minmax(260px, 1fr)`

#### Tablet (601–860px)

- Sidebar collapses — hamburger menu triggers slide-in with dark overlay
- Main content goes full-width with `20px` side padding
- Card grids: 1 column
- Stat grids: 2 columns
- Mood tracker grid: 11 columns (from 22)

#### Mobile (≤500px)

- Single column stack for all content
- Stat grids: 1 column
- Nav: side padding `16px`, user name hidden
- Mood selectors and day pills: slightly smaller touch targets
- Buttons remain full-width and tall

---

### 8. Reusable Component Blueprint

Build pages by composing these atomic components. Each inherits the same design tokens.

**Navigation:**

- `TopNavBar` — fixed, blurred, with logo + links + avatar dropdown
- `Sidebar` — fixed left rail with links, badges, dividers, mini challenge card
- `UserDropdown` — animated popover with header + menu sections
- `HamburgerMenu` — mobile slide-in sidebar + overlay

**Content Shells:**

- `SectionCard` — generic white-on-dark card (`#131313`, `16px` radius, `28px` padding)
- `StatCard` — card with colored top-line and large Bebas Neue value
- `HubCard` — clickable card with icon block + title + description + stats footer + arrow

**Data Display:**

- `ProgressBar` — gradient fill with sheen effect
- `MoodGrid` — 66-cell grid with color-coded mood states
- `TaskRow` — icon + name + done/fail action buttons
- `FeedEntry` — date + mood badge + task bar + reflection + like/comment actions
- `AvatarInitials` — circle with Bebas Neue initials

**Forms:**

- `FormInput` — dark input with floating uppercase label
- `MoodSelector` — 3 large emoji buttons with selected glow state
- `DayPills` — 7 small day-of-week toggle buttons
- `SchedulePreset` — pill buttons (Every Day / Mon–Fri / Custom)
- `PresetCard` — selectable card with icon + name + description

**Feedback:**

- `Badge` — pill-shaped colored indicator
- `TaskTag` — Required (orange) / Optional (grey) / Custom (purple)
- `FinisherBadge` — gold circle with trophy
- `Stepper` — horizontal step dots with connecting lines

Each component must inherit:

- Radius tokens (`16 / 12 / 8 / 100px pill`)
- Shadow tokens (colored glows, not grey)
- Type scale (Bebas Neue for display, DM Sans for body)
- Color rules from sections 1 and 2
- Noise texture from body overlay

---

### 9. Interaction & Motion

- **Hover on cards:** Lift `translateY(-4px)` + border brightens + shadow deepens. Duration: `350ms`.
- **Hover on buttons:** Lift `translateY(-2px)` + glow intensifies. Duration: `300ms`.
- **Dropdown open:** Fade in + scale from `0.97` to `1` + slide down `8px`. Duration: `250ms`, `cubic-bezier(0.25, 0.46, 0.45, 0.94)`.
- **Sidebar slide (mobile):** `transform: translateX`, `300ms ease`.
- **Scroll-triggered fade-in:** Elements start `opacity: 0; translateY(20px)`, animate to visible on intersection. Duration: `600ms`, stagger: `60ms` per sibling.
- **Progress bar fill:** `transition: width 1s ease`.
- **Tab/panel switch:** `fadeUp` keyframe — `opacity 0→1`, `translateY 16px→0`. Duration: `400ms`.
- **Success animation:** `popIn` keyframe — `scale(0)→scale(1)`. Duration: `500ms`, `cubic-bezier(0.175, 0.885, 0.32, 1.275)`.

_Rule:_ Never use spring/bounce easing on UI elements. Keep motion smooth and purposeful. Respect `prefers-reduced-motion`.

---

### 10. Page-Level Consistency Checklist

Before shipping any Total 66 page, verify:

1. Is the background `#0a0a0a` with cards at `#131313`?
2. Is the noise texture overlay present on `body::before`?
3. Are all borders `rgba(255, 255, 255, 0.06)`, never solid grey?
4. Are headings in Bebas Neue and body text in DM Sans?
5. Are all labels/badges/nav uppercase with letter-spacing?
6. Are accent glows used instead of grey box-shadows?
7. Is the fixed 64px navbar present with blur backdrop?
8. Do interactive elements have hover state transitions (300ms)?
9. Do scroll-triggered elements use the `.anim` → `.vis` pattern?
10. Does the page use the correct layout (sidebar for hub, centered for public)?
11. Are challenge types color-coded (Classic = orange, Evolution = cyan, Custom = purple)?
12. Do all inputs use the dark input background (`#0f0f0f`) with orange focus ring?
13. Is responsive behavior correct (sidebar collapses at 860px, grids adapt)?
14. Are touch targets at least 38px on mobile?

If the answer is **Yes** to all, the page is ready.
