import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/checkout_models.dart';
import '../models/sport_models.dart';
import '../services/checkout_service.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../services/sports_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    required this.sportsService,
    required this.firebaseService,
    required this.aiService,
    required this.checkoutService,
  });

  final SportsService sportsService;
  final FirebaseService firebaseService;
  final AiService aiService;
  final CheckoutService checkoutService;

  ThemeMode themeMode = ThemeMode.light;
  Sport selectedSport = Sport.football;
  LeagueOption? selectedLeague;
  bool isLoading = false;
  bool isFirebaseReady = false;
  String? lastError;
  List<SportMatch> matches = <SportMatch>[];
  List<SportMatch> favorites = <SportMatch>[];
  List<StandingEntry> standings = <StandingEntry>[];
  List<ChatMessage> chatMessages = <ChatMessage>[];
  List<CheckoutOrder> checkoutOrders = <CheckoutOrder>[];
  List<StoreProduct> products = <StoreProduct>[];
  bool isAdminAuthenticated = false;

  late final List<LeagueOption> footballLeagues = SportsService.leaguesFor(
    Sport.football,
  );
  late final List<LeagueOption> basketballLeagues = SportsService.leaguesFor(
    Sport.basketball,
  );

  Future<void> initialize() async {
    selectedLeague = footballLeagues.first;
    isLoading = true;
    notifyListeners();

    await firebaseService.initialize();
    isFirebaseReady = firebaseService.isConfigured;

    try {
      final prefs = await SharedPreferences.getInstance();
      final huggingFaceKey =
          prefs.getString('hugging_face_api_key') ??
          AiService.defaultHuggingFaceApiKey;
      final apiFootballKey = prefs.getString('api_football_api_key') ?? '';
      final providerString = prefs.getString('ai_provider') ?? 'local';

      aiService.setApiKey(huggingFaceKey, AiProvider.huggingFace);
      aiService.setProvider(
        providerString == 'hugging_face'
            ? AiProvider.huggingFace
            : AiProvider.local,
      );
      sportsService.setApiFootballKey(apiFootballKey);
    } catch (_) {
      // ignorar fallos de SharedPreferences
    }

    await loadMatches();
    await loadFavorites();
    await loadOrders();
    await loadProducts();
    isAdminAuthenticated = await firebaseService.isAdminAuthenticated();
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadMatches() async {
    if (selectedLeague == null) {
      return;
    }

    isLoading = true;
    notifyListeners();

    lastError = null;
    notifyListeners();
    try {
      final now = DateTime.now();
      matches = await sportsService.fetchMatches(
        sport: selectedSport,
        league: selectedLeague!,
        from: now.subtract(const Duration(days: 90)),
        to: now.add(const Duration(days: 90)),
      );
      standings = await sportsService.fetchStandings(
        sport: selectedSport,
        league: selectedLeague!,
      );
    } catch (_) {
      matches = <SportMatch>[];
      standings = <StandingEntry>[];
      lastError = 'Error cargando partidos. Revisa conexión.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFavorites() async {
    favorites = await firebaseService.loadFavorites();
    notifyListeners();
  }

  Future<void> toggleFavorite(SportMatch match) async {
    final alreadySaved = favorites.any((item) => item.id == match.id);
    if (alreadySaved) {
      await firebaseService.removeFavorite(match.id);
      favorites.removeWhere((item) => item.id == match.id);
    } else {
      await firebaseService.saveFavorite(match);
      favorites.add(match);
    }
    notifyListeners();
  }

  Future<void> loadOrders() async {
    checkoutOrders = await firebaseService.loadOrders();
    notifyListeners();
  }

  Future<void> loadProducts() async {
    products = await firebaseService.loadProducts();
    notifyListeners();
  }

  Future<double> estimateShippingCost({
    required String originAddress,
    required String destinationAddress,
    required double shippingRatePerKm,
  }) async {
    return checkoutService.estimateShippingCost(
      originAddress: originAddress,
      destinationAddress: destinationAddress,
      shippingRatePerKm: shippingRatePerKm,
    );
  }

  Future<void> loginAdmin({
    required String email,
    required String password,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      await firebaseService.signInAdmin(email: email, password: password);
      isAdminAuthenticated = true;
    } catch (error) {
      lastError = error.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logoutAdmin() async {
    await firebaseService.signOutAdmin();
    isAdminAuthenticated = false;
    notifyListeners();
  }

  Future<void> addProduct(StoreProduct product) async {
    await firebaseService.saveProduct(product);
    await loadProducts();
  }

  Future<CheckoutResult> createCheckoutOrder({
    required List<CartItem> items,
    required String originAddress,
    required String destinationAddress,
    required double shippingRatePerKm,
  }) async {
    final totalProductPrice = items.fold<double>(
      0,
      (sum, item) => sum + item.subtotal,
    );
    final orderTitle = items
        .map((item) => '${item.quantity}x ${item.product.name}')
        .join(', ');

    final result = await checkoutService.createCheckout(
      orderTitle: orderTitle,
      itemsTotalAmount: totalProductPrice,
      originAddress: originAddress,
      destinationAddress: destinationAddress,
      shippingRatePerKm: shippingRatePerKm,
    );

    final order = CheckoutOrder(
      id: result.orderId,
      productName: orderTitle,
      productPrice: totalProductPrice,
      distanceKm: result.distanceKm,
      shippingCost: result.shippingCost,
      totalAmount: result.totalAmount,
      paymentUrl: result.paymentUrl,
      createdAt: DateTime.now(),
      destinationAddress: destinationAddress,
    );

    checkoutOrders.insert(0, order);
    await firebaseService.saveOrder(order);
    notifyListeners();
    return result;
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) {
      return;
    }

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    chatMessages.add(userMessage);
    notifyListeners();

    final answer = await aiService.ask(
      question: text,
      sport: selectedSport,
      league: selectedLeague ?? footballLeagues.first,
      matches: matches,
    );

    chatMessages.add(
      ChatMessage(text: answer, isUser: false, timestamp: DateTime.now()),
    );
    notifyListeners();
  }

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setSelectedSport(Sport sport) {
    selectedSport = sport;
    selectedLeague =
        (sport == Sport.football ? footballLeagues : basketballLeagues).first;
    notifyListeners();
    loadMatches();
  }

  void setSelectedLeague(LeagueOption league) {
    selectedLeague = league;
    notifyListeners();
    loadMatches();
  }

  Future<void> setProvider(AiProvider provider) async {
    aiService.setProvider(provider);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'ai_provider',
      provider == AiProvider.huggingFace ? 'hugging_face' : 'local',
    );
    notifyListeners();
  }

  Future<void> setKey(String key, AiProvider provider) async {
    aiService.setApiKey(key, provider);
    final prefs = await SharedPreferences.getInstance();
    if (provider == AiProvider.huggingFace) {
      await prefs.setString('hugging_face_api_key', key);
    }
    notifyListeners();
  }

  Future<void> setApiFootballKey(String key) async {
    sportsService.setApiFootballKey(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_football_api_key', key);
    notifyListeners();
  }
}
