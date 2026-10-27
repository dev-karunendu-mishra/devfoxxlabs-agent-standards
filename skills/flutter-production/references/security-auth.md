# Security, Auth & Privacy

## AuthSession (`templates/lib/features/auth/data/auth_session.dart`)

- A `ChangeNotifier` singleton (`AuthSession.instance`) that holds `token` and `user`. It
  is exposed to Riverpod through `authSessionProvider`, `currentUserProvider` and
  `isSignedInProvider`.
- Persistence goes through a `SecureKeyValueStore` interface. The production
  implementation wraps `FlutterSecureStorage`, and tests swap in an in-memory fake
  (`AuthSession.debugOverrideStore`).
- `restore()` reads the token and user JSON with a **3 s timeout**. On a corrupt or
  missing value it falls back to signed-out and never crashes startup. It sets
  `isRestored` and notifies.
- `signIn(token, user)` writes both values. `signOut()` clears them, deactivates the
  push token, turns the app lock off, and `LocalApiCache.instance.invalidate()`.
- Tokens are **never** stored in `SharedPreferences`, plain files or logs.
- Login: phone OTP (`OtpPinField`), email or Google, plus the legal line "By continuing
  you agree to the Terms and Privacy Notice" next to the button. Optional consents start
  unticked (DPDP).
- Role-gated apps reject unsupported roles at login and show an "admin only" screen.

## App lock (adminastrogaon / astrogaon pattern)

- Opt-in in Settings. When it is on, the app is locked on cold start and **every** time it
  returns from background, with no grace period. It is covered in the app switcher
  (`FLAG_SECURE` through a method channel) while the setting is on.
- `BiometricService` wraps `local_auth`: `authenticate(reason, biometricOnly: false, persistAcrossBackgrounding: true)`.
  The phone PIN or pattern is the fallback. Exceptions map to a `BiometricOutcome`
  (success / cancelled / lockedOut / notAvailable / failed) with a friendly message.
- **Fail closed:** any exception means "not authenticated", never "authenticated by default".
- `AppLockProvider.keepUnlockedDuring(() => picker())` wraps every file or photo picker,
  save dialog, share sheet and payment sheet, so returning from it does not lock. Links
  opened in other apps (`launchUrl`) do lock on return.
- `AppLockGate` sits in `MaterialApp.builder` above the navigator. Never push routes or
  dialogs from the lock screen. It offers Unlock and "Sign out".
- The lock belongs to the session: signing out turns it off.

## Payments (Razorpay)

- **The server creates the order and amount.** The app opens checkout with the order id
  and the public key id. **The server verifies the signature**, and the webhook
  (`payment.captured`) is final.
- Never ship the key secret. Never compute payable amounts on the device.
- Cancelling the sheet is not an error, so show nothing. If verification fails after
  success, the money was taken. Show "processing, don't pay again" and let the webhook
  confirm.
- Wrap the gateway in a `PaymentCheckout` interface and pass a fake in tests.

## Secrets and config

- No API secrets in the binary. Anything shipped (Maps key, Firebase config) is treated
  as public and restricted in its console.
- Use `--dart-define-from-file=config/<flavor>.json` for base URLs and keys. Gitignore the
  real files and commit `config/example.json`.
- `key.properties` and keystores are never committed.

## Data protection (DPDP + good practice)

- Follow the `dpdp-compliance` skill: a Privacy & Legal screen available to guests and
  signed-in users, "Your consents" with switches and timestamped history, privacy request
  form, Grievance Officer card, data download, deactivation and **in-app account
  deletion**.
- No analytics, ads or attribution SDK initialised before consent. OS permissions
  (camera, location, contacts, notifications, mic) are requested **just in time** with a
  reason screen, and denial is handled gracefully.
- Never log PII or tokens. `debugPrint` is only for non-personal diagnostics, and
  `avoid_print` stays on.
- Validate every input at the form boundary (phone, email, required fields).
- Before using a stored file path, check `File(path).existsSync()` and have a fallback.
- Exports and backups stay local unless the user taps Share or Export.
- Strip client PII from payloads sent to external AI APIs.
- Signed short-lived URLs for private files (use `AppNetworkImage.cacheKey` so the
  image caches).
- The Play Data Safety form and the App Store privacy labels must match what the app
  actually collects.
