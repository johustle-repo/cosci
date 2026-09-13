{{flutter_js}}
{{flutter_build_config}}

// CoSci is an authenticated, frequently updated application. Do not let an
// obsolete Flutter service worker keep serving an older project build. This
// also removes workers and caches installed by previous deployments that used
// the same Firebase Hosting origin.
(async () => {
  try {
    if ('serviceWorker' in navigator) {
      const registrations = await navigator.serviceWorker.getRegistrations();
      await Promise.all(registrations.map((registration) => registration.unregister()));
    }

    if ('caches' in window) {
      const cacheNames = await caches.keys();
      await Promise.all(cacheNames.map((cacheName) => caches.delete(cacheName)));
    }
  } catch (error) {
    // Cache cleanup must never prevent the application from opening.
    console.warn('CoSci cache cleanup was skipped:', error);
  }

  // Omitting serviceWorkerSettings intentionally prevents a new Flutter
  // service worker from being registered.
  await _flutter.loader.load();
})();
