# Assets Style Guide

This style guide documents the patterns and conventions used in HeadsUp asset files.

## File Organization

```
assets/
  js/
    app.js              # Main JavaScript entry point
  css/
    app.css             # Main CSS entry point
  vendor/
    topbar.js           # Third-party libraries
  tailwind.config.js    # Tailwind configuration
```

## JavaScript Entry Point (app.js)

```javascript
// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
```

**Pattern**:
- Import phoenix_html for form method handling
- Import Phoenix Socket and LiveView
- Import vendor libraries from `../vendor/`

### CSRF Token Setup

```javascript
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
```

**Pattern**: Read CSRF token from meta tag for API requests.

### LiveSocket Configuration

```javascript
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken}
})
```

**Pattern**:
- Mount at `/live` path
- Enable long poll fallback for connectivity issues
- Pass CSRF token in params

### Progress Bar (Topbar)

```javascript
// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())
```

**Pattern**: Use topbar for loading indicators on navigation.

### LiveSocket Connection

```javascript
// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
```

**Pattern**: Expose liveSocket for debugging in development.

## LiveView Hooks

### Hook Definition Pattern

```javascript
let Hooks = {}

Hooks.InfiniteScroll = {
  mounted() {
    this.observer = new IntersectionObserver(entries => {
      const entry = entries[0]
      if (entry.isIntersecting) {
        this.pushEvent("load-more", {})
      }
    })
    this.observer.observe(this.el)
  },
  destroyed() {
    this.observer.disconnect()
  }
}

Hooks.LocalTime = {
  mounted() {
    this.el.innerText = new Date(this.el.dataset.utc).toLocaleString()
  }
}

let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})
```

**Pattern**:
- Define hooks object before LiveSocket
- Implement `mounted()` for setup
- Implement `destroyed()` for cleanup
- Use `this.el` for DOM element
- Use `this.pushEvent()` to communicate with server

### Hook Usage in HEEx

```heex
<div id="scroll-container" phx-hook="InfiniteScroll">
  <!-- Content -->
</div>

<time id="local-time" phx-hook="LocalTime" data-utc={@datetime}>
  <!-- Will be replaced by local time -->
</time>
```

**Pattern**: Use `phx-hook` attribute with hook name.

## CSS Entry Point (app.css)

```css
@import "tailwindcss/base";
@import "tailwindcss/components";
@import "tailwindcss/utilities";

/* Custom styles below Tailwind imports */

/* Phoenix-specific styles */
.phx-no-feedback.invalid-feedback,
.phx-no-feedback .invalid-feedback {
  display: none;
}

.phx-click-loading {
  opacity: 0.5;
  cursor: not-allowed;
}

.phx-submit-loading {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Custom component styles */
.goal-card {
  @apply bg-white rounded-lg shadow-sm border border-gray-200;
}

.goal-card:hover {
  @apply border-blue-300 shadow-md;
}
```

**Pattern**:
- Import Tailwind layers first
- Add Phoenix feedback styles
- Use `@apply` for component classes

## Tailwind Configuration

```javascript
// tailwind.config.js
module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/heads_up_web.ex",
    "../lib/heads_up_web/**/*.*ex"
  ],
  theme: {
    extend: {
      colors: {
        brand: "#6366f1",
        "brand-dark": "#4f46e5",
      },
      fontFamily: {
        sans: ['"Be Vietnam Pro"', '"Noto Sans"', 'sans-serif'],
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/typography"),
  ],
}
```

**Pattern**:
- Include all .ex and .heex files in content paths
- Extend theme with brand colors
- Add useful plugins (forms, typography)

## Vendor Libraries

### Topbar.js

```javascript
// assets/vendor/topbar.js
// Third-party library for progress bar
// Downloaded and placed in vendor folder
```

**Pattern**: Keep third-party libraries in `vendor/` folder.

### Adding NPM Packages

```bash
# Install to assets folder
npm install some-package --prefix assets
```

```javascript
// Import from node_modules
import "some-package"
```

## Alpine.js Integration

### Including Alpine

```heex
<!-- In root.html.heex -->
<script defer src="https://unpkg.com/alpinejs@3.x.x/dist/cdn.min.js"></script>
```

### Alpine Usage Patterns

```heex
<!-- Dropdown -->
<div x-data="{ open: false }">
  <button @click="open = !open">Toggle</button>
  <div x-show="open" @click.away="open = false">
    Content
  </div>
</div>

<!-- Transitions -->
<div
  x-show="open"
  x-transition:enter="transition ease-out duration-100"
  x-transition:enter-start="transform opacity-0 scale-95"
  x-transition:enter-end="transform opacity-100 scale-100"
  x-transition:leave="transition ease-in duration-75"
  x-transition:leave-start="transform opacity-100 scale-100"
  x-transition:leave-end="transform opacity-0 scale-95"
>
  Animated content
</div>
```

**Pattern**: Use Alpine.js for client-side interactions that don't need server state.

## Event Handling

### Phoenix Events

```javascript
// Listen for Phoenix events
window.addEventListener("phx:page-loading-start", info => {
  // Page is loading
})

window.addEventListener("phx:page-loading-stop", info => {
  // Page finished loading
})

// Custom events from LiveView
window.addEventListener("phx:copy-to-clipboard", event => {
  navigator.clipboard.writeText(event.detail.text)
})
```

### Pushing Events from Hooks

```javascript
Hooks.CopyButton = {
  mounted() {
    this.el.addEventListener("click", () => {
      navigator.clipboard.writeText(this.el.dataset.text)
      this.pushEvent("copied", {})
    })
  }
}
```

## Build Configuration

### esbuild (in config.exs)

```elixir
config :esbuild,
  version: "0.17.11",
  heads_up: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]
```

### Tailwind (in config.exs)

```elixir
config :tailwind,
  version: "3.4.3",
  heads_up: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]
```

## Static Asset Patterns

### Referencing in Templates

```heex
<!-- CSS -->
<link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />

<!-- JavaScript -->
<script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}></script>

<!-- Images -->
<img src={~p"/images/logo.png"} alt="Logo" />
```

**Pattern**: Use `~p` sigil for verified paths, `phx-track-static` for cache busting.

### Static File Location

```
priv/static/
  assets/
    app.js           # Compiled JS
    app.css          # Compiled CSS
  images/
    logo.png         # Static images
  uploads/
    user-avatars/    # User uploads (excluded from live reload)
```

## Naming Conventions

| File Type | Location | Naming |
|-----------|----------|--------|
| Entry JS | `assets/js/` | `app.js` |
| Entry CSS | `assets/css/` | `app.css` |
| Vendor | `assets/vendor/` | Original name |
| Components | `assets/js/` | `snake_case.js` |
| Hooks | Defined in `app.js` | `PascalCase` |
