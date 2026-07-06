// Placeholder service worker to prevent 404/html reload loops on Firebase Messaging init.
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyBXx_u75U_sihRk6T2E2IrMxE_vjUhzTtw",
  projectId: "bidayaapp-c770f",
  messagingSenderId: "239001759258",
  appId: "1:239001759258:web:ce1365aa2e71f5e9e8eba3"
});

const messaging = firebase.messaging();
