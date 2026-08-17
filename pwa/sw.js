const CACHE = 'dsh-remote-pwa-v3';
const ASSETS = [
  './',
  './index.html',
  './manifest.json',
  './css/styles.css',
  './js/app.js',
  './icons/icon.svg',
  './icons/icon-192.png',
  './icons/icon-512.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE).then((cache) => cache.addAll(ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  // 页面导航：优先网络，确保拿到最新 HTML
  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request)
        .then((response) => {
          const copy = response.clone();
          caches.open(CACHE).then((cache) => cache.put(request, copy));
          return response;
        })
        .catch(() => caches.match(request))
    );
    return;
  }

  // 静态资源：缓存优先，失败回退缓存
  event.respondWith(
    caches.match(request).then((cached) => {
      const fetched = fetch(request)
        .then((response) => {
          const copy = response.clone();
          caches.open(CACHE).then((cache) => cache.put(request, copy));
          return response;
        })
        .catch(() => cached);
      return cached || fetched;
    })
  );
});
