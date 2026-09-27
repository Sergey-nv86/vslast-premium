'use strict';

const CACHE_NAME = 'vslast-pwa-shell-v3';

// IMPORTANT: register the custom notification click handler BEFORE loading
// Firebase Messaging. Firebase may otherwise install/override its own
// notificationclick handler and our navigation intent can be lost.
self.addEventListener('notificationclick', function(event) {
  event.preventDefault();
  event.stopImmediatePropagation();

  const data = event.notification.data || {};
  const pushType = data.type ? String(data.type) : '';
  const orderId = data.order_id ? String(data.order_id) : '';
  const productId = data.product_id ? String(data.product_id) : '';
  const threadId = data.thread_id ? String(data.thread_id) : '';
  const messageId = data.message_id ? String(data.message_id) : '';
  const clientId = data.client_id ? String(data.client_id) : '';
  const clientUserId = data.client_user_id
    ? String(data.client_user_id)
    : '';
  const promotionId = data.promotion_id
    ? String(data.promotion_id)
    : '';
  const assortmentDate = data.assortment_date
    ? String(data.assortment_date)
    : '';
  const cartId = data.cart_id ? String(data.cart_id) : '';

  console.log('[FCM SW] Notification click:', data);

  event.notification.close();

  const baseUrl = 'https' + '://vslast-premium.web.app/';
  const targetUrl = new URL(baseUrl);

  targetUrl.searchParams.set('push_type', pushType);

  if (orderId) {
    targetUrl.searchParams.set('order_id', orderId);
  }

  if (productId) {
    targetUrl.searchParams.set('product_id', productId);
  }

  if (threadId) {
    targetUrl.searchParams.set('thread_id', threadId);
  }

  if (messageId) {
    targetUrl.searchParams.set('message_id', messageId);
  }

  if (clientId) {
    targetUrl.searchParams.set('client_id', clientId);
  }

  if (clientUserId) {
    targetUrl.searchParams.set('client_user_id', clientUserId);
  }

  if (promotionId) {
    targetUrl.searchParams.set('promotion_id', promotionId);
  }

  const navigationData = {
    type: 'push_navigation',
    push_type: pushType,
    order_id: orderId,
    product_id: productId,
    thread_id: threadId,
    message_id: messageId,
    client_id: clientId,
    client_user_id: clientUserId,
    promotion_id: promotionId,
    assortment_date: assortmentDate,
    cart_id: cartId,
  };

  console.log('[FCM SW] Navigation data:', navigationData);
  console.log('[FCM SW] Target URL:', targetUrl.toString());

  event.waitUntil(
    clients.matchAll({
      type: 'window',
      includeUncontrolled: true,
    }).then(function(clientList) {
      const sameOriginClients = clientList.filter(function(client) {
        try {
          return new URL(client.url).origin === new URL(baseUrl).origin;
        } catch (_) {
          return false;
        }
      });

      sameOriginClients.sort(function(a, b) {
        return (b.visibilityState === 'visible' ? 1 : 0) -
          (a.visibilityState === 'visible' ? 1 : 0);
      });

      if (sameOriginClients.length > 0) {
        const client = sameOriginClients[0];
        client.postMessage(navigationData);
        return client.focus();
      }

      return clients.openWindow(targetUrl.toString());
    })
  );
});

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
    '[FCM SW] Background message:',
    payload
  );

  const data = payload && payload.data ? payload.data : {};

  // Notification payloads are displayed automatically by FCM in background.
  // Manual display is kept only for data-only messages to avoid duplicates.
  if (payload && payload.notification) {
    return;
  }

  const title = data.title || 'Всласть';
  const body = data.body || 'Новое уведомление';

  self.registration.showNotification(title, {
    body: body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: {
      type: data.type || '',
      order_id: data.order_id ? String(data.order_id) : '',
      product_id: data.product_id ? String(data.product_id) : '',
      thread_id: data.thread_id ? String(data.thread_id) : '',
      message_id: data.message_id ? String(data.message_id) : '',
      client_id: data.client_id ? String(data.client_id) : '',
      client_user_id: data.client_user_id
        ? String(data.client_user_id)
        : '',
      promotion_id: data.promotion_id
        ? String(data.promotion_id)
        : '',
      assortment_date: data.assortment_date
        ? String(data.assortment_date)
        : '',
      cart_id: data.cart_id ? String(data.cart_id) : '',
    },
  });
});

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      await self.clients.claim();

      const keys = await caches.keys();

      await Promise.all(
        keys
          .filter((key) => key !== CACHE_NAME)
          .map((key) => caches.delete(key)),
      );
    })(),
  );
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') {
    return;
  }

  const url = new URL(event.request.url);

  if (url.origin !== self.location.origin) {
    return;
  }

  // Network pass-through.
  // We intentionally do not cache application data or resources.
  event.respondWith(fetch(event.request));
});
