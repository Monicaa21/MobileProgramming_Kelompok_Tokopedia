import 'package:flutter/material.dart';

enum NotificationCategory{
  order,
  promo,
  live,
  finance,
  store,
}

extension NotificationCategoryExtension on NotificationCategory {
  String get apiValue => name;
  String get label {
    switch (this) {
      case NotificationCategory.order:
        return 'Transaksi';
      case NotificationCategory.promo:
        return 'Promo';
      case NotificationCategory.live:
        return 'Live';
      case NotificationCategory.finance:
        return 'Pembayaran';
      case NotificationCategory.store:
        return 'Info Toko';
    }
  }
  static NotificationCategory fromApi(String? value) {
    switch (value?.toLowerCase()) {
      case 'order':
        return NotificationCategory.order;
      case 'promo':
        return NotificationCategory.promo;
      case 'live':
        return NotificationCategory.live;
      case 'finance':
        return NotificationCategory.finance;
      case 'store':
      default:
        return NotificationCategory.store;
    }
  }
}

class NotificationData {
  final String id;
  final String storeName;
  final String title;
  final String message;
  final NotificationCategory category;
  final String? imageUrl;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final bool isRead;
  final DateTime createdAt;

//imageurl nanti dulu 
  const NotificationData({
    required this.id,
    required this.storeName,
    required this.title,
    required this.message,
    required this.category,
    this.imageUrl,
    required this.isRead,
    this.relatedEntityType,
    this.relatedEntityId,
    required this.createdAt,
  });

factory NotificationData.fromJson(Map<String, dynamic> json){
  final rawImage = json['imageUrl']?.toString().trim();
  final rawEntityType = json['relatedEntityType']?.toString().trim();
  final rawEntityId = json['relatedEntityId']?.toString().trim();

  return NotificationData(
  id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
  storeName: json['storeName']?.toString().trim().isNotEmpty == true
  ? json['storeName'].toString().trim()
  : 'Info Toko', 
  title: json['title']?.toString() ?? '', 
  message: json['message']?.toString() ?? '', 
  category: NotificationCategoryExtension.fromApi(json['category']?.toString()),
  imageUrl: (rawImage != null && rawImage.isNotEmpty) ? rawImage : null, 
  isRead: json['isRead'] == true, 
  relatedEntityType: (rawEntityType != null && rawEntityType.isNotEmpty) ? rawEntityType : null,
  relatedEntityId: (rawEntityId != null && rawEntityId.isNotEmpty) ? rawEntityId : null,
  createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
  );
}

  NotificationData copyWith({
    bool? isRead,
  }) {
    return NotificationData(
      id: id, 
      storeName: storeName, 
      title: title, 
      message: message, 
      category: category, 
      imageUrl: imageUrl, 
      isRead: isRead ?? this.isRead, 
      relatedEntityType: relatedEntityType,
      relatedEntityId: relatedEntityId,
      createdAt: createdAt,
    );
  }
}


final List<NotificationData> notificationSamples = [
  //Notification data progress
  NotificationData(
    id: 'tes1',
    storeName: 'Gadgetin Store',
    title: 'Pesananmu sedang dikemas',
    message: 'Penjual sedang menyiapkan barang sebelum dikirim.',
    category: NotificationCategory.order,
    isRead: false,
    createdAt: DateTime.now().subtract(
      const Duration(minutes: 15),
    ),
  ),

  NotificationData(
    id: 'tes2',
    storeName: 'daily TCG',
    title: 'Promo spesial untukmu!',
    message: 'Dapatkan potongan harga untuk produk pilihan hari ini.',
    category: NotificationCategory.promo,
    isRead: false,
    createdAt: DateTime.now().subtract(
      const Duration(hours: 1),
    ),
  ),

  NotificationData(
    id: 'tes3',
    storeName: 'Live Shopping',
    title: 'Live shopping sedang berlangsung',
    message: 'Temukan produk menarik dan penawaran khusus dari penjual.',
    category: NotificationCategory.live,
    isRead: true,
    createdAt: DateTime.now().subtract(
      const Duration(hours: 3),
    ),
  ),

  NotificationData(
    id: 'tes4',
    storeName: 'GreenPay',
    title: 'Transaksi berhasil',
    message: 'Pembayaran untuk pesananmu berhasil diproses.',
    category: NotificationCategory.finance,
    isRead: true,
    createdAt: DateTime.now().subtract(
      const Duration(days: 1),
    ),
  ),

  NotificationData(
    id: 'tes5',
    storeName: 'Official Store',
    title: 'Selamat datang di toko kami!',
    message: 'Terima kasih sudah bergabung. Temukan produk terbaru kami disini.',
    category: NotificationCategory.store,
    isRead: true,
    createdAt: DateTime.now().subtract(
      const Duration(days: 2),
    ),
  ),
];


