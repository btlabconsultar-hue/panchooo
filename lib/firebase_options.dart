import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyBAbP2C24k6nuAibPyZOVbuY1WyR2JNm6g',
      appId: '1:418616656550:web:a42fb83a7c16aff831aa67',
      messagingSenderId: '418616656550',
      projectId: 'tienda-pancho',
      authDomain: 'tienda-pancho.firebaseapp.com',
      storageBucket: 'tienda-pancho.firebasestorage.app',
      measurementId: 'G-GXN44HRV23',
      iosBundleId: 'com.example.myapp',
    );
  }
}
