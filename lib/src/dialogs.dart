import 'package:flutter/cupertino.dart';
import 'package:use_location/src/show_rationale.dart';
import 'package:use_location/use_location.dart';

Future<bool> showEnableWifiSettingsDialog(BuildContext context) async {
  return await showRationaleDialog(
    context: context,
    msg: 'Please enable WiFi to continue.',
    isOpenSettings: true,
  );
}

class WifiConnectDialogs {
  final ShowRationale locationPermission;
  final ShowRationale locationPermissionSettings;
  final ShowRationale enableLocationSettings;
  final ShowRationale enableWifiSettings;

  WifiConnectDialogs({
    this.locationPermission,
    this.locationPermissionSettings,
    this.enableLocationSettings,
    ShowRationale enableWifiSettings,
  }) : this.enableWifiSettings =
            enableWifiSettings ?? showEnableWifiSettingsDialog;
}
