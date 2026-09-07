importScripts(
  'https' + '://www.gstatic.com/firebasejs/12.0.0/firebase-app-compat.js'
);

importScripts(
  'https' + '://www.gstatic.com/firebasejs/12.0.0/firebase-messaging-compat.js'
);

firebase.initializeApp({
  apiKey: 'AIzaSyC11I9q6niCXe73B1vYIJ2XknzhkdDo6s',
  authDomain: 'vslast-premium.firebaseapp.com',
  projectId: 'vslast-premium',
  storageBucket: 'vslast-premium.firebasestorage.app',
  messagingSenderId: '1078788985612',
  appId: '1:1078788985612:web:15484f6de2a20f60e6af29',
  measurementId: 'G-8653ZX27G4',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log(
    '[firebase-messaging-sw.js] Background message:',
    payload
  );

  const data = payload && payload.data ? payload.data : {};
  const title = data.title || 'Всласть';
  const body = data.body || 'Новое уведомление';
  const orderId = data.order_id ? String(data.order_id) : '';

  self.registration.showNotification(title, {
    body: body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: {
      type: data.type || '',
      order_id: orderId,
    },
  });
});

self.addEventListener('notificationclick', function(event) {
  event.preventDefault();
  event.stopImmediatePropagation();

  const data = event.notification.data || {};
  const orderId = data.order_id
    ? String(data.order_id)
    : '';

  console.log('[FCM SW] Notification click:', data);
  console.log('[FCM SW] order_id:', orderId);

  event.notification.close();

  const baseUrl =
    'https' + '://vslast-premium.web.app/';

  const targetUrl = orderId
    ? baseUrl + '?order_id=' + encodeURIComponent(orderId)
    : baseUrl;

  console.log('[FCM SW] Target URL:', targetUrl);

  event.waitUntil(
    clients.matchAll({
      type: 'window',
      includeUncontrolled: true,
    }).then(function(clientList) {

      for (const client of clientList) {
        if ('focus' in client && 'navigate' in client) {
          return client.navigate(targetUrl).then(function() {
            return client.focus();
          });
        }
      }

      return clients.openWindow(targetUrl);
    })
  );
});
