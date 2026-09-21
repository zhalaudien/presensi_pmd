import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presensi_pmd/core/providers/core_providers.dart';
import 'package:presensi_pmd/features/auth/data/auth_repository.dart';
import 'package:presensi_pmd/features/auth/domain/user_model.dart';

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? errorMessage;

  AuthState({
    this.isLoading = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;

  AuthController(this._authRepo)
      : super(AuthState(user: _authRepo.currentUser)) {
    checkSession();
  }

  Future<void> checkSession() async {
    if (_authRepo.isAuthenticated) {
      final user = await _authRepo.getMe();
      state = state.copyWith(user: user ?? _authRepo.currentUser);
    }
  }

  Future<bool> login(String login, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _authRepo.login(login: login, password: password);
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _authRepo.logout();
    state = AuthState();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});
