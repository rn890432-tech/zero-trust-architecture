// mobile-push-sw.js
self.addEventListener('push', function(event) {
  const data = event.data ? event.data.text() : 'New notification!';
  event.waitUntil(
    self.registration.showNotification('SOC Mobile Alert', {
      body: data,
      icon: 'https://cdn-icons-png.flaticon.com/512/1828/1828884.png',
      badge: 'https://cdn-icons-png.flaticon.com/512/1828/1828884.png'
    })
  );
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  event.waitUntil(
    clients.openWindow('/')
  );
});
