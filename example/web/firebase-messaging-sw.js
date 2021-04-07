importScripts("https://www.gstatic.com/firebasejs/8.3.2/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.3.2/firebase-messaging.js");

//Using singleton breaks instantiating messaging()
// App firebase = FirebaseWeb.instance.app;


firebase.initializeApp({
    apiKey: "AIzaSyCeiUhTHiy0MhEYJamcmqeEwUxPenH4fMo",
    authDomain: "rocketchat-3a145.firebaseapp.com",
    projectId: "rocketchat-3a145",
    storageBucket: "rocketchat-3a145.appspot.com",
    messagingSenderId: "1018422454473",
    appId: "1:1018422454473:web:85faa8c52cbb0736dc8518",
    measurementId: "G-0QYN6R6M6B"
});

const messaging = firebase.messaging();
messaging.getToken({vapidKey: "36ae179dbd89791de89a6220f2992fe099381e5b"});
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  // Customize notification here
  const notificationTitle = 'Background Message Title';
  const notificationOptions = {
    body: 'Background Message body.',
    icon: '/firebase-logo.png'
  };

  self.registration.showNotification(notificationTitle,
    notificationOptions);
});

self.addEventListener('notificationclick', function (event) {
    console.log('notification received: ', event)
});