# Style Guide

> This document defines the visual identity and design preferences for HeadsUp.
> The AI agent should follow these guidelines for all UI development.

> Update note (latest): For current UI implementation details and reference-driven layout patterns, treat `/project_doc/docs/design/ux-ui.md` as the primary source of truth.  
> This file remains valid for brand foundations, but if guidance conflicts, follow `ux-ui.md`.

---

## 1. Brand Identity

### Project Name

**Name:** HeadsUp
**Tagline:** Set fewer goals. Finish more.

### Logo

**Logo Status:**

- [ ] I will provide a logo file (place in `/assets/logo/`)
- [x] Generate a simple text-based logo using the project name
- [ ] No logo needed for MVP

**Logo Files Provided:**

- Primary: `/assets/logo/logo-primary.svg`
- Light version (for dark backgrounds): `/assets/logo/logo-light.svg`
- Icon only: `/assets/logo/logo-icon.svg`

**Logo Usage Rules:**

- Minimum size: 120px width
- Clear space around logo: equal to the height of the logo icon
- Never stretch or distort the logo

---

## 2. Color Palette

### Primary Colors

| Role              | Color Name   | Hex Code  | Usage                            |
| ----------------- | ------------ | --------- | -------------------------------- |
| **Primary**       | Brand Indigo | `#6366f1` | Main buttons, links, key actions |
| **Primary Hover** | Brand Dark   | `#4f46e5` | Hover state for primary elements |
| **Primary Light** | Indigo 50    | `#eef2ff` | Backgrounds, highlights          |

### Secondary Colors

| Role                | Color Name | Hex Code  | Usage                      |
| ------------------- | ---------- | --------- | -------------------------- |
| **Secondary**       | Teal       | `#14b8a6` | Secondary buttons, accents |
| **Secondary Hover** | Teal Dark  | `#0d9488` | Hover states               |

### Neutral Colors

| Role               | Color Name      | Hex Code  | Usage                    |
| ------------------ | --------------- | --------- | ------------------------ |
| **Text Primary**   | Dark Blue/Black | `#0d141c` | Headings, important text |
| **Text Secondary** | Muted Blue      | `#49739c` | Body text, descriptions  |
| **Text Muted**     | Slate 400       | `#94a3b8` | Placeholders, hints      |
| **Border**         | Slate 200       | `#e2e8f0` | Borders, dividers        |
| **Background**     | Slate 50        | `#f8fafc` | Page background          |
| **Surface**        | White           | `#ffffff` | Cards, modals            |
| **Surface Alt**    | Light Blue Grey | `#e7edf4` | Secondary backgrounds    |

### Semantic Colors

| Role              | Color Name | Hex Code  | Usage                           |
| ----------------- | ---------- | --------- | ------------------------------- |
| **Success**       | Green      | `#22c55e` | Success messages, confirmations |
| **Success Light** | Green 100  | `#dcfce7` | Success backgrounds             |
| **Warning**       | Amber      | `#f59e0b` | Warnings, caution states        |
| **Warning Light** | Amber 100  | `#fef3c7` | Warning backgrounds             |
| **Error**         | Red        | `#ef4444` | Errors, destructive actions     |
| **Error Light**   | Red 100    | `#fee2e2` | Error backgrounds               |
| **Info**          | Blue       | `#3b82f6` | Informational messages          |
| **Info Light**    | Blue 100   | `#dbeafe` | Info backgrounds                |

### Color Preferences (Plain Language)

Primary color preference:
A modern, professional indigo/blue that feels trustworthy and energetic.

Colors to AVOID:
Neon colors, harsh contrasts.

Overall feeling:
Clean, modern, and structured.

---

## 3. Typography

### Font Families

**Primary Font (Headings & Body):**

- Font: Be Vietnam Pro
- Source: Google Fonts
- Weights needed: 400, 500, 600, 700

**Secondary Font (Alternative Body):**

- Font: Noto Sans
- Source: Google Fonts
- Weights needed: 400, 500, 600

**Monospace Font (Code/Data):**

- Font: JetBrains Mono, Fira Code, or system monospace

**Font Preference (Plain Language):**

Style preference:
[x] Modern and clean (sans-serif like Inter, Helvetica)

### Type Scale

| Element    | Size            | Weight | Line Height | Letter Spacing |
| ---------- | --------------- | ------ | ----------- | -------------- |
| H1         | 36px / 2.25rem  | 700    | 1.2         | -0.02em        |
| H2         | 30px / 1.875rem | 600    | 1.25        | -0.01em        |
| H3         | 24px / 1.5rem   | 600    | 1.3         | 0              |
| H4         | 20px / 1.25rem  | 600    | 1.4         | 0              |
| H5         | 18px / 1.125rem | 600    | 1.4         | 0              |
| Body Large | 18px / 1.125rem | 400    | 1.6         | 0              |
| Body       | 16px / 1rem     | 400    | 1.6         | 0              |
| Body Small | 14px / 0.875rem | 400    | 1.5         | 0              |
| Caption    | 12px / 0.75rem  | 400    | 1.4         | 0.01em         |

---

## 4. Visual Style

### Overall Aesthetic

**Primary Style:**

- [x] **Modern/Bold** - Strong colors, clear hierarchy, confident

### Border Radius (Roundness)

- [x] **Rounded** - 8px-12px (friendly, soft)

**Specific Values:**
| Element | Radius |
|---------|--------|
| Buttons | 8px |
| Cards | 12px |
| Input fields | 8px |
| Modals | 16px |
| Avatars | 50% / fully round |
| Tags/Badges | 9999px / pill |

### Shadows

**Shadow Style:**

- [x] **Subtle shadows** - Barely noticeable, slight depth

**Shadow Definitions:**

```css
/* Small - for buttons, dropdowns */
shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);

/* Medium - for cards, popovers */
shadow-md:
	0 4px 6px -1px rgba(0, 0, 0, 0.1),
	0 2px 4px -1px rgba(0, 0, 0, 0.06);

/* Large - for modals, dialogs */
shadow-lg:
	0 10px 15px -3px rgba(0, 0, 0, 0.1),
	0 4px 6px -2px rgba(0, 0, 0, 0.05);
```

### Spacing System

Use consistent spacing based on a base unit (4px):

| Token | Value | Usage                    |
| ----- | ----- | ------------------------ |
| xs    | 4px   | Tight spacing, icon gaps |
| sm    | 8px   | Related elements         |
| md    | 16px  | Standard padding         |
| lg    | 24px  | Section spacing          |
| xl    | 32px  | Large gaps               |
| 2xl   | 48px  | Section separation       |
| 3xl   | 64px  | Page sections            |

---

## 5. UI Components

### Buttons

**Primary Button:**

- Background: Primary color (`#6366f1`)
- Text: White
- Hover: Darker primary (`#4f46e5`)
- Border radius: 8px
- Padding: 12px 24px
- Font weight: 600

**Secondary Button:**

- Background: Surface Alt (`#e7edf4`)
- Text: Text Primary (`#0d141c`)
- Hover: Darker shade
- Border radius: 8px

**Ghost Button:**

- Background: Transparent
- Text: Text Primary
- Hover: Light gray background

**Danger Button:**

- Background: Error color (`#ef4444`)
- Text: White
- Use for: Delete, cancel subscription, destructive actions

**Button Sizes:**
| Size | Padding | Font Size |
|------|---------|-----------|
| Small | 8px 16px | 14px |
| Medium | 12px 24px | 16px |
| Large | 16px 32px | 18px |

### Form Inputs

**Text Input:**

- Background: White
- Border: 1px solid Border color (`#e2e8f0`)
- Border (focus): Primary color (`#6366f1`)
- Border radius: 8px
- Padding: 12px 16px
- Font size: 16px

**States:**

- Default: Gray border
- Focus: Primary border + subtle shadow
- Error: Error border + error message below
- Disabled: Gray background, muted text

**Labels:**

- Position: Above input
- Font size: 14px
- Font weight: 500
- Color: Text Primary
- Required indicator: Red asterisk (\*)

### Cards

**Standard Card:**

- Background: White
- Border: 1px solid Border color (`#e2e8f0`)
- Border radius: 12px
- Shadow: shadow-sm
- Padding: 24px

**Interactive Card (Clickable):**

- Same as standard
- Hover: Border color change (`border-blue-300`) + shadow-md
- Cursor: Pointer

### Navigation

**Header/Navbar:**

- Position: Static
- Background: White
- Height: 64px
- Shadow: None / Border Bottom

**Sidebar (if applicable):**

- Width: 240px
- Background: White
- Collapsible: Yes

### Tables

**Style:**

- [x] **Clean** - Minimal lines, just row separators

**Table Features:**

- Header background: Light gray / Surface Alt
- Row hover: Light highlight
- Sticky header: Yes

### Modals/Dialogs

**Overlay:** Dark semi-transparent background (rgba(0,0,0,0.5))
**Modal:**

- Background: White
- Border radius: 16px
- Shadow: Large shadow
- Max width: 500px (sm), 800px (lg)
- Padding: 24-32px

### Notifications/Toasts

**Position:** Top right
**Style:** Rounded card with semantic color
**Duration:** 5 seconds

---

## 6. Icons

**Icon Library:**

- [x] Heroicons (v2.1.1)

**Icon Style:**

- [x] Outline (line icons) for UI
- [x] Solid (filled icons) for active states

**Icon Sizes:**
| Context | Size |
|---------|------|
| Inline with text | 16px |
| Buttons | 20px |
| Navigation | 24px |
| Empty states | 48-64px |
| Hero/Feature | 64px+ |

---

## 7. Images & Media

### Image Style

**Photography Style:**

- [x] Modern/Clean
- [x] Minimal backgrounds

**Placeholder Images:**

- Use: UI Avatars or generic patterns
- Avatar placeholder: Initials with colored background

### Image Treatment

- Border radius: Match card radius (12px) or fully round for avatars
- Aspect ratios:
- Thumbnails: 1:1
- Cards: 16:9
- Hero: 21:9

---

## 8. Layout

### Maximum Widths

| Context           | Max Width      |
| ----------------- | -------------- |
| Content (reading) | 720px          |
| Content (general) | 1024px         |
| Full page         | 1280px         |
| Dashboard         | 1440px or full |

### Grid System

- Columns: 12-column grid
- Gutter: 24px desktop, 16px mobile
- Margins: 24px desktop, 16px mobile

### Page Structure

**Standard Page:**

```
+----------------------------------+
|           Header/Nav             |
+----------------------------------+
|                                  |
|         Page Content             |
|    (centered, max-width)         |
|                                  |
+----------------------------------+
|            Footer                |
+----------------------------------+
```

---

## 9. Responsive Design

### Breakpoints

| Name    | Width           | Typical Devices          |
| ------- | --------------- | ------------------------ |
| Mobile  | 0 - 639px       | Phones                   |
| Tablet  | 640px - 1023px  | Tablets, small laptops   |
| Desktop | 1024px - 1279px | Laptops                  |
| Large   | 1280px+         | Desktops, large monitors |

### Mobile Considerations

**Navigation:**

- [x] Hamburger menu (slide-out) or simplified header

**Tables:**

- [x] Stack as cards or horizontal scroll

**Touch Targets:**

- Minimum size: 44px x 44px

---

## 10. Accessibility

### Minimum Requirements

- [x] Color contrast: WCAG AA (4.5:1 for text)
- [x] Focus indicators: Visible keyboard focus states
- [x] Alt text: All meaningful images have descriptions
- [x] Form labels: All inputs have associated labels
- [x] Error messages: Clear and specific
- [x] Font size: Minimum 16px for body text

### Focus States

All interactive elements must have visible focus states:

- Style: Ring
- Color: Primary color (`#6366f1`)

---

## 11. Animation & Motion

### Animation Preference

- [x] **Moderate** - Smooth but not distracting

### Standard Durations

| Type                        | Duration  | Easing      |
| --------------------------- | --------- | ----------- |
| Micro (hover, focus)        | 150ms     | ease-out    |
| Small (dropdowns, tooltips) | 200ms     | ease-out    |
| Medium (modals, sidebars)   | 300ms     | ease-in-out |
| Large (page transitions)    | 400-500ms | ease-in-out |

### Reduce Motion

Respect user's "prefers-reduced-motion" setting.

---

## 12. Reference & Inspiration

### Websites/Apps I Like

| Website/App | What I Like About It                 |
| ----------- | ------------------------------------ |
| Strava      | Social motivation loops, clean feeds |
| Airbnb      | Card design, clean typography        |
| Linear      | Modern feel, dark mode execution     |

### What to AVOID

| Don't Want           | Example/Reason             |
| -------------------- | -------------------------- |
| Cluttered interfaces | Too much on screen at once |
| Bright neon colors   | Feels cheap/unprofessional |
| Tiny text            | Hard to read               |

---

## 13. Dark Mode (Optional)

**Dark Mode Support:**

- [ ] Not needed for MVP
- [x] Nice to have later

**If implementing dark mode:**

| Element        | Light Mode | Dark Mode |
| -------------- | ---------- | --------- |
| Background     | #f8fafc    | #0f172a   |
| Surface        | #ffffff    | #1e293b   |
| Text Primary   | #0d141c    | #f8fafc   |
| Text Secondary | #49739c    | #94a3b8   |
| Border         | #e2e8f0    | #334155   |

---

## 14. Quick Reference Card

### For AI Agent - Copy These Values

```css
/* Colors */
--color-primary: #6366f1;
--color-primary-hover: #4f46e5;
--color-secondary: #14b8a6;
--color-background: #f8fafc;
--color-surface: #ffffff;
--color-surface-alt: #e7edf4;
--color-text: #0d141c;
--color-text-secondary: #49739c;
--color-text-muted: #94a3b8;
--color-border: #e2e8f0;
--color-success: #22c55e;
--color-warning: #f59e0b;
--color-error: #ef4444;

/* Typography */
--font-heading: 'Be Vietnam Pro', sans-serif;
--font-body: 'Be Vietnam Pro', sans-serif;
--font-body-alt: 'Noto Sans', sans-serif;

/* Spacing */
--radius-sm: 4px;
--radius-md: 8px;
--radius-lg: 12px;
--radius-xl: 16px;

/* Shadows */
--shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
--shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
--shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
```

---

## Changelog

| Date       | Change                      | Author |
| ---------- | --------------------------- | ------ |
| 2026-02-02 | Initial style guide created | AI     |
