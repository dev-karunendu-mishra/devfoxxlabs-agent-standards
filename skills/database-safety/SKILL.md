---
name: database-safety
description: Production-grade database standard for every app Karunendu (DevFoxx Labs) builds — MySQL/MariaDB, PostgreSQL, SQLite, Redis and app-local databases, through Laravel/Eloquent, Prisma/TypeORM/Sequelize/Knex, Drizzle or Flutter sqflite/drift. Always identify the environment (local / staging / production) before touching data, never break or lose data in any environment, follow ACID for every write, and ship schema changes as backward-compatible, reversible, tested migrations. Use for any migration, schema change, SQL file, seeder, data fix, query with writes, transaction, import/export, backup/restore or database config change.
metadata:
  author: karunendu
  version: "1.0.0"
---

# Database Safety — know where you are, never break data, always ACID

**Applies to every project and stack:** Laravel (Eloquent, migrations, `sql/*.sql` files), Node.js (Prisma, TypeORM, Sequelize, Knex, Drizzle), Next.js server code, Python, and app-local databases in Flutter/mobile (sqflite, drift, Hive, Isar). Also Redis and any queue/cache that holds state.

Data is the one thing a deploy can't roll back. Code can be redeployed in a minute; a dropped column, a half-run migration or a double-charged wallet can't be undone. So every database task follows three laws:

1. **Know the environment before you act** (§1).
2. **Never break or lose data in any environment** (§2–§4): changes are additive, backward-compatible, reversible, backed up and verified.
3. **Every write is ACID** (§5): atomic, consistent, isolated, durable.

---

## 1. Identify the environment first — every time

Before running **any** command that reads or writes a database (migrate, seed, tinker, SQL client, Prisma, scripts, imports), state in your reply which environment it targets and how you know.

- **Check, don't assume:**
  - Laravel: `php artisan about` (Environment + Database), `php artisan env`, `config('database.default')`, `DB_HOST`/`DB_DATABASE` in the *loaded* `.env`.
  - Node: `NODE_ENV`, `DATABASE_URL` host and database name (never print the password).
  - Flutter: the build flavor / `--dart-define` that picks the API base URL; a mobile app never connects to a server database directly.
  - Tests: confirm `phpunit.xml` / the test env uses a throwaway database (SQLite `:memory:` or a `_test` DB), never a shared one.
- **Treat it as production** if the host isn't `localhost`/`127.0.0.1`/a docker service name, the database name lacks `local`/`dev`/`test`, the credentials came from a deploy secret, or you're on an SSH session to a server, until proven otherwise.
- **What each environment allows:**

| Action | Local | Staging / QA | Production |
|---|---|---|---|
| Read queries | ✅ | ✅ | ✅ read-only user preferred; no `SELECT *` dumps of personal data |
| `migrate` (forward, reviewed) | ✅ | ✅ | ✅ only through the deploy pipeline, after a backup |
| `migrate:fresh` / `migrate:refresh` / `migrate:reset` / `db:wipe` / `prisma migrate reset` / `db push --force-reset` / `sequelize db:drop` | ✅ | ❌ unless the owner explicitly asks for a full reset of that environment | ❌ **never** |
| `migrate:rollback` / `down` migrations | ✅ | ⚠️ only with owner OK | ⚠️ only as a planned, tested rollback with a fresh backup |
| `db:seed` / demo / factory data | ✅ | ⚠️ idempotent reference data only | ⚠️ idempotent reference data only (settings, flags, plans); **never** fake users, demo bookings or known passwords |
| `DROP` / `TRUNCATE` / `DELETE` without `WHERE` / `UPDATE` without `WHERE` | ✅ | ❌ | ❌ |
| Hand-run SQL file | ✅ | ✅ after review | ✅ after review + backup + owner OK, then record it (see §3) |
| Data fix scripts | ✅ | ✅ dry-run first | ✅ dry-run → owner OK → backup → run → verify |

- **Hard guard in code** (set up in every project): Laravel `DB::prohibitDestructiveCommands(app()->isProduction())` in `AppServiceProvider::boot()` (blocks `db:wipe`, `migrate:fresh/refresh/reset` in production); Prisma: never `migrate dev`/`reset` in deploy scripts, only `migrate deploy`; a deploy script never runs seeders that create demo data.
- **Never** point a local `.env`, test or script at a production database "just to check". Use a masked copy or a read replica.
- Production and staging hold **real personal data** (DPDP): don't copy it to local or staging without masking/anonymising it, and don't paste rows into chat, logs or tickets.

## 2. Schema changes that never break anything (expand → migrate → contract)

Old app versions keep calling the API for weeks after a release, web and workers deploy at slightly different times, and production tables are large. So:

- **Additive first:** new tables, new **nullable** columns or columns with a `DEFAULT`, new indexes. Existing rows and existing code keep working.
- **Never in one step:** rename a column/table, change a type, make a column `NOT NULL`, or drop anything. Use **expand → migrate → contract**:
  1. *Expand:* add the new column/table; write to both old and new.
  2. *Migrate:* backfill in batches (idempotent, resumable); switch reads to the new one.
  3. *Contract:* only after every client (including old mobile builds) stops using the old one, and the owner agrees, drop it in a later release.
- **Drops and destructive changes** (`DROP COLUMN/TABLE`, `TRUNCATE`, narrowing a type, deleting rows) need an **explicit owner request**, a backup taken just before, and a note of what data is lost.
- **Constraints that protect data integrity** are part of the schema, not optional: primary keys; foreign keys with a deliberate `ON DELETE` (`restrict` for money and history, `cascade` only for true children, `set null` for optional links); `UNIQUE` for business rules (one booking per slot, one redemption per user per coupon, one payment per gateway ID); `NOT NULL` where a value is required; `CHECK` constraints where the engine enforces them (amount ≥ 0).
- **Types:** money as `DECIMAL(12,2)` or integer paise, never `FLOAT`; times in UTC (`timestamp`/`timestamptz`); enums as strings validated in code (easier to extend than DB enums); `utf8mb4` for text; JSON columns only for flexible, non-queried data.
- **Large tables (≫ 100k rows):** avoid locking DDL in busy hours; on MySQL prefer `ALGORITHM=INPLACE, LOCK=NONE` (or `INSTANT` for adding columns in 8.0+); add indexes online; backfill in chunks (`chunkById`, `LIMIT` loops) with a pause, never one giant `UPDATE`.
- **Every migration is reversible or explicitly irreversible:** write `down()` (or the Prisma/Knex equivalent). If a change can't be reversed (data deleted), say so in the migration and in the change log.
- **Migrations are code, reviewed like code:** one concern per migration; never edit a migration that has already run anywhere shared, so add a new one instead; no business logic or model classes inside migrations (models change later; use the query builder).
- **Idempotent and re-runnable:** guard with `Schema::hasColumn`/`hasTable`, `IF NOT EXISTS`, `information_schema` checks, so a partly applied change can be finished safely.
- **Backward compatibility with clients:** API responses keep old fields until all supported app versions stop reading them; new required fields get server-side defaults.

## 3. Project-specific delivery of schema changes

- If the project ships production schema as hand-written SQL (AstroGaon: `apps/weblaravel/sql/YYYY-MM-DD-*.sql` next to the migration), keep **both** in sync and follow that project's rules. SQL files are guarded and transactional where the engine allows. After running one on production, record the migration as run, so the pipeline's `migrate --force` doesn't fail.
- The deploy pipeline is the **only** path that runs migrations on staging/production. No ad-hoc `migrate` over SSH unless the owner asks for it.
- Each schema change gets a change-log entry: what changed, whether it's backward-compatible, the rollback plan and any owner step (run SQL, mark migration).

## 4. Before / during / after any production data change

1. **Plan:** what exactly changes, how many rows (`SELECT COUNT(*) … WHERE …` first), the rollback, and the downtime/lock risk.
2. **Backup:** a fresh backup or snapshot of the affected tables, *verified* (file exists, non-zero, restorable). Point-in-time recovery switched on where the host supports it.
3. **Dry run:** run on staging or a copy with production-like data; scripts have a `--dry-run` that prints the counts and sample changes without writing.
4. **Owner approval** for anything on production that isn't a reviewed, additive migration going through the pipeline.
5. **Run in a transaction** (see §5) with a row-count check: if the affected count differs from the plan, roll back.
6. **Verify:** `migrate:status`, row counts before and after, spot-check records, the app's health check and error tracker (Sentry) for new errors.
7. **Record:** change log entry and, for data fixes, who ran what and when.

## 5. ACID — every write, every stack

### Atomicity: all or nothing
- Any operation that writes **more than one row or table** runs in **one transaction**: booking + payment + wallet debit + coupon redemption + ledger entry; user + profile + role + consent record; order + items + stock.
  - Laravel: `DB::transaction(fn () => …, attempts: 3)`
  - Prisma: `prisma.$transaction([...])` or the interactive `$transaction(async (tx) => …)`
  - TypeORM: `dataSource.transaction(async (m) => …)`
  - Sequelize: `sequelize.transaction(async (t) => …)`
  - Knex: `knex.transaction(…)`
  - Flutter sqflite/drift: `db.transaction((txn) async {...})`
- **Never** call slow or irreversible external services *inside* a transaction (payment gateway, SMS, email, push, HTTP APIs, file uploads): they can't be rolled back and they hold locks.
  - Do the DB work, commit, then dispatch side effects **after commit**: `DB::afterCommit()`, `->afterCommit()` on jobs, events and notifications, or `after_commit => true` on the queue connection.
  - For must-not-lose messages, use the **transactional outbox** pattern: write the message row in the same transaction, and let a worker send it.
- Don't swallow exceptions inside a transaction (`try { … } catch {}` that continues). A failed step must abort the whole unit.
- Multi-statement SQL files: `START TRANSACTION; … COMMIT;`. Remember MySQL DDL **auto-commits** (it can't be rolled back), so keep DDL and data changes in separate, idempotent steps.

### Consistency: the database enforces the rules
- Invariants live in **constraints** (FK, UNIQUE, NOT NULL, CHECK), not only in application code. Two app servers or a queue worker can bypass app-only checks.
- Status changes follow a state machine checked inside the transaction (`pending → confirmed → completed`; never `cancelled → paid`), using a conditional update: `UPDATE … SET status='paid' WHERE id=? AND status='pending'`, then check the affected row count.
- Derived values (balances, counters, totals) are either computed from the ledger or updated in the same transaction as the ledger row. Never `balance = balance_from_client`.
- Validation happens before the transaction; the transaction re-checks anything that can change concurrently (stock, slot availability, balance, coupon capacity).

### Isolation: concurrent requests don't corrupt each other
- **Read-modify-write on shared rows** (wallet balance, stock, slots, coupon usage, counters) must lock or be atomic:
  - Laravel `->lockForUpdate()` inside the transaction;
  - SQL `SELECT … FOR UPDATE`;
  - Prisma raw `FOR UPDATE`, or atomic `update({ data: { balance: { decrement: x } }, where: { id, balance: { gte: x } } })`;
  - atomic increments (`increment()`, `UPDATE … SET n = n + 1`).
- **Idempotency** for anything a client or webhook can retry: a unique key (gateway payment ID, `Idempotency-Key` header, event ID) with a `UNIQUE` index, so the second attempt becomes a no-op instead of a double credit.
- Know the default isolation level (MySQL InnoDB: REPEATABLE READ; PostgreSQL: READ COMMITTED). Use `SERIALIZABLE` or explicit locks for invariants that span rows (no double booking of a slot), or enforce them with a UNIQUE constraint.
- **Deadlocks** are normal under load: lock rows in a consistent order, keep transactions short, and retry (Laravel `DB::transaction(..., 3)`, a retry loop on Prisma `P2034` / MySQL 1213).
- Test the dangerous ones: two concurrent requests paying from the same wallet, or booking the same slot. Exactly one must succeed.
- Queue workers and cron jobs: make jobs idempotent and unique (`ShouldBeUnique`, `withoutOverlapping()`), and re-read state inside the job.

### Durability: committed data survives crashes
- Transactional engine only (MySQL **InnoDB**, never MyISAM); keep `innodb_flush_log_at_trx_commit=1` and `sync_binlog=1` on production where you control them; PostgreSQL `fsync`/`synchronous_commit` on.
- Backups: automated, **off-site, encrypted, versioned/immutable**, retention per data type; a **restore test** at least quarterly with a recorded RTO/RPO; binlog/WAL for point-in-time recovery where available.
- Redis/cache is **not** a source of truth: anything that must survive (payments, balances, bookings, consents, OTP attempts that matter) is in the database. If Redis holds queues, enable persistence (AOF) or use a database/SQS queue for critical jobs.
- App-local databases (Flutter): data that matters is on the server; local stores are caches that can be rebuilt; local schema has versioned migrations (`onUpgrade` / drift `MigrationStrategy`) so an app update never crashes on old data.

## 6. Queries & access

- ORM / query builder / bound parameters only; never interpolate input into SQL (see `secure-development`).
- Every `UPDATE`/`DELETE` has a `WHERE` that you have run as a `SELECT COUNT(*)` first; mass operations go through the ORM's `chunkById` or batched loops.
- Soft-delete (`deleted_at`) for user-facing records that other data depends on; hard-delete only for legal erasure (DPDP) through the one shared deletion service, keeping legally required records (invoices) anonymised.
- Indexes for every foreign key and every column used in `WHERE`/`ORDER BY` on large tables; check `EXPLAIN` for new heavy queries; avoid N+1 queries (eager loading).
- Separate DB users: the app user has only DML on its schema (no `DROP`, `GRANT`, `FILE`, `SUPER`); migrations use a deploy user; humans use read-only accounts for investigation.
- Connection settings: timeouts, a pool size within the server's `max_connections`, TLS for remote connections, the database not reachable from the internet.

## 7. Tests

- Tests run on a throwaway database (`RefreshDatabase`, transactions per test, Prisma test DB) and **never** on a shared one.
- If tests use SQLite while production is MySQL/PostgreSQL, know the differences (no `ALTER … AFTER`, weaker FK/type checks, different JSON and date functions, transactional DDL). Run migrations against the real engine in CI (a MySQL service container) at least for schema changes.
- For every schema change, test: migrate up on an empty DB; migrate up on a DB with existing rows (defaults fill, nothing fails); `down()` if supported; the app and API still return the old fields.
- For money and concurrency: transaction rollback on failure (nothing half-written), idempotent retry (second call is a no-op), and concurrent-request tests where practical.

## 8. Definition of done — database

- [ ] Environment stated (local / staging / production) and checked, not assumed.
- [ ] No destructive command or statement on staging/production without an explicit owner request, a fresh verified backup and a rollback plan.
- [ ] Schema change is additive / backward-compatible (expand → migrate → contract), idempotent, reversible (or marked irreversible), with constraints and correct types.
- [ ] Project delivery rules followed (e.g. matching `sql/*.sql`, migration recorded after a manual run).
- [ ] Multi-row/table writes in one transaction; no external calls inside it; side effects after commit.
- [ ] Shared-row updates locked or atomic; retries idempotent via unique keys; deadlocks retried.
- [ ] Tests: migration up on existing data, rollback-on-failure, idempotency/concurrency for money paths; suite green.
- [ ] Change log entry with backward-compatibility note, rollback plan and owner steps; owner-only steps on the owner TODO.
