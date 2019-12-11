import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:use_location/use_location.dart';

import 'src/show_rationale.dart' as sr;

enum WifiConnectStatus {
  ok,
  failed,
  notFound,
  wifiEnableDenied,
  // mirrored from 'use_location' plugin
  locationEnableDenied,
  locationPermissionDenied,
}

class WifiConnect {
  static const channel = const MethodChannel('wifi_connect');

  /// Get the currently connected WiFi AP's SSID
  ///
  /// Returns empty string [''] if device is not connected to any WiFi AP.
  static Future<String> getConnectedSSID() async {
    return await channel.invokeMethod('getConnectedSSID') ?? '';
  }

  static Future<WifiConnectStatus> connect(BuildContext context, {
    @required String ssid,
    @required String password,
    ShowRationale showLocationPermissionRationale,
    ShowRationale showLocationPermissionSettingsRationale,
    ShowRationale showEnableLocationSettingsRationale,
    ShowRationale showEnableWifiSettingsRationale,
    Duration wifiEnableTimeout: const Duration(seconds: 5),
  }) async {
    showEnableWifiSettingsRationale ??= sr.showEnableWifiSettingsRationale;

    var locationStatus = await UseLocation.useLocation(
      context,
      showPermissionRationale: showLocationPermissionRationale,
      showPermissionSettingsRationale: showLocationPermissionSettingsRationale,
      showEnableSettingsRationale: showEnableLocationSettingsRationale,
    );
    if (locationStatus != UseLocationStatus.ok) {
      return WifiConnectStatus.values[locationStatus.index + 3];
    }

    var args = {
      'ssid': ssid ?? '',
      'password': password ?? '',
      'wifiEnableTimeoutMillis': wifiEnableTimeout.inMilliseconds
    };
    var index = await channel.invokeMethod("connect", args);
    var status = WifiConnectStatus.values[index];

    if (status == WifiConnectStatus.wifiEnableDenied) {
      var proceed = await showEnableWifiSettingsRationale(context);
      if (proceed) {
        index = await channel.invokeMethod('openWifiSettings', args);
      }
    }

    return WifiConnectStatus.values[index];
  }
}
