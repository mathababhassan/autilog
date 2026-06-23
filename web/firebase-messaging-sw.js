// Firebase Cloud Messaging service worker (web). The firebase_messaging web
// plugin auto-registers this file from the web root; it handles pushes that
// arrive while the tab is in the background / closed.
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBU7wpjCt2rNRobN70Sy1QgbLgPdALpgUE',
  authDomain: 'autilog-e5499.firebaseapp.com',
  projectId: 'autilog-e5499',
  storageBucket: 'autilog-e5499.firebasestorage.app',
  messagingSenderId: '168370628046',
  appId: '1:168370628046:web:5c369fcc194ede0f35f79f',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const n = payload.notification || {};
  self.registration.showNotification(n.title || 'AutiLog', {
    body: n.body || '',
    icon: '/icons/Icon-192.png',
  });
});
