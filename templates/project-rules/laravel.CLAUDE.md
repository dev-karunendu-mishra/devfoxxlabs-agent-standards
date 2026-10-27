# Laravel & API Backend Rules (Project Template)

## 1. S.O.L.I.D & Architecture
- Follow S.O.L.I.D principles on every new implementation.
- Keep controllers thin; extract business domain logic into Service classes (e.g. `WalletService`, `BookingService`).
- Form requests for all input validation with explicit allow-list rules.

## 2. Use What Is Already Installed
Before installing a package, check `composer.json` and `package.json`.
- File uploads: `spatie/laravel-medialibrary` (mandatory, with WebP and responsive conversions).
- Permissions: `spatie/laravel-permission` (`HasRoles`).
- Activity Logs: `spatie/laravel-activitylog` (`LogsActivity`).
- Settings: `spatie/laravel-settings`.
- Slugs: `spatie/laravel-sluggable`.
- API Tokens: `laravel/passport` or `laravel/sanctum` (never mix both `HasApiTokens`).
- Currency: `akaunting/laravel-money`.
- API Docs: `dedoc/scramble` (type hints & docblocks on all endpoints).

## 3. Database Safety & ACID
- State and check the environment first (`php artisan about`).
- Production guard in `AppServiceProvider::boot()`: `DB::prohibitDestructiveCommands(app()->isProduction())`.
- Schema changes are additive (expand -> migrate -> contract).
- Financial, wallet, bookings, and payment mutations must execute inside `DB::transaction()` with `lockForUpdate()`.
- No third-party API calls (Razorpay, SMS, mail, push) inside database transactions; dispatch after commit (`DB::afterCommit()`).

## 4. Security & DPDP Compliance
- Authorization check on every client-sent ID (verify user owns the resource).
- Never trust the client for money, discounts, or prices.
- Rate limit all public write routes (`throttle:60,1` or stricter for auth/OTP).
- Implement DPDP legal endpoints: versioned `GET /legal/{slug}` and append-only `consent_records` ledger.

