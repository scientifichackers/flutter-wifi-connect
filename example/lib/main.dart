import 'package:flutter/material.dart';
import 'package:wifi_connect/wifi_connect.dart';

void main() {
  runApp(Wrapper(child: MyApp()));
}

class Wrapper extends StatelessWidget {
  final Widget child;

  const Wrapper({Key key, @required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(10),
          child: child,
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WifiScannerMixin<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        TextField(
          controller: ssidControl,
          decoration: InputDecoration(labelText: 'SSID'),
        ),
        TextField(
          controller: passwordControl,
          decoration: InputDecoration(labelText: 'Password'),
        ),
        Divider(),
        CheckboxListTile(
          title: Text('hidden'),
          value: hidden,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (value) {
            setState(() {
              hidden = value;
            });
          },
        ),
        Divider(),
        RaisedButton(
          child: Text("connect"),
          onPressed: connect,
        ),
        Divider(),
        if (connectedSSID.isEmpty)
          Text('Wifi is disconnected.')
        else
          Text("Connected to '$connectedSSID'"),
        Text('Status: $connectSuccess'),
      ],
    );
  }

  String connectSuccess;
  var hidden = false;
  var ssidControl = TextEditingController(text: 'Gecko1234');
  var passwordControl = TextEditingController(text: 'password');

  @override
  void initState() {
    super.initState();
    startWifiScanner();
  }

  void showMessage(String msg) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(msg),
        );
      },
    );
  }

  Future<void> connect() async {
    setState(() {
      connectSuccess = '...';
    });
    try {
      await WifiConnect.connect(
        context,
        ssid: ssidControl.text,
        password: passwordControl.text,
        hidden: hidden,
        securityType: hidden ? SecurityType.wpa : SecurityType.auto,
      );
    } on WifiConnectException catch (e) {
      print('error: $e');
      setState(() {
        connectSuccess = e.status.toString();
      });
      return;
    }
    print('sucess!');
    setState(() {
      connectSuccess = 'Success!';
    });
  }
}
