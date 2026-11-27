import mongoose from 'mongoose';

import {
  getNotifications,
  getUnreadCount,
  markNotificationAsRead,
  markAllNotificationsAsRead,
  createNotification,
} from './notifications-service.js';

const allowedCategories = [
  'store',
  'promo',
  'order',
  'finance',
  'live',
];

// GET semua notifikasi
const filterNotifications = async (req, res) => {
  try {
    const category = req.query.category || 'all';

    // validasi kategori
    if (
      category !== 'all' &&
      !allowedCategories.includes(category)
    ) {
      return res.status(400).json({
        success: false,
        message: 'Kategori notifikasi tidak valid',
      });
    }

    // validasi limit
    const requestedLimit = Number(req.query.limit || 30);

    const limit = Number.isFinite(requestedLimit)
      ? Math.min(Math.max(Math.trunc(requestedLimit), 1), 100)
      : 30;

    // ambil notifikasi melalui service
    const notifications = await getNotifications({
      category: category === 'all' ? undefined : category,
      limit,
    });

    return res.status(200).json({
      success: true,
      count: notifications.length,
      data: notifications,
    });
  } catch (error) {
    console.error('Get notifications error:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal mengambil notifikasi',
    });
  }
};

// GET jumlah notifikasi yang belum dibaca
const findUnreadCount = async (req, res) => {
  try {
    const count = await getUnreadCount();

    return res.status(200).json({
      success: true,
      unreadCount: count,
    });
  } catch (error) {
    console.error('Get unread count error:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal menghitung notifikasi',
    });
  }
};

// PATCH satu notifikasi menjadi sudah dibaca
const readNotification = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({
        success: false,
        message: 'ID notifikasi tidak valid',
      });
    }

    const notification = await markNotificationAsRead(id);

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notifikasi tidak ditemukan',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Notifikasi berhasil dibaca',
      data: notification,
    });
  } catch (error) {
    console.error('Mark notification error:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal memperbarui notifikasi',
    });
  }
};

// PATCH semua notifikasi menjadi sudah dibaca
const readAllNotifications = async (req, res) => {
  try {
    const result = await markAllNotificationsAsRead();

    return res.status(200).json({
      success: true,
      message: 'Semua notifikasi berhasil dibaca',
      modifiedCount: result.modifiedCount,
    });
  } catch (error) {
    console.error('Mark all notifications error:', error);

    return res.status(500).json({
      success: false,
      message: 'Gagal memperbarui semua notifikasi',
    });
  }
};

//POST membuat notifikasi baru
const makeNotification = async(req, res) => {
  try {
    const {
      storeName,
      title,
      message,
      category,
      imageUrl = null,
      relatedEntityType = null,
      relatedEntityId = null,
    } = req.body;
    if (!title || !message || !allowedCategories.includes(category)) {
      return res.status(400).json({
        success: false,
        message: 'Data notifikasi tidak lengkap atau kategori tidak valid',
      });
    }

    const notification = await createNotification({
      storeName: storeName || 'Info Toko',
      title,
      message,
      category,
      imageUrl,
      relatedEntityType,
      relatedEntityId,
    });

    return res.status(201).json({
      success: true,
      message: 'Notifikasi berhasil dibuat',
      data: notification,
    });
  } catch (error) {
    console.error('Create notification error:', error);
    return res.status(500).json({
      success: false,
      message: 'Gagal membuat notifikasi',
    });
  }
};
  


export {
  filterNotifications,
  findUnreadCount,
  readNotification,
  readAllNotifications,
  makeNotification,
};
