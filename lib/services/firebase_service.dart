import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import '../models/checkout_models.dart';
import '../models/sport_models.dart';

class FirebaseService {
  FirebaseService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore,
      _auth = auth;

  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;

  FirebaseFirestore get _firestoreInstance =>
      _firestore ??= FirebaseFirestore.instance;
  FirebaseAuth get _authInstance => _auth ??= FirebaseAuth.instance;

  bool _isConfigured = false;
  bool get isConfigured => _isConfigured;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isConfigured = true;
    } catch (_) {
      _isConfigured = false;
      return;
    }

    try {
      if (_authInstance.currentUser == null) {
        await _authInstance.signInAnonymously();
      }
    } catch (_) {
      // Si la auth anónima no está deshabilitada, seguimos funcionando.
    }
  }

  Future<UserCredential> signInAdmin({
    required String email,
    required String password,
  }) async {
    if (!_isConfigured) {
      throw StateError('Firebase no está configurado.');
    }

    try {
      if (_authInstance.currentUser != null &&
          _authInstance.currentUser!.isAnonymous) {
        await _authInstance.signOut();
      }

      final credential = await _authInstance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'No se pudo iniciar sesión.',
        );
      }

      final isAdmin = await _isAdminUser(user.uid, user.email);
      if (!isAdmin) {
        await _authInstance.signOut();
        throw FirebaseAuthException(
          code: 'not-admin',
          message: 'El usuario no tiene permisos de administrador.',
        );
      }

      return credential;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> signOutAdmin() async {
    if (_authInstance.currentUser != null) {
      await _authInstance.signOut();
    }
  }

  Future<bool> isAdminAuthenticated() async {
    final user = _authInstance.currentUser;
    if (user == null) {
      return false;
    }
    return _isAdminUser(user.uid, user.email);
  }

  Future<void> saveProduct(StoreProduct product) async {
    if (!_isConfigured) {
      return;
    }

    try {
      final docId = product.id.isEmpty
          ? _firestoreInstance.collection('Products').doc().id
          : product.id;
      await _firestoreInstance
          .collection('Products')
          .doc(docId)
          .set(product.copyWith(id: docId).toFirestoreMap());
    } catch (_) {
      // Fallback silencioso para no romper la UI.
    }
  }

  Future<List<StoreProduct>> loadProducts() async {
    if (!_isConfigured) {
      return <StoreProduct>[];
    }

    try {
      final snapshot = await _firestoreInstance
          .collection('Products')
          .orderBy('titulo')
          .get();
      return snapshot.docs
          .map((doc) => StoreProduct.fromFirestoreMap(doc.data()))
          .toList();
    } catch (_) {
      return <StoreProduct>[];
    }
  }

  Future<void> deleteProduct(String productId) async {
    if (!_isConfigured) {
      return;
    }

    try {
      await _firestoreInstance.collection('Products').doc(productId).delete();
    } catch (_) {
      // Fallback silencioso para no romper la UI.
    }
  }

  Future<void> saveFavorite(SportMatch match) async {
    if (!_isConfigured) {
      await _saveFavoriteLocally(match);
      return;
    }

    try {
      final userId = _authInstance.currentUser?.uid;
      if (userId == null) {
        await _saveFavoriteLocally(match);
        return;
      }

      await _firestoreInstance
          .collection('favorites')
          .doc(userId)
          .collection('matches')
          .doc(match.id)
          .set(match.toFirestoreMap());
    } catch (_) {
      await _saveFavoriteLocally(match);
    }
  }

  Future<void> removeFavorite(String matchId) async {
    if (!_isConfigured) {
      await _removeFavoriteLocally(matchId);
      return;
    }

    try {
      final userId = _authInstance.currentUser?.uid;
      if (userId == null) {
        await _removeFavoriteLocally(matchId);
        return;
      }

      await _firestoreInstance
          .collection('favorites')
          .doc(userId)
          .collection('matches')
          .doc(matchId)
          .delete();
    } catch (_) {
      await _removeFavoriteLocally(matchId);
    }
  }

  Future<List<SportMatch>> loadFavorites() async {
    if (!_isConfigured) {
      return _loadFavoritesLocally();
    }

    try {
      final userId = _authInstance.currentUser?.uid;
      if (userId == null) {
        return _loadFavoritesLocally();
      }

      final snapshot = await _firestoreInstance
          .collection('favorites')
          .doc(userId)
          .collection('matches')
          .get();
      return snapshot.docs
          .map((doc) => SportMatch.fromFirestoreMap(doc.data()))
          .toList();
    } catch (_) {
      return _loadFavoritesLocally();
    }
  }

  Future<bool> isFavorite(String matchId) async {
    final favorites = await loadFavorites();
    return favorites.any((match) => match.id == matchId);
  }

  Future<void> saveOrder(CheckoutOrder order) async {
    if (!_isConfigured) {
      await _saveOrderLocally(order);
      return;
    }

    try {
      final userId = _authInstance.currentUser?.uid;
      if (userId == null) {
        await _saveOrderLocally(order);
        return;
      }

      await _firestoreInstance
          .collection('orders')
          .doc(userId)
          .collection('orders')
          .doc(order.id)
          .set(order.toFirestoreMap());
    } catch (_) {
      await _saveOrderLocally(order);
    }
  }

  Future<List<CheckoutOrder>> loadOrders() async {
    if (!_isConfigured) {
      return _loadOrdersLocally();
    }

    try {
      final userId = _authInstance.currentUser?.uid;
      if (userId == null) {
        return _loadOrdersLocally();
      }

      final snapshot = await _firestoreInstance
          .collection('orders')
          .doc(userId)
          .collection('orders')
          .get();
      return snapshot.docs
          .map((doc) => CheckoutOrder.fromFirestoreMap(doc.data()))
          .toList();
    } catch (_) {
      return _loadOrdersLocally();
    }
  }

  Future<void> _saveFavoriteLocally(SportMatch match) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('favorites') ?? <String>[];
    final serialized = jsonEncode(match.toFirestoreMap());
    if (!existing.contains(serialized)) {
      existing.add(serialized);
      await prefs.setStringList('favorites', existing);
    }
  }

  Future<void> _removeFavoriteLocally(String matchId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('favorites') ?? <String>[];
    final filtered = existing.where((entry) {
      final map = jsonDecode(entry) as Map<String, dynamic>;
      return map['id']?.toString() != matchId;
    }).toList();
    await prefs.setStringList('favorites', filtered);
  }

  Future<List<SportMatch>> _loadFavoritesLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList('favorites') ?? <String>[];
    return entries
        .map((entry) => jsonDecode(entry) as Map<String, dynamic>)
        .map(SportMatch.fromFirestoreMap)
        .toList();
  }

  Future<void> _saveOrderLocally(CheckoutOrder order) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('checkout_orders') ?? <String>[];
    final serialized = jsonEncode(order.toFirestoreMap());
    if (!existing.contains(serialized)) {
      existing.add(serialized);
      await prefs.setStringList('checkout_orders', existing);
    }
  }

  Future<List<CheckoutOrder>> _loadOrdersLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList('checkout_orders') ?? <String>[];
    return entries
        .map((entry) => jsonDecode(entry) as Map<String, dynamic>)
        .map(CheckoutOrder.fromFirestoreMap)
        .toList();
  }

  Future<bool> _isAdminUser(String uid, String? email) async {
    final byUidAdmins = await _firestoreInstance
        .collection('admins')
        .doc(uid)
        .get();
    if (byUidAdmins.exists) {
      return true;
    }

    final byUidUser = await _firestoreInstance
        .collection('User')
        .doc(uid)
        .get();
    if (byUidUser.exists && _documentIsAdmin(byUidUser.data())) {
      return true;
    }

    if (email == null || email.trim().isEmpty) {
      return false;
    }

    final normalizedEmail = email.trim().toLowerCase();
    final byEmailAdmins = await _firestoreInstance
        .collection('admins')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();
    if (byEmailAdmins.docs.isNotEmpty) {
      return true;
    }

    final byEmailUser = await _firestoreInstance
        .collection('User')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();
    return byEmailUser.docs.any((doc) => _documentIsAdmin(doc.data()));
  }

  bool _documentIsAdmin(Map<String, dynamic>? data) {
    if (data == null) {
      return false;
    }

    final role = data['rol'] ?? data['role'];
    if (role == null) {
      return false;
    }

    return role.toString().toLowerCase() == 'admin';
  }
}
