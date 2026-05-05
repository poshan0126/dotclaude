---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.vue"
  - "**/*.svelte"
  - "**/*.css"
  - "**/*.scss"
  - "**/*.html"
  - "**/components/**"
  - "**/pages/**"
  - "**/views/**"
  - "**/layouts/**"
  - "**/styles/**"
---

# Frontend

## Design Tokens

Before writing frontend code, find the project's existing tokens file (`tokens.css`, `variables.css`, `theme.ts`, `tailwind.config.*`, `_variables.scss`). If none exists, create one. Never hardcode raw values in components.

Required token categories: colors (semantic names with dark mode variants), spacing scale, border radius, shadows (elevation system), typography (display + body + mono fonts, type scale, weights), breakpoints, transitions (durations + easing), z-index scale.

## Design Principles

Pick one primary principle. Don't mix randomly.

| Principle | When to use |
|---|---|
| **Glassmorphism** | Overlays, modern dashboards |
| **Neumorphism** | Settings panels, minimal controls |
| **Brutalism** | Developer tools, editorial sites |
| **Minimalism** | Portfolios, documentation, content-first |
| **Maximalism** | Creative agencies, e-commerce |
| **Claymorphism** | Playful apps, onboarding |
| **Bento Grid** | Dashboards, feature showcases |
| **Aurora / Mesh Gradients** | Landing pages, hero sections |
| **Flat Design** | Mobile apps, system UI |
| **Material Elevation** | Data-heavy apps, enterprise |
| **Editorial** | Blogs, long-form content |

## Component Framework

Use whatever the project already has. Don't mix competing libraries.

| Category | Options (pick one) |
|---|---|
| CSS | Tailwind, vanilla CSS, CSS Modules, styled-components, Emotion, UnoCSS, Panda CSS |
| Primitives | shadcn/ui, Radix, Headless UI, Ark UI, DaisyUI, Mantine, Chakra, Vuetify |
| Animation | CSS transitions, Framer Motion, GSAP, View Transitions API, AutoAnimate |
| Charts | Recharts, D3, Chart.js, Visx, ECharts, Nivo |
| Icons | Lucide, Phosphor, Heroicons, Tabler Icons, Iconify |

## Layout

- CSS Grid for 2D, Flexbox for 1D. Use `gap`, not margin hacks.
- Semantic HTML: `<header>`, `<nav>`, `<main>`, `<section>`, `<article>`, `<footer>`.
- Mobile-first. Touch targets: minimum 44x44px.

## Accessibility (non-negotiable)

- All interactive elements keyboard-accessible.
- Images: meaningful `alt` text. Decorative: `alt=""`.
- Form inputs: associated `<label>` or `aria-label`.
- Contrast: 4.5:1 normal text, 3:1 large text.
- Visible focus indicators. Never `outline: none` without replacement.
- Color never the sole indicator.
- `aria-live` for dynamic content. Respect `prefers-reduced-motion` and `prefers-color-scheme`.

## Performance

- Images: `loading="lazy"` below fold, explicit `width`/`height`.
- Fonts: `font-display: swap`.
- Animations: `transform` and `opacity` only.
- Large lists: virtualize at 100+ items.
- Bundle size: never import a whole library for one function.
