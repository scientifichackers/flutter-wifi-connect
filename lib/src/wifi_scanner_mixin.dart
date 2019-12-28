import 'package:flutter/widgets.dart';
import 'package:wifi_connect/wifi_connect.dart';

mixin WifiScannerMixin<T extends StatefulWidget> implements State<T> {
  var connectedSSID = '';

  Future<void> startWifiScanner({
    Duration period: const Duration(seconds: 1),
  }) async {
    while (true) {
      var newValue = await WifiConnect.getConnectedSSID();
      if (connectedSSID == newValue || !mounted) continue;
      setState(() {
        connectedSSID = newValue;
      });
      await Future.delayed(period);
    }
  }
}
