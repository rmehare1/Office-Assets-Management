import 'package:dio/dio.dart';
import '../models/asset.dart';
import '../models/category.dart';
import '../models/status.dart';
import '../models/user.dart';
import 'api_config.dart';
import 'token_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

class ApiService {
  late final Dio _dio;
  final TokenStorage _tokenStorage;

  ApiService({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      sendTimeout: ApiConfig.timeout,
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.addAll([
      AuthInterceptor(_tokenStorage),
      RetryInterceptor(dio: _dio),
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);
  }

  TokenStorage get tokenStorage => _tokenStorage;

  // Kept for backward compat with AuthProvider
  void setToken(String? token) {
    if (token != null) {
      _tokenStorage.setToken(token);
    } else {
      _tokenStorage.clearToken();
    }
  }

  // ── Auth ────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    // Persist token securely
    final token = data['token'] as String?;
    if (token != null) {
      await _tokenStorage.setToken(token);
    }
    return data;
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String department,
    String role, {
    String? phone,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'department': department,
      'role': role,
      if (phone != null) 'phone': phone,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<AppUser> getMe() async {
    final response = await _dio.get('/auth/me');
    final data = response.data as Map<String, dynamic>;
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  // ── Assets ──────────────────────────────────────────

  Future<List<Asset>> getAssets({
    String? statusId,
    String? categoryId,
    String? search,
    String? sort,
    String? order,
  }) async {
    final params = <String, dynamic>{};
    if (statusId != null) params['status_id'] = statusId;
    if (categoryId != null) params['category_id'] = categoryId;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (sort != null) params['sort'] = sort;
    if (order != null) params['order'] = order;

    final response = await _dio.get('/assets', queryParameters: params);
    final data = response.data as Map<String, dynamic>;
    final list = data['assets'] as List;
    return list.map((j) => Asset.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<Asset> getAsset(String id) async {
    final response = await _dio.get('/assets/$id');
    final data = response.data as Map<String, dynamic>;
    return Asset.fromJson(data['asset'] as Map<String, dynamic>);
  }

  Future<Asset> createAsset(Asset asset) async {
    final response = await _dio.post('/assets', data: asset.toJson());
    final data = response.data as Map<String, dynamic>;
    return Asset.fromJson(data['asset'] as Map<String, dynamic>);
  }

  Future<Asset> updateAsset(Asset asset) async {
    final response = await _dio.put('/assets/${asset.id}', data: asset.toJson());
    final data = response.data as Map<String, dynamic>;
    return Asset.fromJson(data['asset'] as Map<String, dynamic>);
  }

  Future<void> deleteAsset(String id) async {
    await _dio.delete('/assets/$id');
  }

  Future<Map<String, dynamic>> getAssetStats() async {
    final response = await _dio.get('/assets/stats/summary');
    return response.data as Map<String, dynamic>;
  }

  // ── Users ───────────────────────────────────────────

  Future<List<AppUser>> getUsers() async {
    final response = await _dio.get('/users');
    final data = response.data as Map<String, dynamic>;
    final list = data['users'] as List;
    return list.map((j) => AppUser.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<AppUser> getUser(String id) async {
    final response = await _dio.get('/users/$id');
    final data = response.data as Map<String, dynamic>;
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  // ── Categories ──────────────────────────────────────

  Future<List<Category>> getCategories() async {
    final response = await _dio.get('/categories');
    final list = response.data as List;
    return list.map((j) => Category.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<Category> createCategory(Category category) async {
    final response = await _dio.post('/categories', data: category.toJson());
    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Category> updateCategory(Category category) async {
    final response = await _dio.put('/categories/${category.id}', data: category.toJson());
    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCategory(String id) async {
    await _dio.delete('/categories/$id');
  }

  // ── Statuses ────────────────────────────────────────

  Future<List<Status>> getStatuses() async {
    final response = await _dio.get('/statuses');
    final list = response.data as List;
    return list.map((j) => Status.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<Status> createStatus(Status status) async {
    final response = await _dio.post('/statuses', data: status.toJson());
    return Status.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Status> updateStatus(Status status) async {
    final response = await _dio.put('/statuses/${status.id}', data: status.toJson());
    return Status.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteStatus(String id) async {
    await _dio.delete('/statuses/$id');
  }
}
