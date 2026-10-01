import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inzirax/core/app_exception.dart';
import 'package:inzirax/core/geo.dart';
import 'package:inzirax/features/session/session_controller.dart';
import 'package:inzirax/features/settings/settings_controller.dart';
import 'package:inzirax/models/driver_position.dart';
import 'package:inzirax/models/live_alert.dart';
import 'package:inzirax/models/place_suggestion.dart';
import 'package:inzirax/models/route_candidate.dart';
import 'package:inzirax/services/api_client.dart';
import 'package:inzirax/services/background_location_service.dart';
import 'package:inzirax/services/incident_repository.dart';
import 'package:inzirax/services/location_service.dart';
import 'package:inzirax/services/route_repository.dart';
import 'package:inzirax/services/voice_alert_service.dart';
import 'package:inzirax/services/websocket_service.dart';

class NavigationState {
  const NavigationState({
    this.position,
    this.routes = const [],
    this.selectedRoute,
    this.destination,
    this.alerts = const [],
    this.isNavigating = false,
    this.isLoading = false,
    this.isSocketConnected = false,
    this.error,
  });

  final DriverPosition? position;
  final List<RouteCandidate> routes;
  final RouteCandidate? selectedRoute;
  final PlaceSuggestion? destination;
  final List<LiveAlert> alerts;
  final bool isNavigating;
  final bool isLoading;
  final bool isSocketConnected;
  final String? error;

  NavigationState copyWith({
    DriverPosition? position,
    List<RouteCandidate>? routes,
    RouteCandidate? selectedRoute,
    PlaceSuggestion? destination,
    List<LiveAlert>? alerts,
    bool? isNavigating,
    bool? isLoading,
    bool? isSocketConnected,
    String? error,
    bool clearError = false,
  }) => NavigationState(
        position: position ?? this.position,
        routes: routes ?? this.routes,
        selectedRoute: selectedRoute ?? this.selectedRoute,
        destination: destination ?? this.destination,
        alerts: alerts ?? this.alerts,
        isNavigating: isNavigating ?? this.isNavigating,
        isLoading: isLoading ?? this.isLoading,
        isSocketConnected: isSocketConnected ?? this.isSocketConnected,
        error: clearError ? null : error ?? this.error,
      );
}

class NavigationController extends StateNotifier<NavigationState> {
  NavigationController(this.ref)
      : _location = LocationService(),
        _background = BackgroundLocationService(),
        _socket = WebSocketService(),
        _voice = VoiceAlertService(),
        super(const NavigationState()) {
    _listen();
  }

  final Ref ref;
  final LocationService _location;
  final BackgroundLocationService _background;
  final WebSocketService _socket;
  final VoiceAlertService _voice;
  StreamSubscription<DriverPosition>? _foregroundSubscription;
  StreamSubscription<DriverPosition>? _backgroundSubscription;
  StreamSubscription<List<LiveAlert>>? _alertSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  void _listen() {
    _foregroundSubscription = _location.positionStream().listen(_onPosition, onError: (Object error) {
      state = state.copyWith(error: error.toString());
    });
    _backgroundSubscription = _background.positions.listen(_onPosition);
    _alertSubscription = _socket.alerts.listen(_onAlerts);
    _connectionSubscription = _socket.connection.listen((connected) => state = state.copyWith(isSocketConnected: connected));
    ref.listen<String?>(sessionProvider, (_, token) {
      if (token != null) _socket.connect(token);
    });
  }

  void _onPosition(DriverPosition position) {
    state = state.copyWith(position: position);
    _socket.sendPosition(position);
  }

  Future<void> _onAlerts(List<LiveAlert> alerts) async {
    final cutoff = ref.read(settingsProvider).warningDistanceMeters;
    final visible = alerts.where((alert) => alert.distanceMeters <= cutoff).toList(growable: false);
    state = state.copyWith(alerts: visible);
    if (visible.isNotEmpty) {
      final first = visible.first;
      final speed = first.speedLimit == null ? '' : ', speed limit ${first.speedLimit} kilometres per hour';
      await _voice.announce(first.id, '${first.title} in ${first.distanceMeters.round()} metres$speed', enabled: ref.read(settingsProvider).voiceAlerts);
    }
  }

  Future<List<PlaceSuggestion>> search(String query) => RouteRepository(ApiClient(() => ref.read(sessionProvider))).searchPlaces(query, state.position?.point);

  Future<void> selectDestination(PlaceSuggestion destination) async {
    final current = state.position;
    if (current == null) {
      state = state.copyWith(error: 'Waiting for your current location.');
      return;
    }
    if (ref.read(sessionProvider) == null) {
      state = state.copyWith(error: 'Sign in before planning a route.');
      return;
    }
    state = state.copyWith(isLoading: true, destination: destination, clearError: true);
    try {
      final routes = await RouteRepository(ApiClient(() => ref.read(sessionProvider))).plan(
        origin: current.point,
        originName: 'Current location',
        destination: destination,
      );
      state = state.copyWith(routes: routes, selectedRoute: routes.where((r) => r.isRecommended).firstOrNull ?? routes.firstOrNull, isLoading: false);
    } on AppException catch (error) {
      state = state.copyWith(isLoading: false, error: error.message);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: 'Could not plan route: $error');
    }
  }

  void selectRoute(RouteCandidate route) => state = state.copyWith(selectedRoute: route);

  Future<void> startNavigation() async {
    if (state.selectedRoute == null) return;
    await _background.start();
    final token = ref.read(sessionProvider);
    if (token != null) await _socket.connect(token);
    state = state.copyWith(isNavigating: true);
  }

  Future<void> stopNavigation() async {
    await _background.stop();
    state = state.copyWith(isNavigating: false);
  }

  Future<void> reportIncident(IncidentType type) async {
    final point = state.position?.point;
    if (point == null) return;
    try {
      await IncidentRepository(ApiClient(() => ref.read(sessionProvider))).report(type, point);
    } on AppException catch (error) {
      state = state.copyWith(error: error.message);
    }
  }

  @override
  void dispose() {
    _foregroundSubscription?.cancel();
    _backgroundSubscription?.cancel();
    _alertSubscription?.cancel();
    _connectionSubscription?.cancel();
    _background.dispose();
    _socket.dispose();
    _voice.dispose();
    super.dispose();
  }
}

final navigationProvider = StateNotifierProvider<NavigationController, NavigationState>((ref) => NavigationController(ref));

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
