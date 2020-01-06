enum WifiConnectStatus {
  ok,
  failed,
  notFound,
  wifiEnableDenied,
  // mirrored from 'use_location' plugin
  locationEnableDenied,
  locationPermissionDenied,
}

class WifiConnectException implements Exception {
  final WifiConnectStatus status;

  WifiConnectException(this.status);

  @override
  String toString() {
    return "<$runtimeType: status=$status>";
  }
}
