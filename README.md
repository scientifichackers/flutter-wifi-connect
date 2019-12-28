# Flutter WiFi Connect

Easily connect to a specified WiFi AP programmatically, using this plugin.

```dart
import 'package:wifi_connect/wifi_connect.dart';
```

```dart
var status = WifiConnect.connect(context, 'ssid', 'password');
print('Connection status: $status');
```

It's that simple. No fussing with permissions, enabling WiFi, location and all the boring stuff.

---

```dart
var connectedTo = WifiConnect.getConnectedSSID();
print('Connected to: $connectedTo');
```

--- 

And behold, the mighty `WifiScannerMixin`!

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WifiScannerMixin<MyApp> {
 @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text("Connected to '$connectedSSID'"),
        )       
      )   
    );
  }

  @override
  void initState() {
    super.initState();
    startWifiScanner();
  }
}
```
