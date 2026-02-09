### UI/UX Design System Guide: "Soft Modern" Aesthetic

This guide defines the visual language (DNA) of your project. By strictly adhering to these rules for colors, typography, shapes, and spacing, you can build unlimited pages with different structures that all feel professional, cohesive, and visually identical to the "Soft UI" style you like.

---

### 1. The Color Palette

**Philosophy:** A clean, low-contrast canvas where content pops. Avoid "pure black" to reduce eye strain.

#### **Backgrounds (The Canvas)**

- **Global Background:** `#F4F6F9` (Cool Grey) or `#FFF5F2` (Warm Blush)
- _Usage:_ The main page background behind everything.

- **Surface (Cards):** `#FFFFFF` (Pure White)
- _Usage:_ All containers, sidebars, headers, and content blocks.

- **Separators:** `#E5E7EB` (Very Light Grey)
- _Usage:_ Borders, dividers, and lines.

#### **Typography Colors**

- **Primary Text:** `#111827` (Deep Charcoal)
- _Usage:_ Headings, main body text, navigation links.

- **Secondary Text:** `#6B7280` (Medium Grey)
- _Usage:_ Subtitles, dates, captions, "read more" links.

- **Tertiary Text:** `#9CA3AF` (Light Grey)
- _Usage:_ Placeholders in forms, inactive icons.

#### **Accent & Interactive Colors**

- **Primary Brand:** `#1A1A1A` (Black) OR `#FF6B6B` (Coral/Red)
- _Usage:_ Main "Call to Action" buttons (Submit, Post, Login).

- **Interactive/Links:** `#3B82F6` (Vibrant Blue)
- _Usage:_ Text links, active states, hashtags.

- **Functional Tags (Pastels):**
- _Blue:_ Bg: `#DBEAFE` / Text: `#1E40AF`
- _Green:_ Bg: `#D1FAE5` / Text: `#065F46`
- _Red:_ Bg: `#FEE2E2` / Text: `#991B1B`

---

### 2. Shape & Form (The "Soft" Look)

The defining characteristic of this style is **smoothness**. Nothing is sharp.

#### **Border Radius (The Roundness)**

- **Large Containers (Cards, Modals):** `24px`
- **Medium Elements (Images, Inner Blocks):** `16px`
- **Small Elements (Buttons, Inputs, Tags):** `12px` or `50px` (Full Pill)
- _Rule:_ If a button is just an icon, use a circle (50%). If it contains text, use a soft rectangle (12px) or pill (50px).

#### **Shadows (The Depth)**

Avoid dark, hard shadows. Use "diffused" light.

- **Card Shadow:** `0px 4px 20px rgba(0, 0, 0, 0.05)`
- **Hover Effect:** `0px 10px 25px rgba(0, 0, 0, 0.08)` (Element lifts up slightly)

---

### 3. Typography System

**Font Family:** Use a geometric sans-serif (e.g., **Poppins**, **Inter**, or **Nunito**).

- **H1 (Page Titles):** 28px — **Bold (700)**
- **H2 (Section Headers):** 20px — **Semi-Bold (600)**
- **H3 (Card Titles/Names):** 16px — **Semi-Bold (600)**
- **Body Text:** 14px — **Regular (400)**
- _Line Height:_ 1.5 (Very important for readability).

- **Caption/Meta:** 12px — **Medium (500)**

---

### 4. Spacing Rules (Whitespace)

Generous spacing makes the UI feel "expensive" and easy to read.

- **Padding Inside Cards:** `24px` (Do not cram text against the edges).
- **Gap Between Elements:** `16px` (Distance between a title and paragraph).
- **Gap Between Cards:** `24px` or `32px`.

---

### 5. Component Styles (Reusable Elements)

#### **Buttons**

- **Primary:** Solid Brand Color Background + White Text. No border.
- **Secondary:** White Background + Light Grey Border + Dark Text.
- **Ghost:** Transparent Background + Brand Color Text (Hover: Light Grey Bg).

#### **Input Fields**

- **Background:** `#F9FAFB` (Very light grey, not pure white).
- **Border:** None or 1px Solid `#E5E7EB`.
- **Height:** `48px` (Tall and clickable).
- **Radius:** `12px`.

#### **Images & Media**

- **Aspect Ratio:** Consistent shapes (Square `1:1`, Portrait `4:5`, or Landscape `16:9`).
- **Fit:** Always use `object-fit: cover` to prevent stretching.
- **Avatars:** Always circles.

---

### **How to Apply This Guide**

Whenever you create a new page (e.g., Settings, Profile, Search Results), ask:

1. **Is it soft?** (Are corners rounded to 24px?)
2. **Is it light?** (Is the shadow subtle and the background light grey?)
3. **Is it breathable?** (Is there at least 24px of padding inside the container?)
4. **Is the hierarchy clear?** (Are headings dark/bold and meta-data grey/small?)

If the answer is **Yes** to all, your new pages will perfectly match the design style.

---

### 6. Design References (Provided)

The two reference images introduce a **feed-first social dashboard pattern** that can be applied to HeadsUp pages while keeping the same "Soft Modern" DNA.

#### Reference A (Main Stream Dashboard)

- Three-column desktop structure:
  - Left: category rail + promo block
  - Center: primary content feed
  - Right: lightweight discovery widgets (popular posts, suggestions)
- White cards on soft tinted background
- Pill tags, rounded blocks, small status counters
- Compact top bar actions

#### Reference B (Community Feed)

- Three-column desktop structure:
  - Left: profile + primary navigation list
  - Center: feed cards + composer
  - Right: stories + suggestions + recommendations
- Strong card hierarchy (header, body, interaction row)
- Soft color accents for sections (blue/yellow cards)
- Rounded media blocks and compact action controls

---

### 7. Layout Translation Rules (HeadsUp)

Use these rules when translating the references into HeadsUp pages:

#### Desktop Grid

- Use a 3-column shell:
  - Left rail: `240-280px`
  - Center feed/content: flexible main column
  - Right rail: `300-340px`
- Gutter between columns: `24px`
- Keep all rails and cards on the same soft background canvas.

#### Tablet

- Collapse to 2 columns:
  - Center content full width
  - One contextual rail under or above content
- Hide low-priority widgets (ads, tertiary recommendation cards).

#### Mobile

- Single column stack
- Convert sidebars into horizontal modules or collapsible sections
- Keep interaction buttons large and touch-friendly.

---

### 8. Reusable Component Blueprint

To avoid long pages and preserve consistency, compose pages from reusable components:

- `AppTopBar`
- `LeftRailProfileCard`
- `LeftRailNavList`
- `LeftRailCategoryList`
- `CenterFeedSectionHeader`
- `FeedCard` (author row, content, media, actions)
- `StoryRail`
- `SuggestionList`
- `RecommendationGrid`
- `StatPill`
- `SectionCard` (generic white card shell with 24px padding)

Each component must inherit the same:
- Radius tokens (`24 / 16 / 12 / pill`)
- Shadow tokens (`0 4px 20px rgba(0,0,0,0.05)` + hover lift)
- Type scale (`28 / 20 / 16 / 14 / 12`)
- Color rules from sections 1 and 2.

---

### 9. Interaction & Motion

- Hover on cards: lift slightly (`translateY(-2px)`) + hover shadow.
- Navigation items: active state with soft background tint and clear text contrast.
- Drawer/side panels: smooth `180-220ms` transitions, no jarring spring effects.
- Keep animation subtle; never let motion reduce readability.

---

### 10. Page-Level Consistency Checklist

Before shipping any page, verify:

1. Are all card containers white with soft borders and 24px radius?
2. Are text colors mapped correctly (`#111827`, `#6B7280`, `#9CA3AF`)?
3. Are interactions using blue (`#3B82F6`) for links/active states?
4. Are long pages split into reusable components?
5. Does desktop use a clear content hierarchy (rail + main + contextual rail)?
6. Does tablet/mobile preserve clarity without crowded UI?
