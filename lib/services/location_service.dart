import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:inzirax/models/driver_position.dart';

class LocationService {
  Future<LocationPermission> requestPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  Future<bool> isReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    final permission = await requestPermission();
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Stream<DriverPosition> positionStream() async* {
    if (!await isReady()) {
      throw StateError('Location permission and device location services are required.');
    }
    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );
    yield* Geolocator.getPositionStream(locationSettings: settings).map(DriverPosition.fromPosition);
  }
}
