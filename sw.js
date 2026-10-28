self.addEventListener('install', e => self.skipWaiting());
self.addEventListener('activate', e => self.clients.claim());
self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(clients.matchAll({type:'window'}).then(list => {
    for (let c of list) if (c.url.includes('Synapse') && 'focus' in c) return c.focus();
    if (clients.openWindow) return clients.openWindow('./');
  }));
});
self.addEventListener('push', e => {
  let data = {};
  try { data = e.data ? e.data.json() : {}; } catch {}
  e.waitUntil(self.registration.showNotification(data.title || 'Synapse', {
    body: data.body || '',
    icon: data.icon || '',
    badge: data.badge || '',
    tag: data.tag || 'synapse-reminder',
    data: data
  }));
});
self.addEventListener('message', e => {
  if (e.data && e.data.type === 'SHOW_NOTIFICATION') {
    self.registration.showNotification(e.data.title, {
      body: e.data.body,
      icon: e.data.icon || '',
      badge: e.data.badge || '',
      tag: e.data.tag || 'synapse-'+Date.now(),
      data: e.data.data || {}
    });
  }
});
