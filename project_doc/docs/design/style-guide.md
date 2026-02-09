# Style Guide

> This document defines the visual identity and design preferences for Total 66.
> The AI agent should follow these guidelines for all UI development.

---

## 1. Brand Identity

### Project Name

**Name:** Total 66
**Tagline:** 66 Days. Total Transformation.

### Logo

**Logo Status:**

- [ ] I will provide a logo file (place in `/assets/logo/`)
- [x] Generate a text-based logo using the project name
- [ ] No logo needed for MVP

**Logo Treatment:**

- Text: `TOTAL 66` in Bebas Neue, 1.5rem, letter-spacing 4px
- "TOTAL" in `#f0ece6` (text-primary), "66" in `#ff4d00` (accent orange)
- Uppercase, no icon — typographic only

**Logo Usage Rules:**

- Minimum size: 120px width
- Clear space around logo: equal to the height of the logo text
- Never stretch, distort, or recolor the logo
- Always render on dark backgrounds (#0a0a0a or darker)

---

## 2. Color Palette

### Primary Colors

| Role              | Color Name   | Hex Code              | Usage                                |
| ----------------- | ------------ | --------------------- | ------------------------------------ |
| **Primary**       | Total Orange | `#ff4d00`             | Main CTAs, active states, highlights |
| **Primary Hover** | Light Orange | `#ff8a50`             | Hover/secondary accent, gradients    |
| **Primary Glow**  | Orange Glow  | `rgba(255,77,0,0.15)` | Backgrounds, badges, glows           |

### Secondary Colors

| Role           | Color Name  | Hex Code                | Usage                                  |
| -------------- | ----------- | ----------------------- | -------------------------------------- |
| **Cyan**       | Evolution   | `#00d4aa`               | Evolution challenge, secondary accents |
| **Cyan Glow**  | Cyan Dim    | `rgba(0,212,170,0.12)`  | Cyan backgrounds, badges               |
| **Gold**       | Trophy      | `#ffc642`               | Achievements, finisher badge, trophies |
| **Gold Glow**  | Gold Dim    | `rgba(255,198,66,0.15)` | Gold backgrounds                       |
| **Purple**     | Custom      | `#a855f7`               | Custom tasks, user-defined items       |
| **Purple Dim** | Purple Glow | `rgba(168,85,247,0.12)` | Purple backgrounds                     |

### Neutral Colors (Dark Theme)

| Role               | Color Name    | Hex Code                 | Usage                         |
| ------------------ | ------------- | ------------------------ | ----------------------------- |
| **Background**     | Void Black    | `#0a0a0a`                | Page background               |
| **Surface**        | Card Dark     | `#131313`                | Cards, panels                 |
| **Surface Hover**  | Card Hover    | `#1a1a1a`                | Hovered card surfaces         |
| **Elevated**       | Elevated Dark | `#1c1c1c`                | Dropdowns, modals, sidebar    |
| **Input BG**       | Input Dark    | `#0f0f0f`                | Form inputs, textareas        |
| **Text Primary**   | Warm White    | `#f0ece6`                | Headings, important text      |
| **Text Secondary** | Warm Grey     | `#8a8680`                | Body text, descriptions       |
| **Text Muted**     | Faded Grey    | `#5a5754`                | Placeholders, hints, captions |
| **Border**         | Ghost Line    | `rgba(255,255,255,0.06)` | Borders, dividers             |
| **Border Input**   | Input Line    | `rgba(255,255,255,0.08)` | Form borders                  |

### Semantic Colors

| Role            | Color Name | Hex Code                | Usage                          |
| --------------- | ---------- | ----------------------- | ------------------------------ |
| **Success**     | Green      | `#22c55e`               | Task done, completed, positive |
| **Success Dim** | Green Dim  | `rgba(34,197,94,0.12)`  | Success backgrounds            |
| **Warning**     | Yellow     | `#eab308`               | Okay mood, caution states      |
| **Warning Dim** | Yellow Dim | `rgba(234,179,8,0.12)`  | Warning backgrounds            |
| **Error**       | Red        | `#ef4444`               | Failed tasks, errors, danger   |
| **Error Dim**   | Red Dim    | `rgba(239,68,68,0.12)`  | Error backgrounds              |
| **Info**        | Blue       | `#3b82f6`               | Messages, info states          |
| **Info Dim**    | Blue Dim   | `rgba(59,130,246,0.12)` | Info backgrounds               |

### Color Preferences (Plain Language)

Primary color preference:
A bold, fiery orange that conveys discipline, energy, and transformation intensity.

Colors to AVOID:
Pastels, light/airy tones, any bright backgrounds. This is a dark-first design.

Overall feeling:
Dark, intense, premium fitness aesthetic. Like a high-end gym meets a performance dashboard.

---

## 3. Typography

### Font Families

**Display Font (Headings & Titles):**

- Font: Bebas Neue
- Source: Google Fonts
- Weights needed: 400 (single weight)
- Usage: All headings, stat values, badges, navigation labels, hero text
- Always uppercase by nature of the font

**Body Font (Primary):**

- Font: DM Sans
- Source: Google Fonts
- Weights needed: 400, 500, 700, 400 italic
- Usage: Body text, paragraphs, form inputs, buttons, descriptions

**Font Import:**

```html
<link
	href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=DM+Sans:ital,wght@0,400;0,500;0,700;1,400&display=swap"
	rel="stylesheet"
/>
```

**Font Preference (Plain Language):**

Style preference:
[x] Display contrast — condensed all-caps display font (Bebas Neue) paired with a clean geometric sans-serif (DM Sans) for hierarchy and impact

### Type Scale

| Element         | Font Family | Size                       | Weight | Line Height | Letter Spacing |
| --------------- | ----------- | -------------------------- | ------ | ----------- | -------------- |
| Hero/H1         | Bebas Neue  | clamp(2.2rem, 5vw, 3.4rem) | 400    | 1.1         | 3px            |
| H2              | Bebas Neue  | clamp(2rem, 4vw, 3rem)     | 400    | 1.1         | 2px            |
| H3 / Section    | Bebas Neue  | 1.6rem                     | 400    | 1.2         | 2px            |
| H4 / Card Title | Bebas Neue  | 1.4rem                     | 400    | 1.2         | 2px            |
| H5 / Subtitle   | Bebas Neue  | 1.2rem                     | 400    | 1.3         | 2px            |
| Stat Value      | Bebas Neue  | 2rem                       | 400    | 1.0         | 0              |
| Body Large      | DM Sans     | 0.95rem                    | 400    | 1.7         | 0              |
| Body            | DM Sans     | 0.9rem                     | 400    | 1.7         | 0              |
| Body Small      | DM Sans     | 0.85rem                    | 400    | 1.6         | 0              |
| Caption/Label   | DM Sans     | 0.7rem                     | 700    | 1.4         | 2px            |
| Micro Label     | DM Sans     | 0.6rem                     | 700    | 1.4         | 3px            |
| Button          | DM Sans     | 0.85rem                    | 700    | 1.0         | 2px            |
| Nav Link        | DM Sans     | 0.78rem                    | 400    | 1.0         | 1px            |

**Label Convention:**
All labels, badges, nav links, and section headers use `text-transform: uppercase` with letter-spacing of 1–3px. This is a core part of the brand voice.

---

## 4. Visual Style

### Overall Aesthetic

**Primary Style:**

- [x] **Dark/Premium** — Deep blacks, intense accent colors, fitness-industry energy, noise texture overlays

### Texture Overlay

Every page has a subtle noise texture applied via a fixed `::before` pseudo-element on `<body>`:

```css
body::before {
	content: '';
	position: fixed;
	top: 0;
	left: 0;
	width: 100%;
	height: 100%;
	background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)' opacity='0.03'/%3E%3C/svg%3E");
	pointer-events: none;
	z-index: 9999;
}
```

This gives a subtle film-grain texture to all surfaces. Never remove this.

### Border Radius (Roundness)

- [x] **Moderately Rounded** — 10px–16px (premium, not bubbly)

| Element          | Radius                 |
| ---------------- | ---------------------- |
| Buttons (large)  | 14px                   |
| Buttons (small)  | 8–10px                 |
| Cards            | 16px                   |
| Input fields     | 12px                   |
| Modals/Dropdowns | 14px                   |
| Avatars          | 50% (circle)           |
| Tags/Badges      | 100px (pill)           |
| Mood day cells   | 8px                    |
| Progress bars    | 10px                   |
| Sidebar links    | 0 (left border accent) |

### Shadows

**Shadow Style:**

- [x] **Glow-based** — Colored ambient glows instead of traditional grey box-shadows

**Shadow Definitions:**

```css
/* Cards on hover */
shadow-card-hover: 0 16px 40px rgba(0, 0, 0, 0.3);

/* Dropdown menus */
shadow-dropdown: 0 20px 60px rgba(0, 0, 0, 0.6);

/* Primary button glow */
shadow-accent: 0 0 40px rgba(255, 77, 0, 0.2);
shadow-accent-hover: 0 0 60px rgba(255, 77, 0, 0.35);

/* Success button glow */
shadow-success: 0 0 40px rgba(34, 197, 94, 0.2);

/* Start button (elevated) */
shadow-start: 0 0 50px rgba(255, 77, 0, 0.25);
```

Traditional grey box-shadows are NOT used. All depth is communicated via colored glows and border interactions.

### Spacing System

Base unit: 4px

| Token | Value | Usage                            |
| ----- | ----- | -------------------------------- |
| xs    | 4px   | Tight spacing, pill gaps         |
| sm    | 8px   | Related elements, tag padding    |
| md    | 16px  | Standard padding, card internals |
| lg    | 24px  | Section spacing, card padding    |
| xl    | 32px  | Large card padding, section gaps |
| 2xl   | 48px  | Major section separation         |
| 3xl   | 64px  | Page section spacing             |
| 4xl   | 80px  | Top padding (below fixed nav)    |

---

## 5. UI Components

### Buttons

**Primary Button (CTA):**

```css
background: #ff4d00;
color: #ffffff;
border: none;
border-radius: 14px;
padding: 18px;
font-weight: 700;
font-size: 0.85rem;
letter-spacing: 2px;
text-transform: uppercase;
box-shadow: 0 0 40px rgba(255, 77, 0, 0.2);
```

- Hover: translateY(-2px) + stronger glow
- Active: translateY(0)

**Secondary Button:**

```css
background: var(--bg-card);
color: var(--text-secondary);
border: 1px solid var(--border);
border-radius: 12px;
padding: 14px 28px;
font-weight: 700;
letter-spacing: 1.5px;
text-transform: uppercase;
```

- Hover: brighter border + text-primary color

**Danger Button:**

```css
background: rgba(239, 68, 68, 0.12);
color: #ef4444;
border: 1px solid rgba(239, 68, 68, 0.3);
border-radius: 10px;
```

- Hover: solid red background, white text

**Ghost/Pill Button (Tags, Filters):**

```css
background: none;
border: 1px solid var(--border);
border-radius: 100px;
padding: 6px 14px;
color: var(--text-secondary);
font-size: 0.78rem;
text-transform: uppercase;
letter-spacing: 1px;
```

- Active state: accent color + accent-glow background

**Task Action Button (Small Icon):**

```css
width: 34px;
height: 34px;
border-radius: 8px;
border: 1px solid var(--border);
background: none;
```

- Done state: green fill, white icon
- Fail state: red fill, white icon

**Button Sizes:**

| Size      | Padding       | Font Size | Radius |
| --------- | ------------- | --------- | ------ |
| Small     | 6px 14px      | 0.75rem   | 8px    |
| Medium    | 14px 28px     | 0.85rem   | 12px   |
| Large     | 18px (full-w) | 0.9rem    | 14px   |
| XL (hero) | 20px (full-w) | 1rem      | 14px   |

### Form Inputs

**Text Input / Textarea:**

```css
background: #0f0f0f;
border: 1px solid rgba(255, 255, 255, 0.08);
border-radius: 12px;
padding: 14px 16px;
color: #f0ece6;
font-family: 'DM Sans', sans-serif;
font-size: 0.9rem;
```

- Focus: `border-color: rgba(255, 77, 0, 0.4); box-shadow: 0 0 0 3px rgba(255, 77, 0, 0.08);`
- Placeholder: `color: #5a5754;`
- Date inputs: `color-scheme: dark;`

**Labels:**

- Position: Above input
- Font: DM Sans, 0.68rem, weight 700
- Text-transform: uppercase
- Letter-spacing: 2px
- Color: `#5a5754` (text-muted)

**Password Strength Meter:**

- 4-segment bar: weak (red) → fair (yellow) → good (cyan) → strong (green)
- Animated fill transitions

### Cards

**Standard Card:**

```css
background: #131313;
border: 1px solid rgba(255, 255, 255, 0.06);
border-radius: 16px;
padding: 28px;
```

- Hover: `border-color: rgba(255, 255, 255, 0.1); transform: translateY(-4px); box-shadow: 0 16px 40px rgba(0, 0, 0, 0.3);`

**Stat Card (with color top-line):**

```css
/* Same as standard + */
position: relative;
overflow: hidden;
```

- `::before` pseudo-element at top, 2px height, full-width colored bar
- Hover: translateY(-2px)

**Hub Card (large clickable):**

- Standard card + icon block (48px, 14px radius, colored dim background) + title + description + footer with stats + arrow circle

**Challenge Type Convention:**

- Classic → Orange accent (`#ff4d00`)
- Evolution → Cyan accent (`#00d4aa`)
- Custom → Purple accent (`#a855f7`)

### Navigation

**Top Navbar (Fixed):**

```css
position: fixed;
top: 0;
height: 64px;
backdrop-filter: blur(20px);
background: rgba(10, 10, 10, 0.85);
border-bottom: 1px solid rgba(255, 255, 255, 0.06);
z-index: 200;
```

- Logo left, page links center-left, user avatar/dropdown right
- Nav links: uppercase, 0.78rem, 1px letter-spacing
- Active link: orange text + orange glow background

**Sidebar (Hub pages):**

```css
position: fixed;
top: 64px;
width: 260px;
background: #131313;
border-right: 1px solid rgba(255, 255, 255, 0.06);
```

- Links: left-aligned with 3px left border (transparent default, accent when active)
- Active: orange text + glow background + orange left border
- Badges: pill-shaped, colored dim backgrounds
- Active challenge mini-card at bottom with progress bar

**User Dropdown:**

```css
width: 250px;
background: #1c1c1c;
border: 1px solid rgba(255, 255, 255, 0.06);
border-radius: 14px;
box-shadow: 0 20px 60px rgba(0, 0, 0, 0.6);
```

- Animated: opacity + translateY + scale transition
- Header with avatar + name + @nickname
- Sections separated by 1px borders
- Logout item: red colored

### Avatars

**Avatar (No Image):**

```css
border-radius: 50%;
background: rgba(255, 255, 255, 0.06);
font-family: 'Bebas Neue', sans-serif;
color: #5a5754;
letter-spacing: 1px;
```

| Context         | Size  | Font Size |
| --------------- | ----- | --------- |
| Nav avatar      | 32px  | 0.85rem   |
| Dropdown        | 40px  | 1rem      |
| Feed item       | 42px  | 0.85rem   |
| Comment         | 30px  | 0.6rem    |
| Member card     | 56px  | 1.1rem    |
| Profile (large) | 110px | 2.5rem    |

### Badges & Tags

**Standard Badge (Pill):**

```css
font-size: 0.6rem;
font-weight: 700;
padding: 2px 7px;
border-radius: 100px;
text-transform: uppercase;
letter-spacing: 1.5px;
```

- Orange: `color: #ff4d00; background: rgba(255,77,0,0.15);`
- Blue: `color: #3b82f6; background: rgba(59,130,246,0.12);`
- Green: `color: #22c55e; background: rgba(34,197,94,0.12);`

**Task Tags:**

| Type     | Color  | Background             |
| -------- | ------ | ---------------------- |
| Required | Orange | accent-glow            |
| Optional | Grey   | rgba(255,255,255,0.04) |
| Custom   | Purple | purple-dim             |

**Finisher Badge:**

- Gold circle with trophy emoji, positioned as overlay on avatar
- `background: #ffc642; color: #0a0a0a; box-shadow: 0 2px 8px rgba(255,198,66,0.3);`

### Progress Bars

```css
/* Track */
height: 10px;
border-radius: 10px;
background: rgba(255, 255, 255, 0.05);
overflow: hidden;

/* Fill */
background: linear-gradient(90deg, #ff4d00, #ff8a50);
border-radius: 10px;
transition: width 1s ease;
```

- Sheen effect: `::after` pseudo with gradient white highlight at leading edge
- Thin variant (sidebar): height 4px

### Mood Tracker

**66-Day Grid:**

- `grid-template-columns: repeat(22, 1fr);` (3 rows of 22)
- Cell: square aspect-ratio, 8px radius

| Mood     | Emoji | Background Color                          |
| -------- | ----- | ----------------------------------------- |
| Good     | 😊    | `rgba(34, 197, 94, 0.12)`                 |
| Okay     | 😐    | `rgba(234, 179, 8, 0.12)`                 |
| Not Good | 😞    | `rgba(239, 68, 68, 0.12)`                 |
| No Mood  | ·     | `rgba(255, 255, 255, 0.03)`               |
| Future   | —     | `rgba(255, 255, 255, 0.015)` opacity: 0.4 |
| Today    | —     | + `box-shadow: 0 0 0 2px #ff4d00` ring    |

- Hover: `transform: scale(1.2)` with tooltip showing day + mood label

**Phase Labels Above Grid:**

- 3 equal segments: Destruction (1–22), Installation (23–44), Integration (45–66)
- Active phase: orange text + orange bottom border

### Mood Selector (Daily Input)

- 3 large buttons (56×56px, 14px radius)
- Emoji centered, label below
- Selected state: colored border + dim background + box-shadow glow + scale(1.1)

### Feed / Activity Items

**Feed Entry Card:**

```css
background: #131313;
border: 1px solid rgba(255, 255, 255, 0.06);
border-radius: 16px;
padding: 24px;
```

Components:

- Top row: date + day number (Bebas Neue) | mood badge (pill)
- Stats row: tasks done/total + failed count
- Task bar: stacked green (done) + red (failed) + grey (remaining)
- Reflection: italic quote in darker bg with left border accent
- Actions: like button (toggle ❤️/🤍) + comment button with count
- Collapsible comments list + comment input

**Like Button:**

```css
/* Default */
color: var(--text-muted);
/* Liked */
color: #ef4444;
```

### Accordion (FAQ)

- Toggle icon rotates on open
- Content area slides in with max-height animation
- Only one open at a time
- Border-bottom separator between items

### Stepper (Multi-Step Wizard)

- Horizontal dots with connecting lines
- States: done (green fill + checkmark), active (orange outline + glow), default (grey outline)
- Step transitions: fadeUp animation (opacity + translateY)

---

## 6. Icons

**Icon Library:**

- [x] Emoji-based icons throughout (consistent with mobile-first, cross-platform rendering)

**Icon Convention:**

All task, navigation, and feature icons use native emoji rather than SVG icon libraries. This is intentional for:

- Instant recognition
- No extra library weight
- Cross-platform consistency
- Personality and warmth in a dark UI

| Context       | Examples                |
| ------------- | ----------------------- |
| Tasks         | 🏋️ 🥦 😴 🚫 📸 📖 💧 🧘 |
| Navigation    | 🏠 👤 🔥 🤝 💬 📰 ⚙️ 🚪 |
| Moods         | 😊 😐 😞                |
| Status        | ✓ ✕ ● 🏆 ⚡ 🔒 🌍       |
| Notifications | 🔔                      |

**Icon Sizes:**

| Context       | Size    |
| ------------- | ------- |
| Inline text   | 1rem    |
| Task rows     | 1.1rem  |
| Sidebar nav   | 1.05rem |
| Card headers  | 1.3rem  |
| Mood selector | 1.6rem  |
| Hero/Feature  | 1.8rem+ |

---

## 7. Images & Media

### Image Style

**Photography Style:**

- Not currently used — UI is text, emoji, and data-driven
- Future: If images are added, prefer dark/moody fitness photography with orange/warm color grading

**Avatar Placeholder:**

- Initials in Bebas Neue on `rgba(255,255,255,0.06)` circle
- Color: `#5a5754` (text-muted)
- Finisher overlay: gold circle badge with 🏆

### Watermark Text

Used on hero sections for depth:

```css
font-family: 'Bebas Neue', sans-serif;
font-size: clamp(100px, 16vw, 220px);
color: rgba(255, 77, 0, 0.025);
position: absolute;
pointer-events: none;
```

---

## 8. Layout

### Maximum Widths

| Context                 | Max Width           |
| ----------------------- | ------------------- |
| Content (with sidebar)  | 900px + sidebar     |
| Content (centered page) | 780px               |
| Full dashboard          | 1100px + sidebar    |
| Hero section            | Full viewport width |

### Sidebar Layout (Hub Pages)

```
+--64px-nav-bar-(full width, fixed)--+
|                                     |
| +--260px--+ +---remaining---+       |
| | Sidebar | |  Main Content |       |
| | (fixed) | |  (scrollable) |       |
| |         | |               |       |
| +---------+ +---------------+       |
```

### Centered Layout (Public Pages)

```
+--64px-nav-bar-(full width, fixed)--+
|                                     |
|     +---max 780-1100px---+          |
|     |   Page Content     |          |
|     |   (centered)       |          |
|     +--------------------+          |
```

### Grid System

- Cards: `grid-template-columns: repeat(2, 1fr)` with 20px gap
- Member cards: `repeat(auto-fill, minmax(260px, 1fr))`
- Stats row: `repeat(4, 1fr)` with 16px gap
- Mood tracker: `repeat(22, 1fr)` with 4px gap

### Spacing Convention

| Element                   | Padding/Gap               |
| ------------------------- | ------------------------- |
| Card internal             | 28–32px                   |
| Section margin-bottom     | 24–40px                   |
| Main content top padding  | 88px (nav offset)         |
| Main content side padding | 40px desktop, 20px mobile |
| Nav height                | 64px                      |

---

## 9. Responsive Design

### Breakpoints

| Name    | Width          | Typical Devices          |
| ------- | -------------- | ------------------------ |
| Mobile  | 0 – 500px      | Phones                   |
| Small   | 501px – 600px  | Large phones             |
| Tablet  | 601px – 860px  | Tablets, small laptops   |
| Desktop | 861px – 1024px | Laptops                  |
| Large   | 1025px+        | Desktops, large monitors |

### Key Responsive Behaviors

| Breakpoint | Behavior                                              |
| ---------- | ----------------------------------------------------- |
| ≤860px     | Sidebar hidden → hamburger slide-in with dark overlay |
| ≤860px     | Main content: margin-left 0, full width               |
| ≤860px     | Hub grid: 1 column                                    |
| ≤860px     | Mood grid: 11 columns (2 rows become ~6 rows)         |
| ≤860px     | Nav page links hidden                                 |
| ≤1024px    | Stats grid: 2 columns                                 |
| ≤600px     | Preset grid: 1 column                                 |
| ≤500px     | Stats grid: 1 column                                  |
| ≤500px     | Nav side padding: 16px                                |
| ≤500px     | User name hidden in nav                               |

### Mobile Considerations

**Navigation:**

- [x] Hamburger button triggers sidebar slide-in from left
- [x] Semi-transparent dark overlay behind sidebar
- [x] Click overlay to close sidebar

**Touch Targets:**

- Minimum size: 38px × 38px (nav buttons, task actions)
- Mood day cells: minimum 26px × 26px
- Day pills (schedule): 26px × 26px

---

## 10. Accessibility

### Minimum Requirements

- [x] Color contrast: All text passes WCAG AA against dark backgrounds
- [x] Focus indicators: Visible focus states (orange ring)
- [x] Form labels: All inputs have labels above (uppercase micro-label convention)
- [x] Error messages: Red color + text description
- [x] Interactive states: Hover, active, focus, disabled all defined
- [x] Motion: Transitions kept under 600ms

### Focus States

```css
:focus {
	border-color: rgba(255, 77, 0, 0.4);
	box-shadow: 0 0 0 3px rgba(255, 77, 0, 0.08);
	outline: none;
}
```

### Dark Theme Contrast Notes

- Primary text (#f0ece6) on #0a0a0a = 16.4:1 ✅
- Secondary text (#8a8680) on #0a0a0a = 5.8:1 ✅
- Muted text (#5a5754) on #0a0a0a = 3.5:1 ⚠️ (decorative/non-essential only)
- Accent (#ff4d00) on #0a0a0a = 4.7:1 ✅ (large text/headings)

---

## 11. Animation & Motion

### Animation Preference

- [x] **Moderate** — Smooth, purposeful, not distracting

### Standard Transitions

| Type                          | Duration | Easing                                  |
| ----------------------------- | -------- | --------------------------------------- |
| Hover (buttons, cards, links) | 300ms    | ease / cubic-bezier                     |
| Dropdown open/close           | 250ms    | cubic-bezier(0.25, 0.46, 0.45, 0.94)    |
| Sidebar slide                 | 300ms    | ease                                    |
| Scroll reveal (fade-up)       | 600ms    | cubic-bezier(0.25, 0.46, 0.45, 0.94)    |
| Progress bar fill             | 1000ms   | ease                                    |
| Tab switch content            | 400ms    | fadeUp keyframe                         |
| Success checkmark             | 500ms    | cubic-bezier(0.175, 0.885, 0.32, 1.275) |

### Scroll-Triggered Animations

Using IntersectionObserver. Elements start as:

```css
.anim {
	opacity: 0;
	transform: translateY(20px);
	transition: all 0.6s cubic-bezier(0.25, 0.46, 0.45, 0.94);
}
.anim.vis {
	opacity: 1;
	transform: translateY(0);
}
```

Staggered delay: `i * 60ms` for siblings.

### Keyframe Animations Used

```css
@keyframes fadeUp {
	from {
		opacity: 0;
		transform: translateY(16px);
	}
	to {
		opacity: 1;
		transform: translateY(0);
	}
}

@keyframes popIn {
	from {
		transform: scale(0);
	}
	to {
		transform: scale(1);
	}
}
```

---

## 12. Reference & Inspiration

### Visual References

| Reference     | What We Took From It                                |
| ------------- | --------------------------------------------------- |
| 75 Hard       | Challenge structure, discipline-focused UX          |
| Strava        | Activity feed, social accountability, streak data   |
| Whoop         | Dark premium aesthetic, biometric data presentation |
| Linear        | Dark mode execution, clean spacing, modern feel     |
| Nike Run Club | Motivational language, bold typography              |

### What to AVOID

| Don't Want                 | Reason                                  |
| -------------------------- | --------------------------------------- |
| Light/white backgrounds    | Breaks the premium dark identity        |
| Traditional grey shadows   | Use colored glows instead               |
| Serif fonts                | Doesn't match athletic/modern tone      |
| Icon libraries (Heroicons) | Emoji-based system is more personal     |
| Pastel colors              | Doesn't convey discipline/intensity     |
| Rounded-full buttons       | Only for pills/badges, not CTAs         |
| Generic dashboard UIs      | Must feel like a fitness tool, not SaaS |

---

## 13. Dark Mode

**Dark Mode Status:**

- [x] Dark-first design (this IS the primary and only mode for MVP)

**Future Light Mode (if ever needed):**

| Element        | Dark (Current)         | Light (Hypothetical) |
| -------------- | ---------------------- | -------------------- |
| Background     | #0a0a0a                | #f8fafc              |
| Surface        | #131313                | #ffffff              |
| Elevated       | #1c1c1c                | #f1f5f9              |
| Text Primary   | #f0ece6                | #0a0a0a              |
| Text Secondary | #8a8680                | #64748b              |
| Border         | rgba(255,255,255,0.06) | #e2e8f0              |
| Accent         | #ff4d00                | #ff4d00 (unchanged)  |

---

## 14. Quick Reference Card

### For AI Agent — Copy These Values

```css
/* ═══ TOTAL 66 DESIGN TOKENS ═══ */

/* Backgrounds */
--bg-primary: #0a0a0a;
--bg-card: #131313;
--bg-card-hover: #1a1a1a;
--bg-elevated: #1c1c1c;
--bg-input: #0f0f0f;

/* Brand */
--accent: #ff4d00;
--accent-glow: rgba(255, 77, 0, 0.15);
--accent-secondary: #ff8a50;
--cyan: #00d4aa;
--cyan-glow: rgba(0, 212, 170, 0.12);
--gold: #ffc642;
--gold-glow: rgba(255, 198, 66, 0.15);
--purple: #a855f7;
--purple-dim: rgba(168, 85, 247, 0.12);

/* Semantic */
--green: #22c55e;
--green-dim: rgba(34, 197, 94, 0.12);
--yellow: #eab308;
--yellow-dim: rgba(234, 179, 8, 0.12);
--red: #ef4444;
--red-dim: rgba(239, 68, 68, 0.12);
--blue: #3b82f6;
--blue-dim: rgba(59, 130, 246, 0.12);

/* Text */
--text-primary: #f0ece6;
--text-secondary: #8a8680;
--text-muted: #5a5754;

/* Borders */
--border: rgba(255, 255, 255, 0.06);
--border-input: rgba(255, 255, 255, 0.08);

/* Typography */
--font-display: 'Bebas Neue', sans-serif;
--font-body: 'DM Sans', sans-serif;

/* Radius */
--radius-sm: 8px;
--radius-md: 12px;
--radius-lg: 16px;
--radius-pill: 100px;

/* Layout */
--nav-height: 64px;
--sidebar-w: 260px;
```

---

## 15. Page Inventory

| Page             | File                    | In Nav | Layout   |
| ---------------- | ----------------------- | ------ | -------- |
| Homepage         | `total66.html`          | Yes    | Centered |
| Challenges       | `challenges.html`       | Yes    | Centered |
| Members          | `members.html`          | Yes    | Centered |
| Auth (Login/Reg) | `auth.html`             | Yes    | Centered |
| My Hub           | `hub.html`              | Yes    | Sidebar  |
| Active Challenge | `active-challenge.html` | No     | Sidebar  |
| Start Challenge  | `start-challenge.html`  | No     | Centered |
| User Profile     | `profile.html`          | No     | Centered |

---

## Changelog

| Date       | Change                                                 | Author |
| ---------- | ------------------------------------------------------ | ------ |
| 2025-05-04 | Initial style guide created from Total 66 page designs | AI     |
