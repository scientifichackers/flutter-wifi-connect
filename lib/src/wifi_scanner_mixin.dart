import 'package:flutter/widgets.dart';
import 'package:wifi_connect/wifi_connect.dart';

mixin WifiScannerMixin<T extends StatefulWidget> implements State<T> {
  var connectedSSID = '';

  void onSSIDChanged(String ssid) {}

  Future<void> startWifiScanner({
    Duration period: const Duration(seconds: 1),
  }) async {
    while (true) {
      var newValue = await WifiConnect.getConnectedSSID();
      if (!mounted) return;
      if (connectedSSID != newValue) {
        setState(() {
          connectedSSID = newValue;
        });
        onSSIDChanged(newValue);
      }
      await Future.delayed(period);
    }
  }
}
