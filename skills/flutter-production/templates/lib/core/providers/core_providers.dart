import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../features/auth/data/auth_session.dart';
import '../../features/auth/models/app_user.dart';
import '../network/api_client.dart';
import '../services/biometric_service.dart';

/// Global [ApiClient]. Repositories default to `const ApiClient()` too, so
/// tests override repositories rather than this.
final apiClientProvider = Provider<ApiClient>((ref) => const ApiClient());

/// The singleton [AuthSession], bridged from ChangeNotifier into Riverpod.
final authSessionProvider = ChangeNotifierProvider<AuthSession>(
  (ref) => AuthSession.instance,
);

final currentUserProvider = Provider<AppUser?>(
  (ref) => ref.watch(authSessionProvider).user,
);

final isSignedInProvider = Provider<bool>(
  (ref) => ref.watch(authSessionProvider).isSignedIn,
);

final biometricServiceProvider = Provider<BiometricService>(
  (ref) => BiometricService(),
);
