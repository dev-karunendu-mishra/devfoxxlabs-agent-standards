# Contributing to DevFoxx Labs Agent Standards

Thank you for your interest in contributing! We welcome contributions from developers, security professionals, compliance advisors, and AI researchers to make AI pair programming safer, more robust, and legally compliant.

---

## 🏛️ Guiding Principles

Every standard and skill added to this repository must satisfy:
1. **Zero Hallucination / Defense in Depth**: Rules must enforce concrete programmatic safeguards (e.g., server validation, tests, ACID constraints) rather than vague advice.
2. **Deterministic & Production-Tested**: Extracted from real-world, high-traffic production workloads.
3. **Cross-Agent Portable**: Must work transparently across Claude Code, Google Antigravity / Gemini CLI, Cursor, Windsurf, and Universal Agents (`~/.agents`).

---

## 🛠️ How to Add a New Skill

1. Create a directory under `skills/<skill-name>/`.
2. Provide a self-contained `SKILL.md` with:
   - Proper YAML frontmatter (`name`, `description`, `metadata: { author, version }`).
   - Clear trigger conditions.
   - Actionable implementation checklists and code recipes.
3. If bundled scripts are included, use standard language libraries (e.g. Python standard library) with zero external dependency bloat.
4. Add the entry to `manifest.json`.

---

## 📋 Pull Request Process

1. Fork the repository and create your feature branch:
   ```bash
   git checkout -b feat/my-new-standard
   ```
2. Commit your changes following Conventional Commits (`feat:`, `fix:`, `docs:`):
   ```bash
   git commit -m "feat(standards): add WebAuthn authentication standard"
   ```
3. Push to your fork and submit a Pull Request.
4. Verify all markdown files render cleanly with GitHub Flavored Markdown.

---

## 💬 Community & Questions

For questions or discussions, please open an Issue or start a Discussion on GitHub:
👉 https://github.com/dev-karunendu-mishra/devfoxxlabs-agent-standards/issues

