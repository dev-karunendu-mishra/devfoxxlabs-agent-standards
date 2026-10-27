<div align="center">

# 🛡️ DevFoxx Labs — AI Agent Standards & Skills Ecosystem

**Production-grade engineering standards, DPDP Act 2023 compliance, OWASP ASVS L2/L3 security baselines, and 11 pro skills for AI coding agents.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-1.0.0-emerald.svg)](https://github.com/dev-karunendu-mishra/devfoxxlabs-agent-standards)
[![PRs Welcome](https://img.shields.io/badge/PRs-Welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Agents](https://img.shields.io/badge/Agents-Claude%20%7C%20Gemini%20%7C%20Cursor%20%7C%20Windsurf-orange.svg)](#supported-agents)

---

[Quick Start](#-quick-start) • [Why This Exists](#-why-this-exists) • [Core Standards](#-the-5-core-engineering-standards) • [Skills Suite](#-the-production-skills-suite) • [Installation](#-universal-installation) • [Contributing](#-contributing)

</div>

---

## ⚡ Quick Start

Clone and install all standards & skills across **Claude Code, Gemini CLI / Antigravity, Cursor, and Windsurf** in under 30 seconds:

### Windows (PowerShell)
```powershell
git clone https://github.com/dev-karunendu-mishra/devfoxxlabs-agent-standards.git
cd devfoxxlabs-agent-standards
.\install.ps1 -All
```

### macOS & Linux (Bash)
```bash
git clone https://github.com/dev-karunendu-mishra/devfoxxlabs-agent-standards.git
cd devfoxxlabs-agent-standards
chmod +x install.sh
./install.sh all
```

---

## 🌟 Why This Exists

AI coding agents (Claude Code, Gemini, Cursor, Windsurf) build features rapidly, but without strict architectural boundaries, they consistently make three critical mistakes:
1. **Legal & Privacy Blindness**: Inlining tracking pixels and analytics SDKs before obtaining consent, directly violating **India's Digital Personal Data Protection Act, 2023 (DPDP Act)** and **DPDP Rules, 2025**.
2. **Security Vulnerabilities**: Trusting client-side amounts/prices, skipping server-side object ownership checks, and hardcoding secrets.
3. **Database Disasters**: Running destructive schema operations in production (`migrate:fresh`, unsafe `DROP`), omitting `WHERE` clauses, or skipping row-level locks on financial balances.

**DevFoxx Labs Agent Standards** establishes deterministic, non-negotiable rules and a suite of 11 production skills that keep AI assistants strictly aligned with real-world enterprise engineering practices.

---

## 🏛️ The 5 Core Engineering Standards

All agents governed by these standards adhere to five non-negotiable rules:

| # | Standard | Summary | Scope |
|---|---|---|---|
| 1 | **[India DPDP Compliance First](rules/dpdp-compliance.md)** | Mandatory compliance under **DPDP Act, 2023** & **DPDP Rules, 2025**. Single-source versioned notices, unbundled consent, append-only `consent_records` ledger, zero tracker execution before consent, immediate withdrawal, and Grievance Officer routing. Built **first**, before any other feature. | All apps & APIs built for Indian users |
| 2 | **[Security by Design](rules/secure-development.md)** | 4-Layer Defence (*Prevent → Enforce Automatically → Detect → Recover*). 2-min threat model before every feature. Server-side authorization & ownership checks on every request. Server-computed money. Rate limits on public writes. Zero secrets in repos. Negative tests for abuse cases. (OWASP ASVS L2/L3, OWASP Top 10, MASVS, CWE Top 25). | Every app, stack, and API |
| 3 | **[Database Safety & ACID](rules/database-safety.md)** | Know where you are (local / staging / production) before every command. Production is guarded (`DB::prohibitDestructiveCommands`). Schema changes are additive (expand → migrate → contract). Every write is ACID with row locks (`lockForUpdate`) on shared balance/slots. Zero unmasked PII copied across environments. | MySQL, PostgreSQL, SQLite, Redis, Laravel, Prisma, Drift |
| 4 | **[Hugeicons (Free) Everywhere](rules/icons-hugeicons.md)** | Frontends strictly use **Hugeicons Free (Stroke Rounded)**: `@hugeicons/react` on Web and `hugeicons` on Flutter. No mixing icon libraries (no Lucide, Heroicons, Material Icons, or ad-hoc SVGs). Accessible labels mandatory on icon buttons. | Web & Flutter frontends |
| 5 | **[Flutter Screen Protection](rules/flutter-screen-protection.md)** | Mandatory `SafeArea` wrapping on bodies, bottom navigation bars, and persistent action buttons. Dynamic overflow resilience (`Expanded`/`Flexible`, `maxLines`, `ellipsis`, scrollable scaffolds, 320px width support). Mandatory dynamic backend data (`/api/v1/`), auto-skeleton loading, and memory-bounded image caching. | All Flutter mobile apps |

---

## 🧰 The Production Skills Suite

This repository bundles 11 fully self-contained, battle-tested agent skills:

### 1. Compliance, Security & Architecture
* **[`skills/dpdp-compliance`](skills/dpdp-compliance/SKILL.md)**: Establishes DPDP legal notices, consent capture, timestamped consent ledgers, cookie preference banners, withdrawal mechanisms, and grievance dispatch.
* **[`skills/secure-development`](skills/secure-development/SKILL.md)**: 320-line threat-modeling and security hardening standard based on ASVS L2/L3 and OWASP Top 10.
* **[`skills/database-safety`](skills/database-safety/SKILL.md)**: Comprehensive database operations guide, safe migration patterns, expand-migrate-contract workflows, and ACID locking examples.
* **[`skills/flutter-production`](skills/flutter-production/SKILL.md)**: Complete production standard extracted from the DevFoxx Labs portfolio. Includes templates for Riverpod 2.6+ state, API clients, local cache, biometrics, auto-skeleton loaders, sheet insets, and layout matrix test helpers (37 files).

### 2. Design Intelligence & UI/UX
* **[`skills/ui-ux-pro-max`](skills/ui-ux-pro-max/SKILL.md)**: Design intelligence engine for web, mobile, and desktop. Includes searchable datasets for 79 design styles, 192 product palettes, 74 font pairings, 119 UX guidelines, 105 icons, and 22 technology stacks with bundled Python search tools (68 files).
* **[`skills/ui-styling`](skills/ui-styling/SKILL.md)**: Rapid UI creation with shadcn/ui components (Radix UI + Tailwind), custom themes, and canvas layout systems (16 files).
* **[`skills/design`](skills/design/SKILL.md)**: Multi-format brand identity system: logos, corporate identity programs (CIP), banners, icons, and social media image generation (35 files).
* **[`skills/design-system`](skills/design-system/SKILL.md)**: Three-layer design tokens (primitive → semantic → component), CSS variables, and token validation scripts (27 files).
* **[`skills/brand`](skills/brand/SKILL.md)**: Brand identity frameworks, tone of voice, asset management, and color extraction utilities (18 files).
* **[`skills/banner-design`](skills/banner-design/SKILL.md)**: Multi-format creative banner generator for social media, ads, website heroes, and print.
* **[`skills/slides`](skills/slides/SKILL.md)**: Strategic HTML presentation and slide deck builder with Chart.js visualization.

---

## 💻 Universal Installation

### Agent-Specific Installs (Windows PowerShell)

```powershell
# Install to Claude Code only (~/.claude)
.\install.ps1 -Claude

# Install to Google Antigravity & Gemini CLI only (~/.gemini)
.\install.ps1 -Gemini

# Install to Cursor only (~/.cursor)
.\install.ps1 -Cursor

# Install to Windsurf only (~/.codeium/windsurf)
.\install.ps1 -Windsurf

# Inject rules directly into a specific project codebase
.\install.ps1 -TargetProject "E:\DevFoxxLabsProjects\your-project"
```

### Agent-Specific Installs (macOS / Linux)

```bash
./install.sh claude      # ~/.claude
./install.sh gemini      # ~/.gemini
./install.sh cursor      # ~/.cursor
./install.sh windsurf    # ~/.codeium/windsurf
./install.sh /path/to/project
```

---

## 📂 Repository Layout

```
devfoxxlabs-agent-standards/
├── README.md                           # Documentation & master overview
├── manifest.json                       # Machine-readable registry of standards & skills
├── install.ps1                         # PowerShell universal installer (Windows)
├── install.sh                          # Bash universal installer (macOS/Linux)
├── sync.ps1                            # Bi-directional sync tool (repo <-> local agents)
├── LICENSE                             # MIT Open Source License
├── CONTRIBUTING.md                     # Contribution guidelines
│
├── .github/                            # Issue templates & community health
│   ├── ISSUE_TEMPLATE/
│   │   ├── new-standard.yml            # New rule/skill proposal template
│   │   └── bug-report.yml              # Bug report template
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

When you modify skills or rules locally and want to pull them back into this repository, or push updates across all machines:

```powershell
# Pull latest modifications from ~/.gemini into this repo
.\sync.ps1 -Action Pull

# Push latest repo updates back to all local agents
.\sync.ps1 -Action Push
```

---

## 🤝 Contributing

We welcome contributions from developers, security professionals, and compliance advisors! Please read our **[Contributing Guidelines](CONTRIBUTING.md)** before submitting a pull request.

---

## 📄 License & Attribution

Authored and maintained by **Karunendu Mishra** ([DevFoxx Labs](https://github.com/dev-karunendu-mishra)).  
Released under the [MIT License](LICENSE).
