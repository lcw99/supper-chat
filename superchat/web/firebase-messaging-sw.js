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
  console.log('[firebase-messaging-sw.js] background message=', payload);
  // Customize notification here
  var notificationTitle = payload.data.title;
  var notificationOptions = {
    body: payload.data.message,
    icon: payload.data.image,
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

/*
messaging.setBackgroundMessageHandler(function (payload) {
    const promiseChain = clients
        .matchAll({
            type: "window",
            includeUncontrolled: true
        })
        .then(windowClients => {
            for (let i = 0; i < windowClients.length; i++) {
                const windowClient = windowClients[i];
                windowClient.postMessage(payload);
            }
        })
        .then(() => {
            const title = payload.notification.title;
            const options = {
                body: payload.notification.score
              };
            return registration.showNotification(title, options);
        });
    return promiseChain;
});
self.addEventListener('notificationclick', function (event) {
    console.log('notification received: ', event)
});

*/
