// Dummy service worker to prevent 404/html reload loops on boot.
static const VERSION = '1.2';
self.addEventListener('install', (event) => {
  self.skipWaiting();
});
self.addEventListener('activate', (event) => {
  event.waitUntil(clients.claim());
});
