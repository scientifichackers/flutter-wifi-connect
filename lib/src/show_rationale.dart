import 'package:flutter/cupertino.dart';
import 'package:use_location/src/show_rationale.dart';

Future<bool> showEnableWifiSettingsRationale(BuildContext context) async {
  return await showRationaleDialog(
    context: context,
    msg: 'Please enable WiFi to continue.',
    isOpenSettings: true,
  );
}
