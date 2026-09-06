self.addEventListener('notificationclick', (event) => {
  event.preventDefault();
  event.stopImmediatePropagation();

  event.notification.close();

  // DIAGNOSTIC TEST:
  // любой клик по push должен открыть конкретно заказ 1044.
  const targetUrl =
    'https' + '://' + 'vslast-premium.web.app/?order_id=' +
    'cc1d3277-056b-4356-98d1-072d1c72dc5c';

  console.log(
    '[SW TEST] notificationclick FIRED',
    'targetUrl=',
    targetUrl
  );

  event.waitUntil(
    clients.matchAll({
      type: 'window',
      includeUncontrolled: true,
    }).then(async (clientList) => {

      console.log(
        '[SW TEST] clients:',
        clientList.length
      );

      for (const client of clientList) {
        console.log(
          '[SW TEST] navigating client:',
          client.url
        );

        if ('navigate' in client) {
          const result = await client.navigate(targetUrl);

          if (result && 'focus' in result) {
            return result.focus();
          }

          if ('focus' in client) {
            return client.focus();
          }

          return result;
        }
      }

      if (clients.openWindow) {
        console.log(
          '[SW TEST] opening:',
          targetUrl
        );

        return clients.openWindow(targetUrl);
      }

      return undefined;
    }),
  );
});

const firebaseAppUrl =
  'https' + '://' +
  'www.gstatic.com/firebasejs/12.0.0/firebase-app-compat.js';

const firebaseMessagingUrl =
  'https' + '://' +
  'www.gstatic.com/firebasejs/12.0.0/firebase-messaging-compat.js';

importScripts(firebaseAppUrl);
importScripts(firebaseMessagingUrl);

firebase.initializeApp({
  apiKey: 'AIzaSyC11I9q6niCXe73B1vYIJ2XknzhkdDo6s4',
  authDomain: 'vslast-premium.firebaseapp.com',
  projectId: 'vslast-premium',
  storageBucket: 'vslast-premium.firebasestorage.app',
  messagingSenderId: '1078788985612',
  appId: '1:1078788985612:web:15484f6de2a20f60e6af29',
  measurementId: 'G-8653ZX27G4',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log(
    '[SW] Background data message:',
    payload,
  );

  const data = payload?.data || {};

  const title =
    data.title ||
    'Всласть';

  const body =
    data.body ||
    'Новое уведомление';

  const orderId =
    data.order_id
      ? String(data.order_id)
      : '';

  self.registration.showNotification(
    title,
    {
      body,
      icon: '/icons/Icon-192.png',

      data: {
        type: data.type || '',
        order_id: orderId,
      },
    },
  );
});
