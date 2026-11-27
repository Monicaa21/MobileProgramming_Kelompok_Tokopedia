import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:aplikasi_tokped/config.dart';
import 'package:aplikasi_tokped/models/shopping_item.dart';
import 'notification_data.dart';

class NotificationService {
  static const Duration _timeout = Duration(seconds: 12);

  static Uri _uri(String path, [Map<String, String>?query]) {
    final base = Uri.parse('${AppConfig.baseUrl}$path');
    return query == null ? base : base.replace(queryParameters: query);
  }

  static Future<List<NotificationData>> fetchNotifications({
    NotificationCategory? category,
    int limit = 20,
  }) async {
    final query = <String, String>{
      'limit': '$limit',
      if (category != null) 'category': category.apiValue,
    };

    final response = await http
    .get(_uri('/api/notifications', query))
    .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil notifikasi (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format response notifikasi tidak valid');
    }

    final rawList = decoded['data'];
    if (rawList is! List) {
      return [];
    }
    
    final List<NotificationData> notifications = [];
    for (final item in rawList) {
      if (item is Map) {
        notifications.add(
          NotificationData.fromJson(Map<String, dynamic>.from(item)),
      );
    }
  }
    return notifications;
  }
  static Future<int> fetchUnreadCount() async {
    final response = await http.get(_uri('/api/notifications/unread-count'))
    .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil jumlah unread');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['unreadCount'] as num?)?.toInt() ?? 0;
  }

  static Future<void> markAsRead(String id) async {
    final response = await http
        .patch(_uri('/api/notifications/$id/read'))
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Gagal menandai notifikasi sudah dibaca');
    }
  }

  static Future<void> markAllAsRead() async {
    final response = await http
        .patch(_uri('/api/notifications/read-all'))
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Gagal menandai semua notifikasi sudah dibaca');
    }
  }

  static Future<void> createNotification({
    required String storeName,
    required String title,
    required String message,
    required NotificationCategory category,
    String? imageUrl,
    String? relatedEntityType,
    String? relatedEntityId,
  }) async {
    final response = await http
        .post(
          _uri('/api/notifications'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'storeName': storeName,
            'title': title,
            'message': message,
            'category': category.apiValue,
            'imageUrl': imageUrl,
            'relatedEntityType': relatedEntityType,
            'relatedEntityId': relatedEntityId,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Gagal membuat notifikasi');
    }
  }

  //untuk navigasi langsung ke ProductDetailPage saat notifikasi item ditekan
  static Future<ShoppingItem?> fetchItemById(String itemId) async {
    final response = await http
        .get(_uri('/api/items/$itemId'))
        .timeout(_timeout);

    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final itemJson = decoded['item'];
    if (itemJson is Map<String, dynamic>) {
      return ShoppingItem.fromJson(itemJson);
    }
    return null;
  }
}
  
