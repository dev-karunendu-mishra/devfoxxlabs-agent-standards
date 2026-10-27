# Global Rule — Database Safety: Know The Environment, Never Break Data, Always ACID

Applies to every database task in every stack (Laravel/Eloquent + `sql/*.sql`, Prisma/TypeORM/Sequelize/Knex/Drizzle, raw SQL, Redis, Flutter sqflite/drift): migrations, schema changes, seeders, data fixes, imports, writes, transactions, backups. Full standard: the **`database-safety`** skill (`skills/database-safety/SKILL.md`).

- **Environment first, every time:** before any DB command, state which environment it hits (local / staging / production) and how you checked (`php artisan about`, `DB_HOST`/`DB_DATABASE`, `DATABASE_URL` host, flavor). Unknown or remote host = treat as **production**.
- **Production & staging are never broken:** no `migrate:fresh/refresh/reset`, `db:wipe`, `prisma migrate reset`, `DROP`, `TRUNCATE`, or `UPDATE`/`DELETE` without `WHERE`, and no demo seeders there. Destructive steps only on the owner's explicit request + fresh verified backup + rollback plan. Guard it in code (`DB::prohibitDestructiveCommands(app()->isProduction())`; Prisma `migrate deploy` only).
- **Schema changes are additive and backward-compatible:** nullable/defaulted columns, expand → migrate (batched backfill) → contract (drop only later, after old app versions stop using it); idempotent (`IF NOT EXISTS`/`hasColumn`), reversible `down()`, never edit an already-run migration; migrations reach staging/production only through the deploy pipeline; keep project SQL files in sync.
- **Integrity in the database:** PK/FK (deliberate `ON DELETE`), `UNIQUE` for business rules (one payment per gateway ID, one booking per slot), `NOT NULL`, `CHECK`; money `DECIMAL`/paise, never float; UTC times; InnoDB only.
- **ACID on every write:**
  - **A**: multi-row/table writes in one transaction. No payment/SMS/email/HTTP calls inside it; side effects run after commit (`afterCommit`, outbox).
  - **C**: invariants enforced by constraints and conditional updates (`… WHERE status='pending'`, check affected rows).
  - **I**: shared rows (balance, stock, slots, coupons) locked (`lockForUpdate` / `FOR UPDATE`) or updated atomically; idempotency keys with UNIQUE indexes; deadlocks retried.
  - **D**: durable engine settings; off-site, encrypted, versioned backups with a tested restore; Redis/cache is never the source of truth.
- **Production data changes:** count first → backup → dry run on staging → owner OK → run in a transaction with a row-count check → verify (`migrate:status`, counts, error tracker) → change log.
- Never copy real personal data to local/staging unmasked, and never paste rows into chat or logs.
- Tests: throwaway DB only; migrations tested on existing rows and on the real engine for schema changes; rollback-on-failure and idempotency tests for money paths.
- Write this rule (or a pointer to it) into each project's own rules file when setting a project up.

