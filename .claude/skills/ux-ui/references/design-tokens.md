# HeadsUp Design Tokens

Complete mapping from design system values to Tailwind CSS classes.

## Colors

### Backgrounds
| Token | Hex | Tailwind | Usage |
|-------|-----|----------|-------|
| Global bg | `#FFF5F2` | `bg-[#FFF5F2]` | Page background |
| Surface | `#FFFFFF` | `bg-white` | Cards, modals, sidebars |
| Surface alt | `#F9FAFB` | `bg-gray-50` | Input fields, subtle sections |
| Separator | `#E5E7EB` | `border-gray-200` | Borders, dividers |

### Text
| Token | Hex | Tailwind | Usage |
|-------|-----|----------|-------|
| Primary | `#111827` | `text-gray-900` | Headings, nav links |
| Secondary | `#6B7280` | `text-gray-500` | Subtitles, captions |
| Tertiary | `#9CA3AF` | `text-gray-400` | Placeholders, inactive |

### Brand & Interactive
| Token | Hex | Tailwind | Usage |
|-------|-----|----------|-------|
| Brand coral | `#FF6B6B` | `text-[#FF6B6B]` / `bg-[#FF6B6B]` | CTA buttons, accents |
| Brand coral hover | `#FF5252` | `hover:bg-[#FF5252]` | CTA hover |
| Interactive blue | `#3B82F6` | `text-blue-500` | Links, active states |
| Brand indigo | `#6366F1` | `text-indigo-500` / `bg-indigo-500` | Alternative primary |

### Semantic
| Token | Hex | Tailwind bg/text | Usage |
|-------|-----|-----------------|-------|
| Success | `#22C55E` | `bg-green-100 text-green-800` | Completed, positive |
| Warning | `#F59E0B` | `bg-amber-100 text-amber-800` | Paused, caution |
| Error | `#EF4444` | `bg-red-100 text-red-800` | Failed, danger |
| Info | `#3B82F6` | `bg-blue-100 text-blue-800` | Informational |

### Pastel Tags
| Color | Background | Text | Tailwind |
|-------|-----------|------|----------|
| Blue | `#DBEAFE` | `#1E40AF` | `bg-blue-100 text-blue-800` |
| Green | `#D1FAE5` | `#065F46` | `bg-green-100 text-green-800` |
| Red | `#FEE2E2` | `#991B1B` | `bg-red-100 text-red-800` |
| Purple | `#EDE9FE` | `#5B21B6` | `bg-purple-100 text-purple-800` |
| Pink | `#FCE7F3` | `#9D174D` | `bg-pink-100 text-pink-800` |
| Amber | `#FEF3C7` | `#92400E` | `bg-amber-100 text-amber-800` |

## Border Radius

| Element | Value | Tailwind |
|---------|-------|----------|
| Large containers (cards, modals) | `24px` | `rounded-3xl` |
| Medium elements (images, inner blocks) | `16px` | `rounded-2xl` |
| Small elements (buttons, inputs, tags) | `12px` | `rounded-xl` |
| Pill (text buttons, tags) | `9999px` | `rounded-full` |
| Avatars | `50%` | `rounded-full` |

## Shadows

| Level | Value | Tailwind |
|-------|-------|----------|
| Card (default) | `0 4px 20px rgba(0,0,0,0.05)` | `shadow-[0_4px_20px_rgba(0,0,0,0.05)]` |
| Card (hover) | `0 10px 25px rgba(0,0,0,0.08)` | `shadow-[0_10px_25px_rgba(0,0,0,0.08)]` |
| Subtle | `0 1px 2px rgba(0,0,0,0.05)` | `shadow-sm` |
| None | - | `shadow-none` |

## Typography

Font: Poppins, Inter, or Nunito (geometric sans-serif)

| Element | Size | Weight | Tailwind |
|---------|------|--------|----------|
| H1 (page title) | 28px | 700 | `text-[28px] font-bold` |
| H2 (section header) | 20px | 600 | `text-xl font-semibold` |
| H3 (card title) | 16px | 600 | `text-base font-semibold` |
| Body | 14px | 400 | `text-sm` |
| Caption/Meta | 12px | 500 | `text-xs font-medium` |
| Line height | - | - | `leading-relaxed` (1.5+) |

## Spacing

| Token | Value | Tailwind | Usage |
|-------|-------|----------|-------|
| Card padding | 24px | `p-6` | Inside cards |
| Element gap | 16px | `gap-4` | Between title and body |
| Card gap | 24-32px | `gap-6` or `gap-8` | Between cards |
| Section gap | 48px | `py-12` | Between page sections |

## Breakpoints (Mobile-First)

| Name | Min-width | Tailwind prefix | Layout |
|------|-----------|-----------------|--------|
| Mobile | 0px | (default) | Single column, bottom nav |
| Tablet | 640px | `sm:` | 2-column grid |
| Desktop | 1024px | `lg:` | 3-column grid, sidebars visible |
| Large | 1280px | `xl:` | Max-width container |

## Component Quick Reference

### Buttons
```html
<!-- Primary CTA (coral) -->
<button class="bg-[#FF6B6B] hover:bg-[#FF5252] text-white font-semibold px-6 py-3 rounded-full transition-colors">

<!-- Secondary -->
<button class="bg-white border border-gray-200 text-gray-900 font-medium px-4 py-2 rounded-xl hover:bg-gray-50 transition-colors">

<!-- Ghost -->
<button class="text-gray-600 hover:bg-gray-100 font-medium px-4 py-2 rounded-xl transition-colors">

<!-- Follow (pill) -->
<button class="bg-gray-900 text-white text-sm font-medium px-4 py-1.5 rounded-full hover:bg-gray-800">
```

### Input Fields
```html
<input class="w-full h-12 bg-gray-50 border-none rounded-xl px-4 text-sm text-gray-900 placeholder-gray-400 focus:ring-2 focus:ring-blue-500 focus:outline-none" />
```

### Cards
```html
<div class="bg-white rounded-3xl shadow-[0_4px_20px_rgba(0,0,0,0.05)] p-6">
```

## Layout Templates

### 3-Column Feed (Desktop)
```html
<div class="min-h-screen bg-[#FFF5F2]">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
    <div class="lg:grid lg:grid-cols-12 lg:gap-8">
      <aside class="hidden lg:block lg:col-span-3"><!-- Left --></aside>
      <main class="lg:col-span-6 space-y-6"><!-- Feed --></main>
      <aside class="hidden lg:block lg:col-span-3"><!-- Right --></aside>
    </div>
  </div>
</div>
```

### Single Column (Forms, Detail)
```html
<div class="min-h-screen bg-[#FFF5F2]">
  <div class="max-w-2xl mx-auto px-4 py-6 space-y-6">
    <!-- Content -->
  </div>
</div>
```

### Mobile Bottom Padding
Always add `pb-20 lg:pb-0` to main content to account for bottom nav on mobile.
