'use strict';

const CACHE_NAME = 'vslast-pwa-shell-v2';

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
  // Flutter, Firebase and Supabase keep their normal network behavior.
  event.respondWith(fetch(event.request));
});
