import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class SettingsState {
  const SettingsState({
    this.voiceAlerts = true,
    this.warningDistanceMeters = 500,
    this.locationPermission = LocationPermission.denied,
  });

  final bool voiceAlerts;
  final double warningDistanceMeters;
  final LocationPermission locationPermission;

  SettingsState copyWith({bool? voiceAlerts, double? warningDistanceMeters, LocationPermission? locationPermission}) => SettingsState(
        voiceAlerts: voiceAlerts ?? this.voiceAlerts,
        warningDistanceMeters: warningDistanceMeters ?? this.warningDistanceMeters,
        locationPermission: locationPermission ?? this.locationPermission,
      );
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController() : super(const SettingsState()) {
    refreshPermission();
  }

  Future<void> refreshPermission() async => state = state.copyWith(locationPermission: await Geolocator.checkPermission());
  void setVoiceAlerts(bool enabled) => state = state.copyWith(voiceAlerts: enabled);
  void setWarningDistance(double distance) => state = state.copyWith(warningDistanceMeters: distance);
}

final settingsProvider = StateNotifierProvider<SettingsController, SettingsState>((ref) => SettingsController());
