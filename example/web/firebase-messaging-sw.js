importScripts("https://www.gstatic.com/firebasejs/8.3.3/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.3.3/firebase-messaging.js");

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
messaging.setBackgroundMessageHandler(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  // Customize notification here
  var notificationTitle = 'Background Message Title';
  var notificationOptions = {
    body: 'Background Message body.',
    icon: '/firebase-logo.png'
  };

  return self.registration.showNotification(notificationTitle,
    notificationOptions);
});