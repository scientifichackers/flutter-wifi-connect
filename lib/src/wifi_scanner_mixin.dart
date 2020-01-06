import 'package:flutter/widgets.dart';
import 'package:wifi_connect/wifi_connect.dart';

mixin WifiScannerMixin<T extends StatefulWidget> implements State<T> {
  var connectedSSID = '';

  void onSSIDChanged(String ssid) {}

  Future<void> startWifiScanner({
    Duration period: const Duration(seconds: 1),
  }) async {
    var stream = await WifiConnect.getConnectedSSIDListener(
      context,
      period: period,
    );
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
