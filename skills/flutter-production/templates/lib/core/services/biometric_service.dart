import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricOutcome {
  success,

  /// The user closed the prompt (or the system did, e.g. an incoming call).
  cancelled,

  /// Too many failed attempts; the phone's screen lock usually still works.
  lockedOut,

  /// No fingerprint, face or screen lock is set up on this phone.
  notAvailable,
  failed,
}

class BiometricResult {
  final BiometricOutcome outcome;

  /// Shown under the Unlock button; null when there is nothing to explain.
  final String? message;

  const BiometricResult(this.outcome, [this.message]);

  bool get isSuccess => outcome == BiometricOutcome.success;
}

/// Fingerprint / Face ID with the phone's PIN, pattern or passcode as the
/// fallback. Tests pass a fake to [AppLockProvider].
class BiometricService {
  final LocalAuthentication _auth;

  BiometricService({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  /// True when the phone has a fingerprint, face or screen lock to check.
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (isSupported) return true;
      return await _auth.canCheckBiometrics;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<BiometricResult> authenticate(String reason) async {
    if (kIsWeb) {
      return const BiometricResult(
        BiometricOutcome.notAvailable,
        _notAvailableMessage,
      );
    }
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );
      return ok
          ? const BiometricResult(BiometricOutcome.success)
          : const BiometricResult(
              BiometricOutcome.failed,
              "Couldn't confirm it's you. Try again.",
            );
    } on LocalAuthException catch (e) {
      return _fromException(e.code);
    } on MissingPluginException {
      return const BiometricResult(
        BiometricOutcome.notAvailable,
        _notAvailableMessage,
      );
    } on PlatformException catch (e) {
      if (e.code == 'NotEnrolled' || e.code == 'PasscodeNotSet') {
        return const BiometricResult(
          BiometricOutcome.notAvailable,
          _notAvailableMessage,
        );
      } else if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        return const BiometricResult(
          BiometricOutcome.lockedOut,
          "Too many attempts. Wait a moment, or unlock with your phone's PIN or pattern.",
        );
      }
      return const BiometricResult(
        BiometricOutcome.failed,
        "Couldn't confirm it's you. Try again.",
      );
    } catch (_) {
      return const BiometricResult(
        BiometricOutcome.failed,
        "Couldn't confirm it's you. Try again.",
      );
    }
  }

  static const _notAvailableMessage =
      'Set up a fingerprint, face or screen lock on this phone to use App Lock.';

  static BiometricResult _fromException(LocalAuthExceptionCode code) {
    switch (code) {
      case LocalAuthExceptionCode.userCanceled:
      case LocalAuthExceptionCode.systemCanceled:
      case LocalAuthExceptionCode.timeout:
      case LocalAuthExceptionCode.userRequestedFallback:
      case LocalAuthExceptionCode.authInProgress:
      case LocalAuthExceptionCode.uiUnavailable:
        return const BiometricResult(BiometricOutcome.cancelled);
      case LocalAuthExceptionCode.temporaryLockout:
      case LocalAuthExceptionCode.biometricLockout:
        return const BiometricResult(
          BiometricOutcome.lockedOut,
          "Too many attempts. Wait a moment, or unlock with your phone's PIN or pattern.",
        );
      case LocalAuthExceptionCode.noCredentialsSet:
      case LocalAuthExceptionCode.noBiometricsEnrolled:
      case LocalAuthExceptionCode.noBiometricHardware:
        return const BiometricResult(
          BiometricOutcome.notAvailable,
          _notAvailableMessage,
        );
      default:
        return const BiometricResult(
          BiometricOutcome.failed,
          "Couldn't confirm it's you. Try again.",
        );
    }
  }
}
