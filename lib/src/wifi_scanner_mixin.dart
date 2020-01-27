import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:wifi_connect/wifi_connect.dart';

import 'dialogs.dart';

mixin WifiScannerMixin<T extends StatefulWidget> implements State<T> {
  var connectedSSID = '';

  void onSSIDChanged(String ssid) {}

  Future<void> startWifiScanner({
    Duration period: const Duration(seconds: 1),
    WifiConnectDialogs dialogs,
  }) async {
    if (Platform.isAndroid) {
      WifiConnect.useLocation(context, dialogs: dialogs);
    }

    var stream = await WifiConnect.getConnectedSSIDListener(period: period);
    await for (var value in stream) {
      if (!mounted) return;
      if (connectedSSID != value) {
        setState(() {
          connectedSSID = value;
        });
        onSSIDChanged(value);
      }
    }
  }
}
