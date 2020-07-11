import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:wifi_connect/wifi_connect.dart';
import 'package:location/location.dart';

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


    if (Platform.isIOS) {
      //Location permission is required to fetch wifi ssid on IOS 13 and above
      Location location = new Location();

      bool _serviceEnabled;
      PermissionStatus _permissionGranted;
      LocationData _locationData;

      _serviceEnabled = await location.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await location.requestService();
        if (!_serviceEnabled) {
          return;
        }
      }

      _permissionGranted = await location.hasPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        _permissionGranted = await location.requestPermission();
        if (_permissionGranted != PermissionStatus.granted) {
          return;
        }
      }
    }

    var stream = WifiConnect.getConnectedSSIDListener(period: period);
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
