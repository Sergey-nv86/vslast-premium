importScripts(
  'https://www.gstatic.com/firebasejs/12.0.0/firebase-app-compat.js'
);
importScripts(
  'https://www.gstatic.com/firebasejs/12.0.0/firebase-messaging-compat.js'
);

firebase.initializeApp({
  apiKey: 'AIzaSyC11I9q6niCxE73B1vYIJ2XknzhkdDo6s4',
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

  const notification = payload.notification || {};
  const title = notification.title || 'Всласть';

  const notificationOptions = {
    body: notification.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data || {},
  };

  self.registration.showNotification(
    title,
    notificationOptions
  );
});
