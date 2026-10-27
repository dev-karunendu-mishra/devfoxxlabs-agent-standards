# Global Rule — Icons: Hugeicons (Free) Everywhere

Applies to every frontend built — Web (React / Next.js / Vue / Angular / plain HTML) and Mobile (Flutter / React Native).

## 1. Core Mandate
- Use **only Hugeicons, free set** (Stroke Rounded):
  - **Web / React / Next.js:** `@hugeicons/react` (`HugeiconsIcon` component) + `@hugeicons/core-free-icons` (named imports, tree-shaken).
  - **Flutter:** the `hugeicons` package from pub.dev.
- **Never add another icon library**:
  - Do not add `lucide-react`, `heroicons`, `react-icons`, `font-awesome`, `Material Icons` (`Icons.*`), `Cupertino icons`, etc.
  - Never draw ad-hoc inline SVG icons. Brand logos, payment badges, or custom mascot illustrations are assets/images, not icons.
- **Never use Hugeicons Pro packages** (`@hugeicons-pro/*`) unless a Pro license has been explicitly confirmed by the project owner.

## 2. Accessibility (a11y)
- **Interactive Icon-only buttons:** MUST have an accessible label (`aria-label` in HTML/React, `Semantics(label: ...)` or `tooltip` in Flutter).
- **Decorative icons:** Must be hidden from screen readers (`aria-hidden="true"` in HTML/React, `ExcludeSemantics` in Flutter).

## 3. Migration
- If an existing project already uses a different icon library (e.g. legacy Lucide or Material Icons), list all instances and ask the owner before executing a bulk migration.
- Write this rule into each project's own design system documentation upon initialization.

