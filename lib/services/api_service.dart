import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:office_assets_app/models/asset.dart';
import 'package:office_assets_app/models/category.dart';
import 'package:office_assets_app/models/department.dart';
import 'package:office_assets_app/models/location.dart';
import 'package:office_assets_app/models/status.dart';
import 'package:office_assets_app/models/ticket.dart';
import 'package:office_assets_app/models/user.dart';
import 'package:office_assets_app/models/maintenance_alert.dart';
import 'package:office_assets_app/models/asset_log.dart';
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
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.timeout,
        receiveTimeout: ApiConfig.timeout,
        sendTimeout: ApiConfig.timeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

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

  Future<T> _wrap<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // ── Auth ────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String?;
      if (token != null) await _tokenStorage.setToken(token);
      return data;
    });
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password, {
    String? department,
    String? phone,
  }) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          if (department != null && department.isNotEmpty)
            'department': department,
          if (phone != null) 'phone': phone,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String?;
      if (token != null) await _tokenStorage.setToken(token);
      return data;
    });
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
      return response.data as Map<String, dynamic>;
    });
  }

  Future<Map<String, dynamic>> resetPassword(
    String email,
    String token,
    String newPassword,
  ) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {'email': email, 'token': token, 'newPassword': newPassword},
      );
      return response.data as Map<String, dynamic>;
    });
  }

  Future<AppUser> getMe() async {
    final response = await _dio.get('/auth/me');
    final data = response.data as Map<String, dynamic>;
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> updateProfile(
    String name, {
    String? phone,
    String? department,
    String? email,
  }) async {
    try {
      final response = await _dio.patch(
        '/auth/me',
        data: {
          'name': name,
          if (phone != null) 'phone': phone,
          if (department != null) 'department': department,
          if (email != null) 'email': email,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await _dio.patch(
        '/auth/password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw e.error ?? e;
    }
  }

  // ── Assets ──────────────────────────────────────────

  Future<List<Asset>> getAssets({
    String? statusId,
    String? categoryId,
    String? search,
    String? sort,
    String? order,
    String? assignedToUserId,
  }) async {
    return _wrap(() async {
      final params = <String, dynamic>{};
      if (statusId != null) params['status_id'] = statusId;
      if (categoryId != null) params['category_id'] = categoryId;
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (sort != null) params['sort'] = sort;
      if (order != null) params['order'] = order;
      if (assignedToUserId != null) params['assigned_to'] = assignedToUserId;

      final response = await _dio.get('/assets', queryParameters: params);
      final data = response.data as Map<String, dynamic>;
      final list = data['assets'] as List;
      return list
          .map((j) => Asset.fromJson(j as Map<String, dynamic>))
          .toList();
    });
  }

  Future<Asset> getAsset(String id) async {
    return _wrap(() async {
      final response = await _dio.get('/assets/$id');
      final data = response.data as Map<String, dynamic>;
      return Asset.fromJson(data['asset'] as Map<String, dynamic>);
    });
  }

  Future<Asset> createAsset(Asset asset) async {
    return _wrap(() async {
      final response = await _dio.post('/assets', data: asset.toJson());
      final data = response.data as Map<String, dynamic>;
      return Asset.fromJson(data['asset'] as Map<String, dynamic>);
    });
  }

  Future<Asset> updateAsset(Asset asset) async {
    return _wrap(() async {
      final response = await _dio.put(
        '/assets/${asset.id}',
        data: asset.toJson(),
      );
      final data = response.data as Map<String, dynamic>;
      return Asset.fromJson(data['asset'] as Map<String, dynamic>);
    });
  }

  Future<void> deleteAsset(String id) async {
    return _wrap(() => _dio.delete('/assets/$id'));
  }

  Future<Map<String, dynamic>> getAssetStats() async {
    return _wrap(() async {
      final response = await _dio.get('/assets/stats/summary');
      return response.data as Map<String, dynamic>;
    });
  }

  /// Lookup an asset by scanned barcode/QR code value.
  /// Returns null if no asset matches (404).
  Future<Asset?> lookupAssetByCode(String code) async {
    try {
      final response = await _dio.get(
        '/assets/lookup',
        queryParameters: {'code': code},
      );
      final data = response.data as Map<String, dynamic>;
      return Asset.fromJson(data['asset'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<AssetLog>> getAssetHistory(String assetId) async {
    return _wrap(() async {
      final response = await _dio.get('/assets/$assetId/history');
      final data = response.data as Map<String, dynamic>;
      final list = data['history'] as List;
      return list
          .map((j) => AssetLog.fromJson(j as Map<String, dynamic>))
          .toList();
    });
  }

  // ── Users ───────────────────────────────────────────

  Future<List<AppUser>> getUsers() async {
    return _wrap(() async {
      final response = await _dio.get('/users');
      final data = response.data as Map<String, dynamic>;
      final list = data['users'] as List;
      return list
          .map((j) => AppUser.fromJson(j as Map<String, dynamic>))
          .toList();
    });
  }

  Future<AppUser> getUser(String id) async {
    return _wrap(() async {
      final response = await _dio.get('/users/$id');
      final data = response.data as Map<String, dynamic>;
      return AppUser.fromJson(data['user'] as Map<String, dynamic>);
    });
  }

  Future<AppUser> updateUserRole(String id, String role) async {
    return _wrap(() async {
      final response = await _dio.put('/users/$id', data: {'role': role});
      final data = response.data as Map<String, dynamic>;
      return AppUser.fromJson(data['user'] as Map<String, dynamic>);
    });
  }

  // ── Categories ──────────────────────────────────────

  Future<List<Category>> getCategories() async {
    return _wrap(() async {
      final response = await _dio.get('/categories');
      final list = response.data as List;
      return list
          .map((j) => Category.fromJson(j as Map<String, dynamic>))
          .toList();
    });
  }

  Future<Category> createCategory(Category category) async {
    return _wrap(() async {
      final response = await _dio.post('/categories', data: category.toJson());
      return Category.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<Category> updateCategory(Category category) async {
    return _wrap(() async {
      final response = await _dio.put(
        '/categories/${category.id}',
        data: category.toJson(),
      );
      return Category.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<void> deleteCategory(String id) async {
    return _wrap(() => _dio.delete('/categories/$id'));
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
    final response = await _dio.put(
      '/statuses/${status.id}',
      data: status.toJson(),
    );
    return Status.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteStatus(String id) async {
    await _dio.delete('/statuses/$id');
  }

  // ── Locations ────────────────────────────────────────

  Future<List<Location>> getLocations() async {
    final response = await _dio.get('/locations');
    final list = response.data as List;
    return list
        .map((j) => Location.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Location> createLocation(Location location) async {
    final response = await _dio.post('/locations', data: location.toJson());
    return Location.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Location> updateLocation(Location location) async {
    final response = await _dio.put(
      '/locations/${location.id}',
      data: location.toJson(),
    );
    return Location.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteLocation(String id) async {
    await _dio.delete('/locations/$id');
  }

  // ── Departments ──────────────────────────────────────

  Future<List<Department>> getDepartments() async {
    final response = await _dio.get('/departments');
    final list = response.data as List;
    return list
        .map((j) => Department.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Department> createDepartment(Department department) async {
    final response = await _dio.post('/departments', data: department.toJson());
    return Department.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Department> updateDepartment(Department department) async {
    final response = await _dio.put(
      '/departments/${department.id}',
      data: department.toJson(),
    );
    return Department.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteDepartment(String id) async {
    await _dio.delete('/departments/$id');
  }

  // ── Tickets ──────────────────────────────────────────

  Future<List<Ticket>> getUserTickets() async {
    return _wrap(() async {
      final response = await _dio.get('/tickets');
      final data = response.data as Map<String, dynamic>;
      final list = data['tickets'] as List;
      return list
          .map((j) => Ticket.fromJson(j as Map<String, dynamic>))
          .toList();
    });
  }

  Future<Ticket> createTicket({
    required String type,
    String? assetId,
    String? notes,
  }) async {
    return _wrap(() async {
      final response = await _dio.post(
        '/tickets',
        data: {
          'type': type,
          if (assetId != null) 'asset_id': assetId,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return Ticket.fromJson(data['ticket'] as Map<String, dynamic>);
    });
  }

  Future<List<Ticket>> getAllTickets() async {
    return _wrap(() async {
      final response = await _dio.get('/tickets/admin');
      // log(response.data.toString());
      final List<dynamic> data = response.data['tickets'];
      return data.map((json) => Ticket.fromJson(json)).toList();
    });
  }

  Future<Ticket> updateTicketStatus(
    String id,
    String status, {
    String? reason,
  }) async {
    return _wrap(() async {
      final response = await _dio.patch(
        '/tickets/$id/status',
        data: {
          'status': status,
          if (reason != null) 'rejection_reason': reason,
        },
      );
      return Ticket.fromJson(response.data['ticket']);
    });
  }

  Future<Ticket> updateTicket(
    String id, {
    String? type,
    String? assetId,
    String? notes,
  }) async {
    return _wrap(() async {
      final response = await _dio.patch(
        '/tickets/$id',
        data: {
          if (type != null) 'type': type,
          if (assetId != null) 'asset_id': assetId,
          if (notes != null) 'notes': notes,
        },
      );
      return Ticket.fromJson(response.data['ticket']);
    });
  }

  Future<void> cancelTicket(String id) async {
    return _wrap(() => _dio.patch('/tickets/$id/cancel'));
  }

  // ── Maintenance Alerts ──────────────────────────────────────────

  Future<List<MaintenanceAlert>> getAlerts() async {
    return _wrap(() async {
      final response = await _dio.get('/alerts');
      final list = response.data['alerts'] as List;
      return list.map((j) => MaintenanceAlert.fromJson(j as Map<String, dynamic>)).toList();
    });
  }

  Future<MaintenanceAlert> updateAlertStatus(String id, String status) async {
    return _wrap(() async {
      final response = await _dio.put(
        '/alerts/$id/status',
        data: {'status': status},
      );
      return MaintenanceAlert.fromJson(response.data['alert'] as Map<String, dynamic>);
    });
  }
}
