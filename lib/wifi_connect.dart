import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plugin_scaffold/plugin_scaffold.dart';
import 'package:use_location/use_location.dart';
import 'package:wifi_connect/src/exceptions.dart';

import 'src/dialogs.dart';

export 'src/exceptions.dart';
export 'src/wifi_scanner_mixin.dart';

enum SecurityType {
  wpa, wep, open, auto
}

String getCapabilities(SecurityType securityType) {
  String ret = "";
  switch (securityType) {
    case SecurityType.wpa:
      ret = "WPA";
      break;
    case SecurityType.wep:
      ret = "WEP";
      break;
    case SecurityType.open:
      ret = "OPEN";
      break;
    default:
      break;
  }
  return ret;
}

class WifiConnect {
  static const channel = const MethodChannel('wifi_connect');

  /// Get the currently connected WiFi AP's SSID
  ///
  /// Returns empty string [''] if device is not connected to any WiFi AP.
  static Future<String> getConnectedSSID(
    BuildContext context, {
    WifiConnectDialogs dialogs,
  }) async {
    await useLocation(context, dialogs: dialogs);
    return await channel.invokeMethod('getConnectedSSID');
  }

  static Future<void> connect(
    BuildContext context, {
    @required String ssid,
    @required String password,
    bool hidden = false,
    SecurityType securityType = SecurityType.auto,
    WifiConnectDialogs dialogs,
    Duration timeout: const Duration(seconds: 15),
  }) async {
    assert (!hidden || securityType != SecurityType.auto);

    var timeLimit = DateTime.now().add(timeout);

    dialogs ??= WifiConnectDialogs();
    await useLocation(context, dialogs: dialogs);

    var args = {
      'ssid': ssid ?? '',
      'password': password ?? '',
      'hidden': hidden,
      'capabilities': getCapabilities(securityType),
      'timeLimitMillis': timeLimit.millisecondsSinceEpoch,
    };
    var idx = await channel.invokeMethod("connect", args);

    if (idx == WifiConnectStatus.wifiEnableDenied.index) {
      var proceed = await dialogs.enableWifiSettings(context);
      if (proceed) {
        idx = await channel.invokeMethod('openWifiSettings', args);
      }
    }

    if (idx != WifiConnectStatus.ok.index) {
      throw WifiConnectException(WifiConnectStatus.values[idx]);
    }
  }

  static Stream<String> getConnectedSSIDListener({
    Duration period: const Duration(seconds: 1),
  }) {
    return PluginScaffold.createStream(
      channel,
      'connectedSSID',
      period.inMilliseconds,
    );
  }

  static Future<void> useLocation(
    BuildContext context, {
    WifiConnectDialogs dialogs,
  }) async {
    if (!Platform.isAndroid) return;

    dialogs ??= WifiConnectDialogs();
    var locationStatus = await UseLocation.useLocation(
      context,
      showPermissionRationale: dialogs.locationPermission,
      showPermissionSettingsRationale: dialogs.locationPermissionSettings,
      showEnableSettingsRationale: dialogs.enableLocationSettings,
    );

    if (locationStatus != UseLocationStatus.ok) {
      throw WifiConnectException(
        WifiConnectStatus.values[locationStatus.index + 3],
      );
    }
  }
}
