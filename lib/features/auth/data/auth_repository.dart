import 'package:presensi_pmd/core/constants/api_endpoints.dart';
import 'package:presensi_pmd/core/network/api_client.dart';
import 'package:presensi_pmd/core/storage/preferences_helper.dart';
import 'package:presensi_pmd/features/auth/domain/cabang_model.dart';
import 'package:presensi_pmd/features/auth/domain/user_model.dart';

class AuthRepository {
  final ApiClient apiClient;
  final PreferencesHelper prefs;

  AuthRepository({required this.apiClient, required this.prefs});

  Future<Map<String, dynamic>> getConfig() async {
    try {
      final res = await apiClient.get(ApiEndpoints.config);
      if (res.data != null && res.data['data'] is Map<String, dynamic>) {
        final data = res.data['data'] as Map<String, dynamic>;
        if (data['quick_chips'] is List) {
          final chips = (data['quick_chips'] as List).map((e) => e.toString()).toList();
          await prefs.setQuickChips(chips);
        }
        return data;
      }
    } catch (_) {}
    return {};
  }

  Future<UserModel> login({required String login, required String password}) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      data: {
        'login': login.trim(),
        'password': password,
      },
    );

    final resData = response.data;
    if (resData == null || resData['success'] != true) {
      throw ApiException(message: resData?['message'] ?? 'Login gagal.');
    }

    final data = resData['data'] as Map<String, dynamic>;
    final token = (data['token'] ?? data['access_token'] ?? '').toString();
    if (token.isEmpty) {
      throw ApiException(message: 'Token otentikasi tidak ditemukan dalam respons.');
    }

    await prefs.setToken(token);

    final userJson = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : data;

    final user = UserModel.fromJson(userJson);
    await prefs.setUser(user.toJson());

    if (user.cabang != null) {
      await prefs.setCabang(user.cabang!.toJson());
    } else if (data['cabang'] is Map<String, dynamic>) {
      await prefs.setCabang(data['cabang'] as Map<String, dynamic>);
    }

    // Also fetch config in background
    getConfig().ignore();

    return user;
  }

  Future<UserModel?> getMe() async {
    try {
      final response = await apiClient.get(ApiEndpoints.me);
      if (response.data != null && response.data['data'] is Map<String, dynamic>) {
        final data = response.data['data'] as Map<String, dynamic>;
        final user = UserModel.fromJson(data);
        await prefs.setUser(user.toJson());
        if (user.cabang != null) {
          await prefs.setCabang(user.cabang!.toJson());
        }
        return user;
      }
    } catch (_) {}

    // Fallback from cache
    final localUser = prefs.getUser();
    if (localUser != null) {
      return UserModel.fromJson(localUser);
    }
    return null;
  }

  Future<void> logout() async {
    try {
      await apiClient.post(ApiEndpoints.logout);
    } catch (_) {}
    await prefs.clearSession();
  }

  UserModel? get currentUser {
    final map = prefs.getUser();
    if (map == null) return null;
    return UserModel.fromJson(map);
  }

  CabangModel? get currentCabang {
    final map = prefs.getCabang();
    if (map == null) return null;
    return CabangModel.fromJson(map);
  }

  bool get isAuthenticated => prefs.hasToken();
}
