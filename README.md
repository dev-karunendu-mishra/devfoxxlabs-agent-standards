# 🛡️ DevFoxx Labs — AI Agent Standards & Skills Ecosystem

> **Author**: Karunendu (DevFoxx Labs)  
> **Version**: 1.0.0  
> **Supported Agents**: Claude Code, Google Antigravity, Gemini CLI, Cursor, Windsurf, Cline, Codex, Amp, Aider, and Universal Agents (`~/.agents`).

A unified, production-tested repository containing global engineering standards, compliance frameworks, security baselines, and specialized skills for autonomous and pair-programming AI coding agents.

---

## 🌟 Why This Repository Exists

AI coding agents write the best code when they operate under strict, proven constraints rather than guessing architectural boundaries. This repository consolidates all production standards and rules authored at **DevFoxx Labs** into a single source of truth that can be:
1. **Installed globally** into local agent configurations (`~/.claude`, `~/.gemini`, `~/.cursor`, `~/.codeium/windsurf`, `~/.agents`).
2. **Mounted into individual projects** (`.agents/rules/`, `CLAUDE.md`, `.cursorrules`).
3. **Shared with teams and other developers** so that any agent working on any codebase immediately adheres to the exact same security, legal, database, and architectural standards.

---

## 🏛️ The 5 Core Engineering Standards

All agents governed by these standards adhere to five non-negotiable rules:

| # | Standard | Summary | Scope |
|---|---|---|---|
| 1 | **[India DPDP Compliance First](rules/dpdp-compliance.md)** | Full compliance with the **Digital Personal Data Protection Act, 2023** and **DPDP Rules, 2025**. Notices (Privacy, Terms, Refund, Cookie), unbundled consent, append-only `consent_records` ledger, immediate withdrawal, zero tracker execution before consent, Data Principal rights, and Grievance Officer workflows. Built **first**, before any other feature. | Every web app, mobile app, and backend built for Indian users |
| 2 | **[Security by Design](rules/secure-development.md)** | Four-layer defence: *Prevent → Enforce Automatically → Detect → Recover*. 2-min threat model before every feature. Server-side authorization and ownership check on every request. Server-computed money (never trust client amounts). Strict rate limits on write routes. Zero secrets in repos. Negative tests for abuse cases. Based on OWASP ASVS 5.0 (L2/L3), OWASP Top 10, MASVS, and CWE Top 25. | Every app, stack, and API |
| 3 | **[Database Safety & ACID](rules/database-safety.md)** | Know where you are (local / staging / production) before every command. Production is guarded (`DB::prohibitDestructiveCommands`). Schema changes are additive (expand → migrate → contract) and backward-compatible. Every write is ACID with row locks (`lockForUpdate`) on shared balance/slots. Zero unmasked PII copied across environments. | MySQL, PostgreSQL, SQLite, Redis, Laravel, Prisma, Drift |
| 4 | **[Hugeicons (Free) Everywhere](rules/icons-hugeicons.md)** | Frontends strictly use **Hugeicons Free (Stroke Rounded)**: `@hugeicons/react` on Web and `hugeicons` on Flutter. No mixing icon libraries (no Lucide, Heroicons, Material Icons, or ad-hoc SVGs). Accessible labels mandatory on icon buttons. | Web & Flutter frontends |
| 5 | **[Flutter Screen Protection](rules/flutter-screen-protection.md)** | Mandatory `SafeArea` wrapping on bodies, bottom navigation bars, and persistent action buttons. Dynamic overflow resilience (`Expanded`/`Flexible`, `maxLines`, `ellipsis`, scrollable scaffolds, 320px width support). Mandatory dynamic backend data (`/api/v1/`), auto-skeleton loading, and memory-bounded image caching. | All Flutter mobile apps |

---

## 🧰 The Production Skills Suite (`skills/`)

The repository includes 11 production-grade agent skills ready for instant invocation:

### 1. Foundation & Compliance
- **`skills/dpdp-compliance`**: Full workflow for establishing DPDP legal notices, consent tables, cookie preference banners, withdrawal mechanisms, and grievance dispatch.
- **`skills/secure-development`**: 320-line threat-modeling and security hardening standard based on ASVS L2/L3 and OWASP Top 10.
- **`skills/database-safety`**: Comprehensive database operations guide, safe migration patterns, expand-migrate-contract workflows, and ACID locking examples.
- **`skills/flutter-production`**: The complete production standard extracted from the DevFoxx Labs portfolio. Includes templates for Riverpod 2.6+ state, API clients, local cache, biometrics, auto-skeleton loaders, sheet insets, and layout matrix test helpers.

### 2. Design Intelligence & UI/UX
- **`skills/ui-ux-pro-max`**: Design intelligence engine for web, mobile, and desktop. Includes searchable datasets for 79 design styles, 192 product palettes, 74 font pairings, 119 UX guidelines, 105 icons, and 22 technology stacks with bundled Python search tools.
- **`skills/ui-styling`**: Rapid UI creation with shadcn/ui components (Radix UI + Tailwind), custom themes, and canvas layout systems.
- **`skills/design`**: Multi-format brand identity system: logos, corporate identity programs (CIP), banners, icons, and social media image generation.
- **`skills/design-system`**: Three-layer design tokens (primitive → semantic → component), CSS variables, and token validation scripts.
- **`skills/brand`**: Brand identity frameworks, tone of voice, asset management, and color extraction utilities.
- **`skills/banner-design`**: Multi-format creative banner generator for social media, ads, website heroes, and print.
- **`skills/slides`**: Strategic HTML presentation and slide deck builder with Chart.js visualization.

---

## 🚀 Installation & Quick Start

### Windows (PowerShell)

Run `install.ps1` to install across all or specific agents:

```powershell
# 1. Install across ALL agents (Claude, Gemini, Cursor, Windsurf, ~/.agents)
.\install.ps1 -All

# 2. Or install to specific agents
.\install.ps1 -Claude -Gemini
.\install.ps1 -Cursor
.\install.ps1 -Windsurf

# 3. Or deploy rules into a specific project repository
.\install.ps1 -TargetProject "E:\DevFoxxLabsProjects\my-project"
```

Running `.\install.ps1` with no flags launches an interactive menu.

---

### macOS & Linux (Bash)

```bash
# Make executable
chmod +x install.sh

# Install across ALL agents
./install.sh all

# Or install to specific agent
./install.sh claude
./install.sh gemini
./install.sh cursor
./install.sh windsurf

# Or deploy to a project
./install.sh /path/to/my-project
```

---

## 📂 Repository Directory Layout

```
devfoxx-agent-standards/
├── README.md                           # Documentation & master overview
├── manifest.json                       # Machine-readable registry of standards & skills
├── install.ps1                         # PowerShell universal installer (Windows)
├── install.sh                          # Bash universal installer (macOS/Linux)
├── sync.ps1                            # Bi-directional sync tool (repo <-> local agents)
│
├── rules/                              # Global & platform-specific rules
│   ├── dpdp-compliance.md              # DPDP Act 2023 / Rules 2025 rule
│   ├── secure-development.md           # Security by Design rule
│   ├── database-safety.md              # Database Safety & ACID rule
│   ├── icons-hugeicons.md              # Hugeicons standard rule
│   ├── flutter-screen-protection.md    # Flutter screen protection & overflow rule
│   ├── CLAUDE_GLOBAL.md                # Global prompt for ~/.claude/CLAUDE.md
│   ├── GEMINI_GLOBAL.md                # Global prompt for ~/.gemini/GEMINI.md
│   ├── WINDSURF_GLOBAL.md              # Global prompt for Windsurf memories
│   └── CURSOR_GLOBAL.md                # Global rules for Cursor / .cursorrules
│
├── skills/                             # The 11 agent skills
│   ├── dpdp-compliance/                # DPDP compliance framework
│   ├── secure-development/             # OWASP ASVS L2/L3 security standard
│   ├── database-safety/                # Production database safety standard
│   ├── flutter-production/             # Flutter architecture, templates & test helpers
│   ├── ui-ux-pro-max/                  # Design intelligence engine & datasets
│   ├── ui-styling/                     # shadcn/ui & Tailwind customization
│   ├── design/                         # Brand identity, CIP & visual design
│   ├── design-system/                  # Design tokens & component specs
│   ├── brand/                          # Brand voice & asset pipelines
│   ├── banner-design/                  # Multi-format ad & hero banner design
│   └── slides/                         # HTML presentation generator
│
└── templates/                          # Ready-to-copy project templates
    └── project-rules/
        ├── flutter.CLAUDE.md           # Flutter mobile project rules template
        ├── laravel.CLAUDE.md           # Laravel API project rules template
        └── web-nextjs.CLAUDE.md        # Next.js web frontend rules template
```

---

## 🔄 Keeping Standards in Sync

When you modify skills or rules locally and want to pull them back into this repository, run:

```powershell
# Pull latest changes from ~/.gemini into this repo
.\sync.ps1 -Action Pull

# Push latest repo updates back to all local agents
.\sync.ps1 -Action Push
```

---

## 📄 License & Attribution

Authored and maintained by **Karunendu** ([DevFoxx Labs](https://github.com/devfoxx)).  
Shared internally and across projects to maintain consistent engineering excellence across all AI pair programming workflows.
