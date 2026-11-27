import express from 'express';

import {
  filterNotifications,
  findUnreadCount,
  readNotification,
  readAllNotifications,
  makeNotification,
} from './notifications-controller.js';

export default (app) => {
  const route = express.Router();

  app.use('/notifications', route);

  // Mengambil jumlah notifikasi yang belum dibaca
  route.get('/unread-count', findUnreadCount);

  // Mengambil semua notifikasi
  route.get('/', filterNotifications);

  // Menandai semua notifikasi sudah dibaca
  route.patch('/read-all', readAllNotifications);

  // Menandai satu notifikasi sudah dibaca
  route.patch('/:id/read', readNotification);

  route.post('/', makeNotification);
};
